import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../creator_wallet_provider.dart';
import '../models/creator_wallet.dart';
import '../widgets/creator_widgets.dart';
import '../widgets/wallet_widgets.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CreatorWalletProvider>().load(force: true);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int? get _amountFen => parseYuanToFen(_amount.text);

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<CreatorWalletProvider>();
    final stats = wallet.stats;
    final available = stats?.withdrawableFen ?? 0;
    final amountFen = _amountFen ?? 0;
    final amountInvalid = _amount.text.trim().isNotEmpty && _amountFen == null;
    final canContinue =
        stats != null &&
        !amountInvalid &&
        amountFen >= 1000 &&
        amountFen <= available;

    return CreatorScreen(
      title: '提现',
      onBack: () => context.pop(),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => wallet.load(force: true),
              color: AppColors.sage,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6E8B70),
                          Color(0xFF9FAF8D),
                          Color(0xFFC8AD79),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusHero,
                      ),
                      boxShadow: AppColors.shadowButton,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '可提现余额',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stats == null ? '¥ —' : '¥ ${formatFen(available)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stats == null
                              ? '正在读取真实钱包余额'
                              : '冻结 ¥${formatFen(stats.frozenFen)} · 仅审核通过收入可提现',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (wallet.error != null) ...[
                    const SizedBox(height: 14),
                    _InlineError(
                      message: wallet.error!,
                      onRetry: () => wallet.load(force: true),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const CreatorSectionHeader(
                    title: '提现金额',
                    subtitle: '最低提现 10 元，金额会先冻结再进入打款流程',
                  ),
                  const SizedBox(height: 12),
                  GlassPanel(
                    child: Column(
                      children: [
                        TextField(
                          controller: _amount,
                          enabled: stats != null && !wallet.loading,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            prefixText: '¥ ',
                            hintText: '0.00',
                            errorText: amountInvalid ? '请输入有效金额，最多两位小数' : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '当前可提现 ¥${formatFen(available)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: stats == null || available <= 0
                                  ? null
                                  : () {
                                      _amount.text = formatFen(available);
                                      setState(() {});
                                    },
                              child: const Text('全部提现'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_amount.text.trim().isNotEmpty && !amountInvalid) ...[
                    const SizedBox(height: 8),
                    Text(
                      amountFen < 1000
                          ? '提现金额不能低于 ¥10.00'
                          : amountFen > available
                          ? '提现金额不能超过可提现余额'
                          : '提交后余额将冻结 ¥${formatFen(amountFen)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: canContinue
                            ? AppColors.sage
                            : AppColors.statusFailed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  GlassPanel(
                    child: Column(
                      children: const [
                        _RuleRow(
                          icon: Icons.lock_clock_rounded,
                          text: '提交后金额先冻结，后台处理完成后再扣减',
                        ),
                        SizedBox(height: 12),
                        _RuleRow(
                          icon: Icons.receipt_long_outlined,
                          text: '每笔申请都会写入现金钱包流水',
                        ),
                        SizedBox(height: 12),
                        _RuleRow(
                          icon: Icons.verified_user_outlined,
                          text: '收款账户信息错误可能导致提现失败并退回',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          CreatorBottomAction(
            label: '下一步：填写提现账户',
            icon: Icons.arrow_forward_rounded,
            caption: amountFen > 0
                ? '本次提现 ¥${formatFen(amountFen)}'
                : '请输入提现金额',
            onPressed: canContinue
                ? () => context.push('/withdraw/channel?amountFen=$amountFen')
                : null,
          ),
        ],
      ),
    );
  }
}

class WithdrawChannelPage extends StatefulWidget {
  const WithdrawChannelPage({super.key, required this.amountFen});

  final int amountFen;

  @override
  State<WithdrawChannelPage> createState() => _WithdrawChannelPageState();
}

class _WithdrawChannelPageState extends State<WithdrawChannelPage> {
  final _accountName = TextEditingController();
  final _accountNo = TextEditingController();
  List<CreatorPaymentChannel> _channels = const [];
  String? _selectedCode;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  CreatorPaymentChannel? get _selectedChannel {
    for (final channel in _channels) {
      if (channel.code == _selectedCode) return channel;
    }
    return null;
  }

  bool get _amountValid =>
      _selectedChannel?.supportsAmount(widget.amountFen) ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreatorWalletProvider>().load();
      _loadChannels();
    });
  }

  @override
  void dispose() {
    _accountName.dispose();
    _accountNo.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final channels = await context
          .read<CreatorWalletProvider>()
          .fetchWithdrawChannels();
      if (!mounted) return;
      setState(() {
        _channels = channels;
        _selectedCode = channels.isEmpty ? null : channels.first.code;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '提现渠道加载失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final channel = _selectedChannel;
    final accountName = _accountName.text.trim();
    final accountNo = _accountNo.text.trim();
    if (channel == null) {
      _showMessage('请先选择提现渠道');
      return;
    }
    if (!_amountValid) {
      _showMessage(
        '${channel.name}支持 ¥${formatFen(channel.minFen)}～¥${formatFen(channel.maxFen)}',
      );
      return;
    }
    if (accountName.isEmpty) {
      _showMessage('请输入收款人姓名');
      return;
    }
    if (accountName.length > 100) {
      _showMessage('收款人姓名不能超过 100 个字符');
      return;
    }
    if (accountNo.isEmpty) {
      _showMessage('请输入收款账户');
      return;
    }
    if (accountNo.length > 100) {
      _showMessage('收款账户不能超过 100 个字符');
      return;
    }

    setState(() => _submitting = true);
    try {
      final withdrawal = await context
          .read<CreatorWalletProvider>()
          .createWithdrawal(
            amountFen: widget.amountFen,
            channelCode: channel.code,
            accountName: accountName,
            accountNo: accountNo,
          );
      if (!mounted) return;
      context.push('/withdraw/result?id=${withdrawal.id}', extra: withdrawal);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('提现申请提交失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<CreatorWalletProvider>();
    final available = wallet.stats?.withdrawableFen;
    return CreatorScreen(
      title: '填写提现账户',
      onBack: () => context.pop(),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                GlassPanel(
                  backgroundColor: AppColors.sage.withValues(alpha: 0.08),
                  borderColor: AppColors.sage.withValues(alpha: 0.2),
                  child: Column(
                    children: [
                      Text(
                        '提现金额',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '¥ ${formatFen(widget.amountFen)}',
                        style: const TextStyle(
                          color: AppColors.sage,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        available == null
                            ? '正在确认可提现余额'
                            : '提交后可提现余额预计剩余 ¥${formatFen((available - widget.amountFen).clamp(0, available))}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                CreatorSectionHeader(
                  title: '提现方式',
                  action: TextButton(
                    onPressed: _loading ? null : _loadChannels,
                    child: const Text('刷新'),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading && _channels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null && _channels.isEmpty)
                  EmptyPanel(
                    icon: Icons.cloud_off_outlined,
                    title: '提现渠道加载失败',
                    subtitle: _error!,
                    actionLabel: '重新加载',
                    onAction: _loadChannels,
                  )
                else if (_channels.isEmpty)
                  const EmptyPanel(
                    icon: Icons.account_balance_wallet_outlined,
                    title: '暂无可用提现渠道',
                    subtitle: '请稍后刷新，或联系运营确认渠道状态。',
                  )
                else
                  for (final channel in _channels) ...[
                    ChannelTile(
                      title: channel.name,
                      subtitle:
                          '限额 ¥${formatFen(channel.minFen)}～¥${formatFen(channel.maxFen)}'
                          '${channel.feeRateBps > 0 ? ' · 手续费 ${channel.feeRateBps / 100}%' : ' · 无手续费'}',
                      icon: walletChannelIcon(channel.code, channel.icon),
                      color: walletChannelColor(channel.code),
                      selected: _selectedCode == channel.code,
                      onTap: () {
                        setState(() => _selectedCode = channel.code);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                if (_channels.isNotEmpty && !_amountValid) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusFailed.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      '当前金额不在所选渠道限额内，请返回修改金额或更换渠道。',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.statusFailed),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const FormFieldLabel('收款人姓名', required: true),
                TextField(
                  controller: _accountName,
                  textInputAction: TextInputAction.next,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: '请输入与账户实名一致的真实姓名',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                const FormFieldLabel('收款账户', required: true),
                TextField(
                  controller: _accountNo,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: _selectedCode == 'BANK'
                        ? '请输入银行卡号'
                        : '请输入支付宝 / 微信账号',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '平台只展示脱敏后的收款账号，完整账号不会返回到 App。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          CreatorBottomAction(
            label: _submitting ? '正在提交申请…' : '确认提交提现',
            icon: Icons.verified_rounded,
            caption: '提交后进入待处理状态，金额会先冻结',
            onPressed: _submitting || !_amountValid ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class WithdrawResultPage extends StatefulWidget {
  const WithdrawResultPage({
    super.key,
    required this.withdrawalId,
    this.initialWithdrawal,
  });

  final int withdrawalId;
  final CreatorWithdrawal? initialWithdrawal;

  @override
  State<WithdrawResultPage> createState() => _WithdrawResultPageState();
}

class _WithdrawResultPageState extends State<WithdrawResultPage> {
  CreatorWithdrawal? _withdrawal;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _withdrawal = widget.initialWithdrawal;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final withdrawal = await context
          .read<CreatorWalletProvider>()
          .fetchWithdrawal(widget.withdrawalId);
      if (!mounted) return;
      setState(() => _withdrawal = withdrawal);
      await context.read<CreatorWalletProvider>().refreshBalanceIfChanged(
        withdrawal: withdrawal,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '提现状态刷新失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final withdrawal = _withdrawal;
    final unsettled =
        withdrawal == null ||
        withdrawal.status == CreatorWithdrawStatus.pending ||
        withdrawal.status == CreatorWithdrawStatus.processing;
    return CreatorScreen(
      title: '提现申请',
      onBack: () => context.go('/profile'),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                if (withdrawal == null && _refreshing)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (withdrawal == null)
                  EmptyPanel(
                    icon: Icons.error_outline_rounded,
                    title: '无法读取提现申请',
                    subtitle: _error ?? '申请可能不存在或网络不可用。',
                    actionLabel: '重新加载',
                    onAction: _refresh,
                  )
                else ...[
                  _WithdrawStatusHero(withdrawal: withdrawal),
                  const SizedBox(height: 18),
                  GlassPanel(
                    child: Column(
                      children: [
                        _DetailRow(
                          label: '提现金额',
                          value: '¥${formatFen(withdrawal.amountFen)}',
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: '提现渠道',
                          value: withdrawal.channelCode,
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(label: '收款人', value: withdrawal.accountName),
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: '收款账户',
                          value: withdrawal.accountNoMasked,
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(label: '申请编号', value: withdrawal.withdrawNo),
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: '申请时间',
                          value: formatWalletDate(
                            withdrawal.createdAt,
                            withTime: true,
                          ),
                        ),
                        if (withdrawal.processedAt != null) ...[
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: '处理时间',
                            value: formatWalletDate(
                              withdrawal.processedAt,
                              withTime: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (withdrawal.failureReason?.isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statusFailed.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Text(
                        withdrawal.failureReason!,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.statusFailed),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.statusFailed),
                    ),
                  ],
                ],
              ],
            ),
          ),
          CreatorBottomAction(
            label: unsettled ? (_refreshing ? '正在刷新…' : '刷新处理状态') : '返回我的钱包',
            icon: unsettled
                ? Icons.refresh_rounded
                : Icons.account_balance_wallet,
            caption: unsettled ? '待处理或处理中的资金会显示为冻结' : '最终状态已记录，可在现金流水中查看',
            onPressed: _refreshing
                ? null
                : unsettled
                ? _refresh
                : () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _WithdrawStatusHero extends StatelessWidget {
  const _WithdrawStatusHero({required this.withdrawal});

  final CreatorWithdrawal withdrawal;

  @override
  Widget build(BuildContext context) {
    final (icon, color, message) = switch (withdrawal.status) {
      CreatorWithdrawStatus.pending => (
        Icons.schedule_rounded,
        AppColors.gold,
        '申请已提交，金额已冻结。运营处理后会更新为“处理中”或最终结果。',
      ),
      CreatorWithdrawStatus.processing => (
        Icons.sync_rounded,
        const Color(0xFF7B8EC8),
        '平台正在处理打款，请耐心等待；资金仍保持冻结。',
      ),
      CreatorWithdrawStatus.success => (
        Icons.check_circle_rounded,
        AppColors.sage,
        '提现已完成，资金已从钱包扣除。',
      ),
      CreatorWithdrawStatus.failed => (
        Icons.error_rounded,
        AppColors.statusFailed,
        '提现失败，冻结金额已退回可提现余额。',
      ),
      CreatorWithdrawStatus.cancelled => (
        Icons.cancel_rounded,
        AppColors.taupe,
        '提现已取消，冻结金额已退回可提现余额。',
      ),
    };
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 52),
          const SizedBox(height: 12),
          Text(
            withdrawal.statusLabel,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: color),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.statusFailed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.statusFailed,
            size: 18,
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

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.sage),
        const SizedBox(width: 9),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
