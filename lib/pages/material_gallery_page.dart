import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/media_utils.dart';
import '../data/models/material_model.dart';
import '../data/repositories/material_repository.dart';
import '../widgets/media/media_viewers.dart';
import '../widgets/state_views.dart';

/// 素材库 / 素材选择页。
///
/// 路由：`/select-material`（顶层路由，由图生视频创作页 push 进来）。
///
/// **点一张素材 → `Navigator.pop(context, url)` 把地址交回上一页**，
/// 上一页会把它直接当成任务的 `refImageUrl` 提交给后端。
///
/// ---
///
/// ## 关于网络请求
///
/// 这一页**必须走 `MaterialRepository`（内部是全局 `ApiClient`）**，
/// 不能自己 `Dio()`：
///
/// 1. 裸 `Dio()` 没有 `baseUrl`，`get('/api/materials/my')` 是一个没有 host 的
///    相对地址，请求根本发不出去（Web 上会解析成当前页面域名，直接 404）；
/// 2. 即使地址对了，也**没有 `Authorization` 头** —— 后端 `AuthInterceptor`
///    会直接返回 401。token 是由 `ApiClient` 的拦截器统一注入的。
///
/// 之前这一页就是踩了这两个坑，表现是"页面空白、控制台一句人话都没有"。
class MaterialGalleryPage extends StatefulWidget {
  const MaterialGalleryPage({super.key});

  @override
  State<MaterialGalleryPage> createState() => _MaterialGalleryPageState();
}

class _MaterialGalleryPageState extends State<MaterialGalleryPage> {
  /// 一次拉多少条。
  ///
  /// 用「大页 + 不分页」而不是上拉加载：`StaggeredGrid.count` 接收的是一个
  /// **完整的 children 列表**（不是懒加载的 itemBuilder），分页省不下任何
  /// 渲染开销，只会让代码多出一堆状态。素材量大了再换 `SliverMasonryGrid`。
  static const int _pageSize = 30;

  List<MaterialModel> _items = const [];

  /// 首次加载中（只有列表还是空的时候才整页转圈，
  /// 否则下拉刷新会把已有网格清成一片白）。
  bool _loading = true;

  /// 正在上传（右上角按钮转圈）。
  bool _uploading = false;

  /// 加载失败原因，非 null 且列表为空时整页展示 + 重试。
  String? _error;

  @override
  void initState() {
    super.initState();
    // 放到首帧之后再触发：repository 请求回来会 setState，
    // 在 initState 里同步触发会在 build 期间标记依赖组件为脏。
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  // ===========================================================================
  // 数据
  // ===========================================================================

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await context
          .read<MaterialRepository>()
          .fetchMyMaterials(page: 0, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载素材失败：$e';
        _loading = false;
      });
    }
  }

  Future<void> _upload() async {
    if (_uploading) return;

    // 复用项目统一的 MediaUtils：它已经处理了权限申请、体积校验（10MB）
    // 以及 Web / Android 的差异 —— 不要在这里重新实现一遍。
    final file = await MediaUtils.pickImageFromGallery();
    if (file == null) {
      // null 有两种可能：用户主动取消（不该弹提示），
      // 或权限被拒 / 体积超限（MediaUtils 会把原因写进 lastErrorMessage）
      final reason = MediaUtils.lastErrorMessage;
      if (reason != null) _showMessage(reason);
      return;
    }

    final bytes = await MediaUtils.readBytes(file);
    if (!mounted) return;
    if (bytes == null) {
      _showMessage(MediaUtils.lastErrorMessage ?? '读取图片失败，请重新选择');
      return;
    }

    setState(() => _uploading = true);
    try {
      // 关键：走 repository 而不是 MultipartFile.fromFile(file.path)。
      // Web 上 XFile.path 是 `blob:` 开头的临时地址，后端根本拿不到；
      // 只有字节流能同时兼容 Android 与 Web。
      await context.read<MaterialRepository>().uploadImage(
            bytes: bytes,
            filename: MediaUtils.fileNameOf(file, fallback: 'material.jpg'),
          );
      if (!mounted) return;
      _showMessage('上传成功');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('上传失败：$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// 删除素材：二次确认 → 调接口 → 成功才从列表移除。
  ///
  /// 加二次确认是因为删除按钮就压在每张图的右上角，
  /// 误触一下就真删了，而且这里是逻辑删除、页面上没有"回收站"可找回。
  Future<void> _confirmDelete(MaterialModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除素材'),
        content: Text('确定删除「${item.displayName}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await context.read<MaterialRepository>().deleteMaterial(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items.where((e) => e.id != item.id).toList();
      });
      _showMessage('已删除');
    } on ApiException catch (e) {
      // 不能静默吞掉：删失败却把卡片移除了，刷新一下它又回来。
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('删除失败：$e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ===========================================================================
  // 构建
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的素材库'),
        actions: [
          IconButton(
            tooltip: '上传素材',
            onPressed: _uploading ? null : _upload,
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.add_a_photo_outlined),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  /// 四种状态，缺一个都会出现"页面一片空白、也不知道为什么"。
  Widget _buildBody() {
    // ---- 1. 加载中（仅首次，列表为空时）----
    if (_loading && _items.isEmpty) {
      return const LoadingView(message: '正在加载素材…');
    }

    // ---- 2. 加载失败，且一条都没拿到 ----
    if (_error != null && _items.isEmpty) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    // ---- 3. 空数据（也要能下拉刷新，所以包一层可滚动）----
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.photo_library_outlined,
                title: '还没有素材',
                description: '点右上角上传一张图片，创作时就能直接选用',
                actionLabel: '上传素材',
                onAction: _upload,
              ),
            ),
          ],
        ),
      );
    }

    // ---- 4. 网格渲染 ----
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      // StaggeredGrid.count 没有 padding 参数，边距只能包在外面
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          children: [for (final item in _items) _buildTile(item)],
        ),
      ),
    );
  }

  /// 点击一张素材。
  ///
  /// 这一页有**两种进入方式，点一下的语义完全不同**：
  ///
  /// 1. 从图生视频创作页 `push('/select-material')` 进来 —— 是「选择器」，
  ///    选中就 `pop(url)` 把地址交回上一页；
  /// 2. 从底部导航「素材」Tab 进来（`/materials`）—— 这里就是这个分支的
  ///    **根页面**，导航栈里压根没有上一页，`pop` 什么也做不了。
  ///    这种情况改成打开大图预览，而不是"点了没反应"。
  ///
  /// 用 `canPop()` 区分：push 进来的能 pop，Tab 根页面不能。
  void _onTapItem(MaterialModel item) {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      // ---- 选择器模式：把地址交回上一页（图生视频创作页）----
      //
      // ⚠️ 回传的是 item.url —— 后端返回的**原始相对地址**
      // （形如 /upload/xxx.png）。上一页会把它原样当作 refImageUrl
      // 提交给后端、存进任务表，所以这里绝不能传拼好的绝对地址：
      // 那会把 http://localhost:8080 这种本机地址写进数据库，
      // 换台机器 / 换个端口就失效了。
      navigator.pop(item.url);
      return;
    }

    // ---- Tab 模式：看大图。显示才需要拼绝对地址 ----
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ImagePreviewPage(
          imageUrl: AppConfig.resolveAssetUrl(item.url),
          title: item.displayName,
        ),
      ),
    );
  }

  Widget _buildTile(MaterialModel item) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 1,
      child: GestureDetector(
        onTap: () => _onTapItem(item),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Stack(
            children: [
              // 显示必须拼绝对地址：后端给的是 /upload/xxx.png，
              // Web 上直接交给 Image.network 会按当前页面域名去解析（→ 404 破图）。
              AppNetworkImage(
                url: AppConfig.resolveAssetUrl(item.url),
                fit: BoxFit.cover,
              ),
              Positioned(
                right: 4,
                top: 4,
                child: InkWell(
                  onTap: () => _confirmDelete(item),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black45,
                    child: Icon(Icons.delete_outline,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
