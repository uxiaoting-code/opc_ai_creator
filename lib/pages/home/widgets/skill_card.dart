import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/skill_model.dart';
import '../../../widgets/cover_image.dart';

/// 首页 Skill 线路卡片（横向滑动列表的单元）。
///
/// 点击直接带着 skillId 进入对应类型的创作页 ——
/// 这就是「首页 = Skill 选择入口」的含义：**一次点击即可开始创作**，
/// 不需要先进创作页再选线路。
class SkillCard extends StatelessWidget {
  const SkillCard({
    super.key,
    required this.skill,
    required this.onTap,
    this.width = 136,
  });

  final SkillModel skill;
  final VoidCallback onTap;
  final double width;

  /// 封面高度。
  static const double _coverHeight = 104;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: theme.dividerTheme.color ?? Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------- 封面 ----------
                SizedBox(
                  height: _coverHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverImage(
                        seed: skill.code,
                        url: skill.coverUrl,
                        icon: skill.type == SkillType.textToImage
                            ? Icons.auto_awesome
                            : Icons.movie_creation_outlined,
                      ),
                      // 类型角标：文生图 / 图生视频
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.42),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                          child: Text(
                            skill.type.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- 文字区 ----------
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm + 2,
                    AppSpacing.sm,
                    AppSpacing.sm + 2,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        skill.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              skill.scene ?? '通用场景',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                          // 热度，体现线路的受欢迎程度
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 11,
                            color: AppColors.accent.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            skill.usageLabel,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
