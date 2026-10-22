import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 结果预览卡：图片 / 视频 / 占位三种状态。
class ResultPreviewCard extends StatelessWidget {
  const ResultPreviewCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.videoUrl,
    this.onTap,
    this.aspectRatio = 4 / 3,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? videoUrl;
  final VoidCallback? onTap;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = videoUrl;
    final image = imageUrl;
    final isVideo = video != null && video.isNotEmpty;
    final url = isVideo ? video : image;
    final hasUrl = url != null && url.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          boxShadow: AppColors.shadowSoft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasUrl)
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  else
                    _placeholder(),
                  if (isVideo)
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.42),
                        ),
                        child: const Icon(
                          CupertinoIcons.play_fill,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.warmGradient),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 40,
          color: AppColors.charcoal.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
