import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/platform_utils.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/scaffold_page.dart';

/// 页面 12：设置页
///
/// 「环境信息」与「主题切换」两块已经实现且真实可用 ——
/// 因为这两项直接关系到「Web 用 localhost / Android 用局域网 IP」的调试方式，
/// 联调时必须能一眼看出当前连的是哪个后端。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return ScaffoldPage(
      pageNumber: 12,
      title: '设置',
      routePath: RouteNames.settingsPath,
      icon: Icons.settings_rounded,
      summary: '环境切换、主题外观、生成默认参数、缓存与关于',
      plannedFeatures: [
        '生成默认参数：默认线路、默认尺寸、默认生成数量',
        '缓存管理：查看占用、清理图片缓存',
        '通知设置：任务完成提醒',
        '账号安全：修改密码、注销账号',
        '关于：版本号、开源许可、项目说明',
        '意见反馈',
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- 已实现：主题切换 ----------
          _SectionCard(
            title: '外观',
            icon: CupertinoIcons.paintbrush,
            children: [
              Text('主题模式', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              CupertinoSlidingSegmentedControl<ThemeMode>(
                groupValue: themeProvider.themeMode,
                backgroundColor: AppColors.sageTint.withValues(alpha: 0.55),
                thumbColor: theme.colorScheme.surface,
                padding: const EdgeInsets.all(3),
                children: const {
                  ThemeMode.light: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Icon(CupertinoIcons.sun_max, size: 18),
                  ),
                  ThemeMode.system: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Icon(CupertinoIcons.circle_lefthalf_fill, size: 18),
                  ),
                  ThemeMode.dark: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Icon(CupertinoIcons.moon, size: 18),
                  ),
                },
                onValueChanged: (mode) {
                  if (mode == null) return;
                  HapticFeedback.selectionClick();
                  themeProvider.setThemeMode(mode);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                themeProvider.themeModeLabel,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ---------- 已实现：环境信息 ----------
          _SectionCard(
            title: '环境信息（调试用）',
            icon: CupertinoIcons.info_circle,
            children: [
              _InfoTile(label: '当前环境', value: AppConfig.envLabel),
              _InfoTile(label: '运行平台', value: PlatformUtils.platformName),
              _InfoTile(
                label: '后端地址',
                value: AppConfig.baseUrl,
                monospace: true,
              ),
              _InfoTile(
                label: '静态资源',
                value: AppConfig.assetBaseUrl,
                monospace: true,
              ),
              _InfoTile(
                label: '登录模式',
                value: AppConfig.bypassLogin ? '脚手架放行（未连后端）' : '真实接口',
                valueColor: AppConfig.bypassLogin
                    ? AppColors.accent
                    : AppColors.statusSuccess,
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  PlatformUtils.isWeb
                      ? 'Web 调试：后端跑在本机，直接用 localhost。'
                      : 'Android 真机：手机访问不到 localhost，必须用电脑的局域网 IP，'
                            '并确保手机与电脑在同一 WiFi、后端监听 0.0.0.0。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ---------- 待实现清单 ----------
          _SectionCard(
            title: '待实现',
            icon: Icons.construction_outlined,
            children: const [
              _TodoTile('生成默认参数（默认线路 / 尺寸 / 数量）'),
              _TodoTile('缓存管理：查看占用、清理图片缓存'),
              _TodoTile('通知设置：任务完成提醒'),
              _TodoTile('账号安全：修改密码、注销账号'),
              _TodoTile('关于：版本号、开源许可'),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          OutlinedButton.icon(
            onPressed: () => context.push(RouteNames.componentGalleryPath),
            icon: const Icon(Icons.widgets_outlined, size: 18),
            label: const Text('打开组件预览（开发用）'),
          ),

          const SizedBox(height: AppSpacing.xl),

          Center(
            child: Text(
              'OPC AI 创作平台 · 课程设计脚手架 v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.82)
            : AppColors.glass,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.white.withValues(alpha: 0.7),
        ),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.monospace = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool monospace;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: valueColor ?? theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(
            Icons.check_box_outline_blank_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
