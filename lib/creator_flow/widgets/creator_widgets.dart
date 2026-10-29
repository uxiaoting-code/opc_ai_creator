import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../creator_flow/models/creator_models.dart';
import '../../widgets/premium/glass_panel.dart';
import '../../widgets/premium/premium_choice_chip.dart';
import '../../widgets/premium/premium_top_bar.dart';
import '../../widgets/premium/pressable_scale.dart';
export '../../widgets/premium/glass_panel.dart';

class CreatorScreen extends StatelessWidget {
  const CreatorScreen({
    super.key,
    required this.child,
    this.title,
    this.onBack,
    this.actions = const [],
    this.floatingActionButton,
    this.padding = const EdgeInsets.fromLTRB(20, 6, 20, 24),
  });

  final Widget child;
  final String? title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: title == null
          ? null
          : premiumTopBar(title: title!, onBack: onBack, actions: actions),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        top: title == null,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class CreatorSectionHeader extends StatelessWidget {
  const CreatorSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class CreatorHeroCard extends StatelessWidget {
  const CreatorHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.gradient,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6F8E70), Color(0xFFA7B58E), Color(0xFFC8AD79)],
            ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        boxShadow: AppColors.shadowButton,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -44,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ],
      ),
    );
  }
}

class CreatorMetric extends StatelessWidget {
  const CreatorMetric({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent = AppColors.sage,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 15, color: accent),
              if (icon != null) const SizedBox(width: 5),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class CreatorTag extends StatelessWidget {
  const CreatorTag({
    super.key,
    required this.label,
    this.color = AppColors.sage,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewStatusBadge extends StatelessWidget {
  const ReviewStatusBadge({super.key, required this.status});

  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      ReviewStatus.pending => (AppColors.gold, Icons.schedule_rounded),
      ReviewStatus.approved => (AppColors.sage, Icons.check_circle_rounded),
      ReviewStatus.rejected => (AppColors.statusFailed, Icons.cancel_rounded),
    };
    return CreatorTag(label: status.label, color: color, icon: icon);
  }
}

class CreationModeIcon extends StatelessWidget {
  const CreationModeIcon({
    super.key,
    required this.mode,
    this.size = 38,
    this.color,
  });

  final CreationMode mode;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      CreationMode.image => Icons.auto_awesome_rounded,
      CreationMode.video => Icons.movie_filter_rounded,
      CreationMode.audio => Icons.graphic_eq_rounded,
    };
    final tone = color ?? _modeColor(mode);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: tone, size: size * 0.5),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final MarketOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CreationModeIcon(mode: order.mode),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${order.brand} · ${order.mode.shortLabel} · ${order.deadline}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '¥${order.reward.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.sage,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CreatorTag(
                label: order.status.label,
                color: _orderStatusColor(order.status),
              ),
              const SizedBox(width: 8),
              CreatorTag(
                label: '剩余 ${order.tasksLeft} 个名额',
                color: AppColors.taupe,
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.taupe,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            PremiumChoiceChip(
              label: labels[i],
              selected: selectedIndex == i,
              onTap: () => onChanged(i),
              compact: true,
            ),
            if (i != labels.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class ArtworkPreview extends StatelessWidget {
  const ArtworkPreview({
    super.key,
    required this.mode,
    required this.seed,
    this.height = 230,
    this.showLabel = true,
    this.onTap,
  });

  final CreationMode mode;
  final int seed;
  final double height;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _artworkColors(mode, seed);
    final icon = switch (mode) {
      CreationMode.image => Icons.image_rounded,
      CreationMode.video => Icons.play_circle_fill_rounded,
      CreationMode.audio => Icons.graphic_eq_rounded,
    };
    final label = switch (mode) {
      CreationMode.image => 'AI IMAGE',
      CreationMode.video => 'AI VIDEO',
      CreationMode.audio => 'AI AUDIO',
    };

    final card = Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        boxShadow: AppColors.shadowLift,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -50,
            top: -60,
            child: _Orb(size: 190, color: Colors.white.withValues(alpha: 0.18)),
          ),
          Positioned(
            left: -44,
            bottom: -75,
            child: _Orb(
              size: 210,
              color: AppColors.charcoal.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            left: 22,
            top: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
              ),
              child: Icon(icon, color: Colors.white, size: 38),
            ),
          ),
          if (mode == CreationMode.audio)
            Align(
              alignment: const Alignment(0, 0.55),
              child: _Waveform(seed: seed),
            ),
          if (showLabel)
            Positioned(
              left: 22,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${mode.label} · 预览稿',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '由 AI 工作台生成',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return card;
    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
          child: card,
        ),
      ),
    );
  }
}

class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: Theme.of(context).textTheme.titleSmall,
          children: [
            if (required)
              const TextSpan(
                text: '  *',
                style: TextStyle(color: AppColors.statusFailed),
              ),
          ],
        ),
      ),
    );
  }
}

class CreatorBottomAction extends StatelessWidget {
  const CreatorBottomAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.caption,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? caption;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (caption != null) ...[
              Text(caption!, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 7),
            ],
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: icon == null
                    ? const SizedBox.shrink()
                    : Icon(icon, size: 18),
                label: Text(label),
              ),
            ),
            if (secondaryLabel != null)
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ),
      ),
    );
  }
}

class ChannelTile extends StatelessWidget {
  const ChannelTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color = AppColors.sage,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      borderColor: selected ? color.withValues(alpha: 0.65) : null,
      backgroundColor: selected ? color.withValues(alpha: 0.06) : null,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? color : AppColors.taupe,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 34),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.sageTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.sage, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

Future<void> showCreatorSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = '知道了',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(
        Icons.check_circle_rounded,
        color: AppColors.sage,
        size: 42,
      ),
      title: Text(title),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}

Color _modeColor(CreationMode mode) {
  return switch (mode) {
    CreationMode.image => AppColors.sage,
    CreationMode.video => const Color(0xFF7B8EC8),
    CreationMode.audio => AppColors.gold,
  };
}

Color _orderStatusColor(MarketOrderStatus status) {
  return switch (status) {
    MarketOrderStatus.open => AppColors.sage,
    MarketOrderStatus.accepted => const Color(0xFF7B8EC8),
    MarketOrderStatus.submitted => AppColors.gold,
    MarketOrderStatus.approved => AppColors.sage,
    MarketOrderStatus.rejected => AppColors.statusFailed,
  };
}

List<Color> _artworkColors(CreationMode mode, int seed) {
  final palettes = switch (mode) {
    CreationMode.image => const [
      [Color(0xFFE7D2BB), Color(0xFFC9A96E)],
      [Color(0xFFCAD9C5), Color(0xFF7C9A7E)],
      [Color(0xFFE2D7CA), Color(0xFFA88F77)],
      [Color(0xFFD8C8B8), Color(0xFF8C7865)],
    ],
    CreationMode.video => const [
      [Color(0xFF252E42), Color(0xFF7B8EC8)],
      [Color(0xFF263832), Color(0xFF7C9A7E)],
      [Color(0xFF3D2E2D), Color(0xFFC48772)],
      [Color(0xFF2B3142), Color(0xFF9A88C7)],
    ],
    CreationMode.audio => const [
      [Color(0xFFD3B47B), Color(0xFF8D774F)],
      [Color(0xFFA9BCA7), Color(0xFF617C65)],
      [Color(0xFFC8A9A0), Color(0xFF8A6862)],
      [Color(0xFFB7B2CA), Color(0xFF777092)],
    ],
  };
  return palettes[seed.abs() % palettes.length];
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final random = math.Random(seed);
    return SizedBox(
      height: 42,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(22, (index) {
          final height = 8.0 + random.nextDouble() * 26;
          return Container(
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}
