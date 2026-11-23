import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../creator_wallet_provider.dart';
import '../models/creator_wallet.dart';
import '../widgets/creator_widgets.dart';
import '../widgets/wallet_widgets.dart';

class CreatorProfilePage extends StatefulWidget {
  const CreatorProfilePage({super.key});

  @override
  State<CreatorProfilePage> createState() => _CreatorProfilePageState();
}

class _CreatorProfilePageState extends State<CreatorProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CreatorWalletProvider>().load(force: true);
    });
  }

  Future<void> _refresh() {
    return context.read<CreatorWalletProvider>().load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<CreatorWalletProvider>();
    final user = auth.user;
    final stats = wallet.stats;

    return CreatorScreen(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.sage,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        user?.username ?? '—',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '刷新钱包',
                  onPressed: wallet.refreshing ? null : _refresh,
                  icon: wallet.refreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            if (wallet.error != null) ...[
              const SizedBox(height: 14),
              _WalletErrorBanner(message: wallet.error!, onRetry: _refresh),
            ],
            const SizedBox(height: 20),
            _WalletHero(
              stats: stats,
              loading: wallet.loading,
              onRecharge: () => context.push('/recharge'),
              onWithdraw: stats != null && stats.withdrawableFen >= 1000
                  ? () => context.push('/withdraw')
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CreatorMetric(
                    label: '算力余额',
                    value: stats == null ? '—' : '${stats.credits}',
                    icon: Icons.bolt_rounded,
                    accent: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CreatorMetric(
                    label: '审核通过',
                    value: stats == null ? '—' : '${stats.approvedReviewCount}',
                    icon: Icons.verified_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CreatorMetric(
                    label: '待审核',
                    value: stats == null ? '—' : '${stats.pendingReviewCount}',
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
                  icon: Icons.auto_awesome_outlined,
                  label: '创作首页',
                  color: AppColors.sage,
                  onTap: () => context.go('/create'),
                ),
                _ToolTile(
                  icon: Icons.fact_check_outlined,
                  label: '作品与审核',
                  color: AppColors.gold,
                  onTap: () => context.push('/submissions'),
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
                  icon: Icons.school_outlined,
                  label: '课程中心',
                  color: AppColors.gold,
                  onTap: () => context.go('/course'),
                ),
                _ToolTile(
                  icon: Icons.logout_rounded,
                  label: '退出登录',
                  color: AppColors.statusFailed,
                  onTap: () async {
                    context.read<CreatorWalletProvider>().clear();
                    await auth.logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            CreatorSectionHeader(
              title: '最近现金流水',
              subtitle: '收入、提现冻结和退回均以后端账本为准',
              action: wallet.transactionTotal > 0
                  ? TextButton(
                      onPressed: () => context.push('/wallet/transactions'),
                      child: const Text('全部 ›'),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            _RecentTransactions(wallet: wallet),
            if (wallet.lastUpdated != null) ...[
              const SizedBox(height: 14),
              Text(
                '更新于 ${formatWalletDate(wallet.lastUpdated, withTime: true)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({
    required this.stats,
    required this.loading,
    required this.onRecharge,
    required this.onWithdraw,
  });

  final CreatorProfileStats? stats;
  final bool loading;
  final VoidCallback onRecharge;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E8B70), Color(0xFFA9B893), Color(0xFFC8AD79)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        boxShadow: AppColors.shadowButton,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '可提现余额',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              if (loading && stats == null)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stats == null ? '¥ —' : '¥ ${formatFen(stats!.withdrawableFen)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '仅审核通过的订单收入可提现',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11,
            ),
          ),
          if (stats != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CashPill(
                  label: '冻结 ¥${formatFen(stats!.frozenFen)}',
                  icon: Icons.lock_clock_rounded,
                ),
                _CashPill(
                  label: '累计收入 ¥${formatFen(stats!.totalIncomeFen)}',
                  icon: Icons.trending_up_rounded,
                ),
                _CashPill(
                  label: '累计提现 ¥${formatFen(stats!.totalWithdrawnFen)}',
                  icon: Icons.payments_outlined,
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _WalletButton(
                  label: '充值算力',
                  icon: Icons.add_card_rounded,
                  onTap: onRecharge,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WalletButton(
                  label: onWithdraw == null ? '暂无可提现' : '立即提现',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: onWithdraw,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashPill extends StatelessWidget {
  const _CashPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10.5),
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white54,
        side: BorderSide(
          color: Colors.white.withValues(alpha: onTap == null ? 0.18 : 0.36),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.12),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class _WalletErrorBanner extends StatelessWidget {
  const _WalletErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.statusFailed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.statusFailed.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: AppColors.statusFailed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.wallet});

  final CreatorWalletProvider wallet;

  @override
  Widget build(BuildContext context) {
    if (wallet.loading && wallet.recentTransactions.isEmpty) {
      return const GlassPanel(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (wallet.recentTransactions.isEmpty) {
      return EmptyPanel(
        icon: Icons.receipt_long_outlined,
        title: wallet.error == null ? '暂无现金流水' : '流水暂不可用',
        subtitle: wallet.error ?? '订单审核通过或提交提现后会显示记录。',
        actionLabel: wallet.error == null ? null : '重新加载',
        onAction: wallet.error == null ? null : () => wallet.load(force: true),
      );
    }

    return GlassPanel(
      child: Column(
        children: [
          for (var i = 0; i < wallet.recentTransactions.length; i++) ...[
            WalletTransactionRow(transaction: wallet.recentTransactions[i]),
            if (i != wallet.recentTransactions.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Divider(),
              ),
          ],
        ],
      ),
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
