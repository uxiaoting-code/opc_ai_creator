import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/creator_wallet.dart';

IconData walletTransactionIcon(WalletTransactionKind kind) {
  return switch (kind) {
    WalletTransactionKind.orderIncome => Icons.arrow_downward_rounded,
    WalletTransactionKind.withdrawFreeze => Icons.lock_clock_rounded,
    WalletTransactionKind.withdrawSuccess => Icons.arrow_upward_rounded,
    WalletTransactionKind.withdrawRefund => Icons.replay_rounded,
    WalletTransactionKind.manualAdjust => Icons.tune_rounded,
    WalletTransactionKind.unknown => Icons.receipt_long_rounded,
  };
}

Color walletTransactionColor(WalletTransactionKind kind) {
  return switch (kind) {
    WalletTransactionKind.orderIncome ||
    WalletTransactionKind.withdrawRefund => AppColors.sage,
    WalletTransactionKind.withdrawFreeze => AppColors.gold,
    WalletTransactionKind.withdrawSuccess => AppColors.statusFailed,
    WalletTransactionKind.manualAdjust => AppColors.taupe,
    WalletTransactionKind.unknown => AppColors.taupe,
  };
}

IconData walletChannelIcon(String? code, String? icon) {
  final value = '${code ?? ''} ${icon ?? ''}'.toLowerCase();
  if (value.contains('alipay')) {
    return Icons.account_balance_wallet_rounded;
  }
  if (value.contains('wechat')) return Icons.chat_bubble_rounded;
  if (value.contains('unionpay')) return Icons.credit_card_rounded;
  if (value.contains('bank')) return Icons.account_balance_rounded;
  return Icons.payments_outlined;
}

Color walletChannelColor(String code) {
  return switch (code.toUpperCase()) {
    'ALIPAY' => const Color(0xFF1677FF),
    'WECHAT' => const Color(0xFF2AAE67),
    'UNIONPAY' => const Color(0xFFC04A5A),
    'BANK' => AppColors.taupe,
    _ => AppColors.sage,
  };
}

String formatWalletDate(DateTime? date, {bool withTime = false}) {
  if (date == null) return '—';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return withTime
      ? '${date.year}-$month-$day $hour:$minute'
      : '$month-$day $hour:$minute';
}

class WalletTransactionRow extends StatelessWidget {
  const WalletTransactionRow({
    super.key,
    required this.transaction,
    this.showBalance = false,
  });

  final CreatorWalletTransaction transaction;
  final bool showBalance;

  @override
  Widget build(BuildContext context) {
    final color = walletTransactionColor(transaction.kind);
    final delta = transaction.displayDeltaFen;
    final sign = delta > 0 ? '+' : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            walletTransactionIcon(transaction.kind),
            color: color,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$sign¥${formatFen(delta)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    transaction.typeLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatWalletDate(
                      transaction.createdAt,
                      withTime: showBalance,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (showBalance) ...[
                    const Spacer(),
                    Text(
                      '余额 ¥${formatFen(transaction.balanceAfterFen)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
