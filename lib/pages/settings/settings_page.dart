import 'package:flutter/material.dart';
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
            icon: Icons.palette_outlined,
            children: [
              _SettingTile(
                title: '主题模式',
                subtitle: themeProvider.themeModeLabel,
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined, size: 18),
                    ),
                  ],
                  selected: {themeProvider.themeMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      themeProvider.setThemeMode(selection.first),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ---------- 已实现：环境信息 ----------
          _SectionCard(
            title: '环境信息（调试用）',
            icon: Icons.dns_outlined,
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
                valueColor:
                    AppConfig.bypassLogin ? AppColors.accent : AppColors.statusSuccess,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.transparent),
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

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium),
              if (subtitle != null)
                Text(subtitle!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        ?trailing,
      ],
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
