import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/creator_widgets.dart';

const _courses = [
  _CourseItem(
    coverIndex: 0,
    tag: '线下培训',
    title: 'AI 电商创作训练营',
    subtitle: '从商品图、短视频到数字人，完整跑通一条接单链路',
    meta: '上海 · 第 6 期 · 12 月 12 日',
    progress: 0.0,
    action: '查看详情',
    highlights: ['商品主图与提示词', '短视频与数字人', '接单实战与审核'],
  ),
  _CourseItem(
    coverIndex: 1,
    tag: '线上课程',
    title: '商品主图：用对提示词，少改十版',
    subtitle: '风格、光线、场景与比例的高效写法',
    meta: '12 节 · 林老师',
    progress: 0.35,
    action: '继续学习',
    highlights: ['光与影', '电商构图', '常见改稿问题'],
  ),
  _CourseItem(
    coverIndex: 2,
    tag: '线上课程',
    title: '数字人口播：从文案到成片',
    subtitle: '音色、口型与节奏的完整演示',
    meta: '8 节 · 周老师',
    progress: 0.0,
    action: '开始学习',
    highlights: ['口播文案', '数字人选择', '成片节奏'],
  ),
];

class _CourseItem {
  const _CourseItem({
    required this.coverIndex,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.progress,
    required this.action,
    required this.highlights,
  });

  final int coverIndex;
  final String tag;
  final String title;
  final String subtitle;
  final String meta;
  final double progress;
  final String action;
  final List<String> highlights;
}

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
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
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
          _CourseCard(
            course: _courses[0],
            onTap: () => _showCourseDetail(context, _courses[0]),
          ),
          const SizedBox(height: 12),
          _CourseCard(
            course: _courses[1],
            onTap: () => _showCourseDetail(context, _courses[1]),
          ),
          const SizedBox(height: 12),
          _CourseCard(
            course: _courses[2],
            onTap: () => _showCourseDetail(context, _courses[2]),
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

void _showCourseDetail(BuildContext context, _CourseItem course) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CourseDetailSheet(course: course),
  );
}

class _CourseDetailSheet extends StatelessWidget {
  const _CourseDetailSheet({required this.course});

  final _CourseItem course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.72,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.warmBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.taupe.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.tag, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 5),
                        Text(course.title, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 6),
                        Text(course.meta, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text(course.subtitle, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 18),
                  Text('课程亮点', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  for (final highlight in course.highlights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.sage,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              highlight,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    '课程内容当前为原型演示数据，报名和考核暂未接入后端。',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/create');
                },
                child: const Text('去创作'),
              ),
            ),
          ],
        ),
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
  const _CourseCard({required this.course, required this.onTap});

  final _CourseItem course;
  final VoidCallback onTap;

  static const _covers = [
    [Color(0xFF7C9A7E), Color(0xFFA9C3A6)],
    [Color(0xFFC9A96E), Color(0xFFE7D3A1)],
    [Color(0xFF6E8B9A), Color(0xFFA7C4D0)],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = _covers[course.coverIndex % _covers.length];
    return GlassPanel(
      padding: EdgeInsets.zero,
      onTap: onTap,
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
                      course.tag,
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
                Text(course.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  course.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(course.meta, style: theme.textTheme.bodySmall),
                if (course.progress > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: LinearProgressIndicator(
                      value: course.progress,
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
                      onPressed: onTap,
                      child: Text(course.action),
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
