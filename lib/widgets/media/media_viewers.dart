import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 带占位与失败兜底的网络图片。
///
/// **刻意只用 Flutter 内置的 [Image.network]，不引入 cached_network_image。**
///
/// 原因：`cached_network_image` 会带进
/// `flutter_cache_manager → path_provider → path_provider_foundation → objective_c`
/// 一长串传递依赖，其中 `objective_c` 的 native assets 构建钩子会在部分
/// Dart SDK 上直接编译失败，导致 `flutter test / run / build` 全线报错
/// （不只是 iOS，Android 和 Web 一起挂）。删掉之后少了 27 个传递依赖。
///
/// 内置方案已经够用：
/// - 内存缓存由 Flutter 的 `ImageCache` 负责；
/// - Web 上的磁盘缓存由浏览器 HTTP 缓存负责；
/// - 占位与失败兜底用 [Image.network] 自带的 loadingBuilder / errorBuilder。
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  /// 自定义加载失败时的占位。
  ///
  /// 作品/线路封面用 [CoverImage] 时会传渐变占位进来，
  /// 比默认的破图图标好看得多；不传则用内置的破图占位。
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    // 空地址直接走失败兜底，避免 Image.network 抛异常刷屏
    final Widget image = url.isEmpty
        ? (errorWidget ?? _ErrorBox(width: width, height: height))
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            // 加载中：显示品牌色背景 + 转圈
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _PlaceholderBox(
                width: width,
                height: height,
                progress: progress.expectedTotalBytes == null
                    ? null
                    : progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!,
              );
            },
            // 加载失败：显示破图占位，不让异常冒泡到 UI
            errorBuilder: (context, error, stackTrace) =>
                errorWidget ?? _ErrorBox(width: width, height: height),
          );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({this.width, this.height, this.progress});

  final double? width;
  final double? height;

  /// 下载进度 0~1，服务器没给 Content-Length 时为 null。
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: progress == null
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
                value: progress,
              ),
            ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.statusFailed.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.statusFailed,
        size: 28,
      ),
    );
  }
}

/// 全屏图片预览页。
///
/// 支持双指缩放、双击放大、下拉关闭 —— 用 Flutter 内置的
/// [InteractiveViewer] 实现，**不依赖任何第三方预览库**，
/// 天然同时支持 Android 与 Web。
///
/// 用法：
/// ```dart
/// Navigator.of(context).push(MaterialPageRoute(
///   builder: (_) => ImagePreviewPage(imageUrl: work.imageUrl),
/// ));
/// ```
class ImagePreviewPage extends StatefulWidget {
  const ImagePreviewPage({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.title,
  }) : assert(
          imageUrl != null || imageBytes != null,
          'imageUrl 与 imageBytes 至少要传一个',
        );

  /// 网络图片地址（优先生效）。
  final String? imageUrl;

  /// 本地字节流，用于「刚选完还没上传」的预览场景。
  final Uint8List? imageBytes;

  final String? title;

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  final TransformationController _transform = TransformationController();

  /// 双击放大的目标倍数。
  static const double _zoomScale = 2.5;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? '预览'),
        actions: [
          // 复位缩放
          IconButton(
            tooltip: '还原',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () => _transform.value = Matrix4.identity(),
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: 5,
          // 放大后允许拖动查看细节
          panEnabled: true,
          child: Center(child: _buildImage()),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return AppNetworkImage(url: widget.imageUrl!, fit: BoxFit.contain);
    }
    return Image.memory(widget.imageBytes!, fit: BoxFit.contain);
  }

  TapDownDetails? _lastTapDown;

  void _handleDoubleTapDown(TapDownDetails details) => _lastTapDown = details;

  /// 双击以点击位置为中心放大 / 还原。
  void _handleDoubleTap() {
    if (_transform.value.getMaxScaleOnAxis() > 1.01) {
      _transform.value = Matrix4.identity();
      return;
    }

    final position = _lastTapDown?.localPosition;
    if (position == null) return;

    _transform.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (_zoomScale - 1),
        -position.dy * (_zoomScale - 1),
        0,
        1,
      )
      ..scaleByDouble(_zoomScale, _zoomScale, 1, 1);
  }
}

/// 视频播放页。
///
/// 用 [video_player]（Android 用 ExoPlayer、Web 用 HTML5 video）
/// 加 [chewie] 提供播放控件，两端共用一套代码。
///
/// 注意：Web 端能否播放取决于后端返回的视频格式与 CORS 配置，
/// 后端静态资源需要放开 `Access-Control-Allow-Origin`。
class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key, required this.url, this.title});

  /// 视频地址，必须是完整 URL（用 AppConfig.resolveAssetUrl 拼过）。
  final String url;

  final String? title;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  String? _error;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _videoController = controller;

      await controller.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        aspectRatio: controller.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.secondary,
          bufferedColor: AppColors.primary.withValues(alpha: 0.3),
          backgroundColor: Colors.white24,
        ),
        errorBuilder: (context, message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              '视频播放失败\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );

      setState(() => _initializing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '视频加载失败：$e';
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    // 顺序很重要：先释放 Chewie，再释放底层 VideoPlayerController
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? '视频播放'),
      ),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }
}
