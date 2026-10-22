import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'media/media_viewers.dart';

/// 通用封面图组件。
///
/// 后端还没返回封面 URL 时（`url` 为空），渲染一个**由种子决定的渐变色块**，
/// 而不是破图占位或灰底 —— 这样开发阶段和答辩演示时页面也是好看的，
/// 不会因为没接后端就显得很潦草。
///
/// 同一个种子永远得到同一组颜色（自己实现的稳定哈希，不依赖
/// `String.hashCode`——它在不同 Dart 版本/平台上不保证一致），
/// 所以列表刷新、页面重建时封面颜色不会乱跳。
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.seed,
    this.url,
    this.icon,
    this.label,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  /// 渐变色的决定种子，一般传 `skill.code` 或 `'work_${work.id}'`。
  final String seed;

  /// 真实封面地址。为空则用渐变占位。
  final String? url;

  /// 渐变色块上的图标。
  final IconData? icon;

  /// 渐变色块左下角的文字（一般不用传，卡片下方已有标题）。
  final String? label;

  final BorderRadius? borderRadius;
  final BoxFit fit;

  /// 原型里的暖色/莫兰迪色板：奶油、蜜桃、鼠尾草、灰褐。
  static const List<List<Color>> _palettes = [
    [Color(0xFFE8D5C4), Color(0xFFD4B896)], // 蜜桃 → 香槟
    [Color(0xFFC7D5C0), Color(0xFFA8BFA0)], // 鼠尾草浅 → 深
    [Color(0xFFF0DCC8), Color(0xFFE4C9A8)], // 奶油 → 金
    [Color(0xFFD8D0C0), Color(0xFFBFB39E)], // 燕麦 → 灰褐
    [Color(0xFFE5D5D5), Color(0xFFC9AEAE)], // 藕粉 → 豆沙
    [Color(0xFFD0DCE5), Color(0xFFA8BFC9)], // 雾蓝 → 灰蓝
    [Color(0xFFF5EDDE), Color(0xFFE4D0A8)], // 暖白 → 淡金
    [Color(0xFFE0E8DC), Color(0xFFA8BFA9)], // 浅绿 → 鼠尾草
  ];

  /// 稳定哈希：同样的字符串在任何平台、任何次运行都得到同样的值。
  ///
  /// 不用 `String.hashCode` 是因为 Dart 没有承诺它跨版本稳定，
  /// 万一变了会导致封面颜色在版本升级后集体变色。
  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return hash;
  }

  /// 当前种子对应的渐变。
  LinearGradient get _gradient {
    final palette = _palettes[_stableHash(seed) % _palettes.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: palette,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    final Widget child = hasUrl
        ? AppNetworkImage(
            url: url!,
            fit: fit,
            borderRadius: borderRadius,
            // 真实图片加载失败时，退回渐变占位，而不是破图图标
            errorWidget: _buildPlaceholder(),
          )
        : _buildPlaceholder();

    return child;
  }

  Widget _buildPlaceholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: AppColors.charcoal.withValues(alpha: 0.55),
                size: 30,
              ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.charcoal.withValues(alpha: 0.68),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
