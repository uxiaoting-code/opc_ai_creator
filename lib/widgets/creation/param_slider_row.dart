import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 一行“标题 + 滑杆 + 数值”的参数控件。
class ParamSliderRow extends StatelessWidget {
  const ParamSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.valueLabel,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text(
              valueLabel ?? value.toStringAsFixed(1),
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.sage,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.sage,
            inactiveTrackColor: AppColors.sageTint,
            thumbColor: AppColors.sage,
            overlayColor: AppColors.sage.withValues(alpha: 0.12),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
