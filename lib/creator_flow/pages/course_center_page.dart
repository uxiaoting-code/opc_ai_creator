import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/creator_widgets.dart';

/// 原型中的「课程中心」一级 Tab。
///
/// 当前课程数据由本地固定配置提供（真实课程后端尚未落地），
/// 首轮只做与原型一致的视觉和导航入口，避免阻塞 AI 创作主线。
class CourseCenterPage extends StatelessWidget {
  const CourseCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CreatorScreen(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('课程中心', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      '从入门到接单，掌握 AI 电商创作',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              CreatorTag(
                label: '成长体系',
                color: AppColors.sage,
                icon: Icons.trending_up_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _CourseBanner(),
          const SizedBox(height: 22),
          const CreatorSectionHeader(
            title: '推荐课程',
            subtitle: '课程内容当前为原型演示数据',
          ),
          const SizedBox(height: 12),
          const _CourseCard(
            coverIndex: 0,
            tag: '线下培训',
            title: 'AI 电商创作训练营',
            subtitle: '从商品图、短视频到数字人，完整跑通一条接单链路',
            meta: '上海 · 第 6 期 · 12 月 12 日',
            progress: 0.0,
            action: '查看详情',
          ),
          const SizedBox(height: 12),
          const _CourseCard(
            coverIndex: 1,
            tag: '线上课程',
            title: '商品主图：用对提示词，少改十版',
            subtitle: '风格、光线、场景与比例的高效写法',
            meta: '12 节 · 林老师',
            progress: 0.35,
            action: '继续学习',
          ),
          const SizedBox(height: 12),
          const _CourseCard(
            coverIndex: 2,
            tag: '线上课程',
            title: '数字人口播：从文案到成片',
            subtitle: '音色、口型与节奏的完整演示',
            meta: '8 节 · 周老师',
            progress: 0.0,
            action: '开始学习',
          ),
          const SizedBox(height: 18),
          GlassPanel(
            backgroundColor: AppColors.sage.withValues(alpha: 0.07),
            borderColor: AppColors.sage.withValues(alpha: 0.18),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.sage,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '课程报名、签到和考核当前尚未接入真实后端，先作为原型页面展示。',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseBanner extends StatelessWidget {
  const _CourseBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 168,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7C9A7E),
            Color(0xFF9DB48F),
            Color(0xFFC9A96E),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        boxShadow: AppColors.shadowButton,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -42,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 8,
            child: Icon(
              Icons.school_rounded,
              size: 92,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 电商创作训练营',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '通过培训、实操和考核，解锁更高难度的接单任务',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.sage,
                      minimumSize: const Size(104, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () => context.go('/create'),
                    child: const Text('去创作', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.coverIndex,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.progress,
    required this.action,
  });

  final int coverIndex;
  final String tag;
  final String title;
  final String subtitle;
  final String meta;
  final double progress;
  final String action;

  static const _covers = [
    [Color(0xFF7C9A7E), Color(0xFFA9C3A6)],
    [Color(0xFFC9A96E), Color(0xFFE7D3A1)],
    [Color(0xFF6E8B9A), Color(0xFFA7C4D0)],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = _covers[coverIndex % _covers.length];
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 104,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 14,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white.withValues(alpha: 0.82),
                    size: 44,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(meta, style: theme.textTheme.bodySmall),
                if (progress > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.sageTint,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => context.go('/create'),
                      child: Text(action),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
