import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

class CreatorProfilePage extends StatelessWidget {
  const CreatorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final flow = context.watch<CreatorFlowProvider>();
    final user = auth.user;

    return CreatorScreen(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: ListView(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nickname ?? user?.username ?? '创作者',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.username ?? 'demo_creator',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const CreatorTag(
                label: '认证创作者',
                color: AppColors.sage,
                icon: Icons.verified_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6E8B70),
                  Color(0xFFA9B893),
                  Color(0xFFC8AD79),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
              boxShadow: AppColors.shadowButton,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '我的荷包',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¥ ${flow.withdrawable.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '审核通过后可提现收入',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _WalletButton(
                        label: '充值算力',
                        icon: Icons.add_card_rounded,
                        onTap: () => context.push('/recharge'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _WalletButton(
                        label: '立即提现',
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: () => context.push('/withdraw'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CreatorMetric(
                  label: '算力余额',
                  value: flow.credits.toStringAsFixed(0),
                  icon: Icons.bolt_rounded,
                  accent: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CreatorMetric(
                  label: '审核通过',
                  value: '${flow.approvedCount}',
                  icon: Icons.verified_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CreatorMetric(
                  label: '待审核',
                  value: '${flow.pendingReviewCount}',
                  icon: Icons.schedule_rounded,
                  accent: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const CreatorSectionHeader(title: '创作与资金', subtitle: '常用功能入口'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              _ToolTile(
                icon: Icons.storefront_outlined,
                label: '接单大厅',
                color: AppColors.sage,
                onTap: () => context.go('/market'),
              ),
              _ToolTile(
                icon: Icons.dashboard_customize_outlined,
                label: '创作工作台',
                color: const Color(0xFF7B8EC8),
                onTap: () => context.go('/workbench'),
              ),
              _ToolTile(
                icon: Icons.fact_check_outlined,
                label: '审核记录',
                color: AppColors.gold,
                onTap: () => context.go('/submissions'),
              ),
              _ToolTile(
                icon: Icons.bolt_rounded,
                label: '充值算力',
                color: AppColors.gold,
                onTap: () => context.push('/recharge'),
              ),
              _ToolTile(
                icon: Icons.account_balance_wallet_outlined,
                label: '提现',
                color: AppColors.sage,
                onTap: () => context.push('/withdraw'),
              ),
              _ToolTile(
                icon: Icons.logout_rounded,
                label: '退出登录',
                color: AppColors.statusFailed,
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          CreatorSectionHeader(
            title: '最近流水',
            action: TextButton(
              onPressed: () => context.push('/withdraw'),
              child: const Text('去提现'),
            ),
          ),
          const SizedBox(height: 10),
          if (flow.walletEntries.isEmpty)
            const EmptyPanel(
              icon: Icons.receipt_long_outlined,
              title: '暂无流水',
              subtitle: '完成充值、创作或提现后会显示记录。',
            )
          else
            GlassPanel(
              child: Column(
                children: [
                  for (var i = 0; i < flow.walletEntries.length; i++) ...[
                    _WalletEntryRow(entry: flow.walletEntries[i]),
                    if (i != flow.walletEntries.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 11),
                        child: Divider(),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WalletButton extends StatelessWidget {
  const _WalletButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.36)),
        backgroundColor: Colors.white.withValues(alpha: 0.12),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletEntryRow extends StatelessWidget {
  const _WalletEntryRow({required this.entry});

  final WalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color, sign) = switch (entry.type) {
      WalletEntryType.income => (
        Icons.arrow_downward_rounded,
        AppColors.sage,
        '+',
      ),
      WalletEntryType.recharge => (Icons.add_card_rounded, AppColors.gold, '+'),
      WalletEntryType.consume => (Icons.bolt_rounded, AppColors.taupe, '-'),
      WalletEntryType.withdraw => (
        Icons.arrow_upward_rounded,
        AppColors.statusFailed,
        '-',
      ),
    };
    final unit = entry.isCredit ? ' 算力' : ' 元';
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 3),
              Text(
                _formatDate(entry.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          '$sign${entry.amount.toStringAsFixed(entry.isCredit ? 0 : 2)}$unit',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) => '${date.month}月${date.day}日';
}
