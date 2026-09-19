import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/work_model.dart';
import '../../../widgets/cover_image.dart';

/// 首页「最近作品」横滑区的作品缩略图（对应需求 5）。
///
/// 视频作品会在封面上叠一个播放角标 + 时长，
/// 让用户在列表里就能区分图片和视频，不用点进去才知道。
class RecentWorkCard extends StatelessWidget {
  const RecentWorkCard({
    super.key,
    required this.work,
    required this.onTap,
    this.size = 112,
  });

  final WorkModel work;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 封面：没有 URL 时用作品 ID 作种子生成固定渐变色
              CoverImage(
                seed: 'work_${work.id}',
                url: work.coverUrl?.isNotEmpty == true
                    ? work.coverUrl
                    : work.resourceUrl,
                icon: work.isVideo
                    ? Icons.movie_outlined
                    : Icons.image_outlined,
              ),

              // 底部渐变压暗，保证角标文字在任何封面上都看得清
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),

              // 左下角：作品标题
              Positioned(
                left: 6,
                right: 6,
                bottom: 5,
                child: Text(
                  work.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // 右上角：视频时长
              if (work.isVideo && work.durationLabel != null)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      work.durationLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // 视频中央播放角标
              if (work.isVideo)
                Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
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
