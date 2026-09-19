import 'package:flutter/material.dart';

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

  /// 渐变色板。都是「深底 + 高饱和」的组合，叠白色图标好看。
  static const List<List<Color>> _palettes = [
    [Color(0xFF6C4DF6), Color(0xFF17C3E6)], // 电光紫 → 青蓝（品牌主渐变）
    [Color(0xFFFF5A9E), Color(0xFF6C4DF6)], // 品红 → 紫
    [Color(0xFF12B76A), Color(0xFF17C3E6)], // 翠绿 → 青蓝
    [Color(0xFFFF8A3D), Color(0xFFFF5A9E)], // 橙 → 品红
    [Color(0xFF2E90FA), Color(0xFF6C4DF6)], // 蓝 → 紫
    [Color(0xFF8B5CF6), Color(0xFFFF8A3D)], // 紫 → 橙
    [Color(0xFF0EA5E9), Color(0xFF12B76A)], // 天蓝 → 翠绿
    [Color(0xFFF04438), Color(0xFFFF8A3D)], // 红 → 橙
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
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 30),
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
                    color: Colors.white.withValues(alpha: 0.95),
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
