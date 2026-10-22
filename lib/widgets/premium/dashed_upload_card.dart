import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'pressable_scale.dart';

/// 模板中的大尺寸虚线选择区域。
class DashedUploadCard extends StatelessWidget {
  const DashedUploadCard({
    super.key,
    required this.child,
    required this.onTap,
    this.height = 190,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback onTap;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      child: PressableScale(
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _DashedRoundedBorderPainter(
                color: isDark
                    ? AppColors.sageSoft.withValues(alpha: 0.5)
                    : AppColors.sage.withValues(alpha: 0.42),
              ),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.5)
                      : AppColors.glass.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(0.8),
          const Radius.circular(AppSpacing.radiusCard),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 7, metric.length)),
          paint,
        );
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
