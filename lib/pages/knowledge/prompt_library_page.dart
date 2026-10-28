import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/prompt_model.dart';
import '../../data/repositories/prompt_repository.dart';
import '../../widgets/creation/prompt_input_card.dart';
import '../../widgets/premium/glass_panel.dart';
import '../../widgets/premium/premium_choice_chip.dart';
import '../../widgets/premium/premium_top_bar.dart';
import '../../widgets/premium/pressable_scale.dart';
import '../../widgets/state_views.dart';

/// 页面 8：Prompt 知识库。
///
/// 数据来自 `GET /api/prompts`，支持分类、关键词和分页检索。
/// 卡片可以直接套用到文生图页，也可以复制或收藏。
class PromptLibraryPage extends StatefulWidget {
  const PromptLibraryPage({super.key});

  @override
  State<PromptLibraryPage> createState() => _PromptLibraryPageState();
}

class _PromptLibraryPageState extends State<PromptLibraryPage> {
  static const int _pageSize = 12;
  static const List<String> _categories = [
    '全部',
    '人物',
    '风景',
    '电商',
    '二次元',
    '建筑',
    '其他',
  ];

  late final PromptRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _searchDebounce;
  final List<PromptModel> _prompts = [];
  final Set<int> _favoriteBusyIds = {};

  String _category = '全部';
  String? _error;
  String? _loadMoreError;
  bool _loading = true;
  bool _loadingMore = false;
  bool _creating = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _repository = context.read<PromptRepository>();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirstPage());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
      _loadMoreError = null;
    });
    try {
      final result = await _repository.fetchPrompts(
        category: _category == '全部' ? null : _category,
        keyword: _searchController.text,
        page: 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _prompts
          ..clear()
          ..addAll(result.list);
        _page = 1;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '加载 Prompt 失败：$error';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final result = await _repository.fetchPrompts(
        category: _category == '全部' ? null : _category,
        keyword: _searchController.text,
        page: _page + 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        final existing = _prompts.map((item) => item.id).toSet();
        _prompts.addAll(
          result.list.where((item) => !existing.contains(item.id)),
        );
        _page++;
        _hasMore = result.hasMore;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadMoreError = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadMoreError = '加载更多失败：$error');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadFirstPage);
  }

  void _changeCategory(String category) {
    if (_category == category) return;
    setState(() => _category = category);
    _loadFirstPage();
  }

  Future<void> _copyPrompt(PromptModel prompt) async {
    try {
      await Clipboard.setData(ClipboardData(text: prompt.content));
      if (mounted) _showMessage('Prompt 已复制');
    } catch (error) {
      if (mounted) _showMessage('复制失败：$error');
    }
  }

  Future<void> _toggleFavorite(PromptModel prompt) async {
    if (_favoriteBusyIds.contains(prompt.id)) return;
    setState(() => _favoriteBusyIds.add(prompt.id));
    try {
      final result = await _repository.toggleFavorite(prompt.id);
      if (!mounted) return;
      final index = _prompts.indexWhere((item) => item.id == prompt.id);
      if (index >= 0) {
        setState(() {
          _prompts[index] = prompt.copyWith(
            favorited: result.favorited,
            favoriteCount: result.favoriteCount,
          );
        });
      }
      _showMessage(result.favorited ? '已收藏' : '已取消收藏');
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('收藏操作失败：$error');
    } finally {
      if (mounted) setState(() => _favoriteBusyIds.remove(prompt.id));
    }
  }

  void _applyPrompt(PromptModel prompt) {
    context.push(
      Uri(
        path: RouteNames.textToImagePath,
        queryParameters: {
          'prompt': prompt.content,
          if (prompt.negativeContent != null &&
              prompt.negativeContent!.trim().isNotEmpty)
            'negativePrompt': prompt.negativeContent!,
        },
      ).toString(),
    );
  }

  Future<void> _openCreateSheet() async {
    if (_creating) return;
    final draft = await showModalBottomSheet<_PromptDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PromptCreateSheet(
        initialCategory: _category == '全部' ? '' : _category,
      ),
    );
    if (draft == null || !mounted) return;

    setState(() => _creating = true);
    try {
      final created = await _repository.createPrompt(
        title: draft.title,
        content: draft.content,
        negativeContent: draft.negativeContent,
        category: draft.category,
        tags: draft.tags,
      );
      if (!mounted) return;
      if (_category == '全部' || _category == created.category) {
        setState(() => _prompts.insert(0, created));
      }
      _showMessage('Prompt 已保存');
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('保存失败：$error');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: premiumTopBar(
        title: 'Prompt 知识库',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RouteNames.homePath);
          }
        },
        actions: [
          PremiumCircleAction(
            icon: _creating ? null : Icons.add_rounded,
            content: _creating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.sage,
                    ),
                  )
                : null,
            tooltip: '投稿 Prompt',
            onPressed: _creating ? null : _openCreateSheet,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryRow(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        0,
      ),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: AppSpacing.radiusPill,
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: (_) => _loadFirstPage(),
          decoration: InputDecoration(
            hintText: '搜索标题、正文或标签',
            hintStyle: Theme.of(context).textTheme.bodySmall,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '清空',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      _loadFirstPage();
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.md,
        ),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return PremiumChoiceChip(
            label: category,
            selected: _category == category,
            compact: true,
            onTap: () => _changeCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _prompts.isEmpty) {
      return const LoadingView(message: '正在加载 Prompt…');
    }
    if (_error != null && _prompts.isEmpty) {
      return ErrorView(message: _error!, onRetry: _loadFirstPage);
    }
    if (_prompts.isEmpty) {
      return EmptyView(
        icon: Icons.menu_book_outlined,
        title: '没有找到 Prompt',
        description: '换个关键词或分类试试',
        actionLabel: _searchController.text.isNotEmpty || _category != '全部'
            ? '清空筛选'
            : null,
        onAction: () {
          _searchController.clear();
          setState(() => _category = '全部');
          _loadFirstPage();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      color: AppColors.sage,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              0,
              AppSpacing.pagePadding,
              AppSpacing.lg,
            ),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childCount: _prompts.length,
              itemBuilder: (context, index) {
                final prompt = _prompts[index];
                return _PromptCard(
                  prompt: prompt,
                  favoriteBusy: _favoriteBusyIds.contains(prompt.id),
                  onApply: () => _applyPrompt(prompt),
                  onCopy: () => _copyPrompt(prompt),
                  onFavorite: () => _toggleFavorite(prompt),
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);
    if (_loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              _loadMoreError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            TextButton(onPressed: _loadMore, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.sage,
            ),
          ),
        ),
      );
    }
    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text('— 没有更多了 —', style: theme.textTheme.bodySmall),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.xxl);
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.favoriteBusy,
    required this.onApply,
    required this.onCopy,
    required this.onFavorite,
  });

  final PromptModel prompt;
  final bool favoriteBusy;
  final VoidCallback onApply;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      child: GlassPanel(
        onTap: onApply,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sageTint,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    prompt.category ?? '其他',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.sage,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: prompt.favorited ? '取消收藏' : '收藏',
                    onPressed: favoriteBusy ? null : onFavorite,
                    icon: favoriteBusy
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            prompt.favorited
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 19,
                            color: prompt.favorited
                                ? AppColors.statusFailed
                                : AppColors.taupe,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              prompt.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              prompt.content,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.55),
            ),
            if (prompt.tagList.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: [
                  for (final tag in prompt.tagList.take(3))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Divider(
              height: 1,
              color: theme.dividerTheme.color ?? AppColors.divider,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 13,
                  color: AppColors.taupe,
                ),
                const SizedBox(width: 3),
                Text('${prompt.useCount}', style: theme.textTheme.labelSmall),
                const SizedBox(width: 8),
                Icon(
                  Icons.favorite_border_rounded,
                  size: 13,
                  color: AppColors.taupe,
                ),
                const SizedBox(width: 3),
                Text(
                  '${prompt.favoriteCount}',
                  style: theme.textTheme.labelSmall,
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: '复制',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 17),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '套用',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptDraft {
  const _PromptDraft({
    required this.title,
    required this.content,
    this.negativeContent,
    this.category,
    this.tags,
  });

  final String title;
  final String content;
  final String? negativeContent;
  final String? category;
  final String? tags;
}

class _PromptCreateSheet extends StatefulWidget {
  const _PromptCreateSheet({required this.initialCategory});

  final String initialCategory;

  @override
  State<_PromptCreateSheet> createState() => _PromptCreateSheetState();
}

class _PromptCreateSheetState extends State<_PromptCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _negativeController = TextEditingController();
  final _tagsController = TextEditingController();
  late final TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.initialCategory);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _negativeController.dispose();
    _tagsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    Navigator.pop(
      context,
      _PromptDraft(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        negativeContent: _negativeController.text.trim().isEmpty
            ? null
            : _negativeController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        tags: _tagsController.text.trim().isEmpty
            ? null
            : _tagsController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusHero),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.sm,
          AppSpacing.pagePadding,
          AppSpacing.lg + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.taupe.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('保存自定义 Prompt', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _titleController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '例如：极简商品主图',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入 Prompt 标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              PromptInputCard(
                controller: _contentController,
                title: 'Prompt 内容',
                hintText: '输入可直接用于生成的完整提示词…',
                maxLength: 4000,
                minLines: 4,
                maxLines: 8,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _negativeController,
                maxLength: 2000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '反向提示词（选填）',
                  hintText: '例如：文字、水印、低清晰度',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: '分类',
                        hintText: '电商 / 人物 / 风景',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _tagsController,
                      maxLength: 255,
                      decoration: const InputDecoration(
                        labelText: '标签',
                        hintText: '商品,极简',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _submit, child: const Text('保存 Prompt')),
            ],
          ),
        ),
      ),
    );
  }
}
