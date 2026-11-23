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

class RechargePage extends StatefulWidget {
  const RechargePage({super.key});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  final _custom = TextEditingController();
  int _selected = 1;
  static const _presetYuan = [50, 100, 200, 500, 1000];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CreatorWalletProvider>().load();
    });
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  int? get _customFen => parseYuanToFen(_custom.text);

  int get _amountFen {
    final custom = _customFen;
    return custom ?? _presetYuan[_selected] * 100;
  }

  bool get _customInvalid =>
      _custom.text.trim().isNotEmpty && _customFen == null;

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<CreatorWalletProvider>();
    final credits = wallet.stats?.credits;
    return CreatorScreen(
      title: '充值算力',
      onBack: () => context.pop(),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.24),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '当前算力余额',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        credits == null ? '— 点' : '$credits 点',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '充值比例：1 元 = 100 算力点',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const CreatorSectionHeader(
                  title: '选择充值金额',
                  subtitle: '创建订单后，支付成功才会增加算力',
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _presetYuan.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemBuilder: (context, index) {
                    final amount = _presetYuan[index];
                    final selected =
                        _custom.text.trim().isEmpty && _selected == index;
                    return GlassPanel(
                      onTap: () {
                        _custom.clear();
                        FocusScope.of(context).unfocus();
                        setState(() => _selected = index);
                      },
                      backgroundColor: selected
                          ? AppColors.gold.withValues(alpha: 0.1)
                          : null,
                      borderColor: selected
                          ? AppColors.gold.withValues(alpha: 0.48)
                          : null,
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¥$amount',
                            style: TextStyle(
                              color: selected
                                  ? AppColors.gold
                                  : AppColors.charcoal,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${amount * 100} 算力',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                const FormFieldLabel('自定义金额'),
                TextField(
                  controller: _custom,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixText: '¥ ',
                    hintText: '请输入金额，最多两位小数',
                    errorText: _customInvalid ? '请输入有效金额，最多两位小数' : null,
                  ),
                ),
                const SizedBox(height: 18),
                GlassPanel(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: AppColors.sage,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '支付结果以后端为准',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'App 只创建充值订单，支付渠道确认成功后算力才会到账。',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CreatorBottomAction(
            label: '下一步：选择充值渠道',
            icon: Icons.arrow_forward_rounded,
            caption: '本次充值 ¥${formatFen(_amountFen)}，到账 $_amountFen 算力',
            onPressed: _amountFen > 0 && !_customInvalid
                ? () => context.push('/recharge/channel?amountFen=$_amountFen')
                : null,
          ),
        ],
      ),
    );
  }
}

class RechargeChannelPage extends StatefulWidget {
  const RechargeChannelPage({super.key, required this.amountFen});

  final int amountFen;

  @override
  State<RechargeChannelPage> createState() => _RechargeChannelPageState();
}

class _RechargeChannelPageState extends State<RechargeChannelPage> {
  List<CreatorPaymentChannel> _channels = const [];
  String? _selectedCode;
  bool _loading = true;
  bool _creating = false;
  bool _agree = true;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChannels());
  }

  Future<void> _loadChannels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final channels = await context
          .read<CreatorWalletProvider>()
          .fetchRechargeChannels();
      if (!mounted) return;
      setState(() {
        _channels = channels;
        _selectedCode = channels.isEmpty ? null : channels.first.code;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '充值渠道加载失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createOrder() async {
    if (_creating) return;
    final channel = _selectedChannel;
    if (channel == null) {
      _showMessage('请先选择支付渠道');
      return;
    }
    if (!_amountValid) {
      _showMessage(
        '${channel.name}支持 ¥${formatFen(channel.minFen)}～¥${formatFen(channel.maxFen)}',
      );
      return;
    }
    if (!_agree) {
      _showMessage('请先同意充值服务协议');
      return;
    }

    setState(() => _creating = true);
    try {
      final order = await context.read<CreatorWalletProvider>().createRecharge(
        amountFen: widget.amountFen,
        channelCode: channel.code,
      );
      if (!mounted) return;
      context.push('/recharge/result?orderId=${order.id}', extra: order);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('充值订单创建失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _creating = false);
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
    return CreatorScreen(
      title: '选择充值渠道',
      onBack: () => context.pop(),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                GlassPanel(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.08),
                  borderColor: AppColors.gold.withValues(alpha: 0.2),
                  child: Column(
                    children: [
                      Text(
                        '充值金额',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '¥ ${formatFen(widget.amountFen)}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '到账 ${widget.amountFen} 算力点',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                CreatorSectionHeader(
                  title: '支付方式',
                  action: TextButton(
                    onPressed: _loading ? null : _loadChannels,
                    child: const Text('刷新'),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading && _channels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null && _channels.isEmpty)
                  EmptyPanel(
                    icon: Icons.cloud_off_outlined,
                    title: '充值渠道加载失败',
                    subtitle: _error!,
                    actionLabel: '重新加载',
                    onAction: _loadChannels,
                  )
                else if (_channels.isEmpty)
                  const EmptyPanel(
                    icon: Icons.account_balance_wallet_outlined,
                    title: '暂无可用充值渠道',
                    subtitle: '请稍后刷新，或联系运营确认支付渠道状态。',
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
                if (_channels.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  if (!_amountValid)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statusFailed.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Text(
                        '当前金额不在所选渠道限额内，请返回修改金额或更换渠道。',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.statusFailed),
                      ),
                    ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    value: _agree,
                    onChanged: (value) =>
                        setState(() => _agree = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '我已阅读并同意《充值服务协议》',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
          CreatorBottomAction(
            label: _creating ? '正在创建订单…' : '创建充值订单',
            icon: Icons.receipt_long_rounded,
            caption: '创建后为“待支付”，到账以支付渠道回调为准',
            onPressed: _creating || !_amountValid || !_agree
                ? null
                : _createOrder,
          ),
        ],
      ),
    );
  }
}

class RechargeResultPage extends StatefulWidget {
  const RechargeResultPage({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  final int orderId;
  final CreatorRechargeOrder? initialOrder;

  @override
  State<RechargeResultPage> createState() => _RechargeResultPageState();
}

class _RechargeResultPageState extends State<RechargeResultPage> {
  CreatorRechargeOrder? _order;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final order = await context.read<CreatorWalletProvider>().fetchRecharge(
        widget.orderId,
      );
      if (!mounted) return;
      setState(() => _order = order);
      await context.read<CreatorWalletProvider>().refreshBalanceIfChanged(
        recharge: order,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '充值状态刷新失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final pending =
        order == null || order.status == CreatorRechargeStatus.pending;
    return CreatorScreen(
      title: '充值结果',
      onBack: () => context.go('/profile'),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                if (order == null && _refreshing)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (order == null)
                  EmptyPanel(
                    icon: Icons.error_outline_rounded,
                    title: '无法读取充值订单',
                    subtitle: _error ?? '订单可能不存在或网络不可用。',
                    actionLabel: '重新加载',
                    onAction: _refresh,
                  )
                else ...[
                  _RechargeStatusHero(order: order),
                  const SizedBox(height: 18),
                  GlassPanel(
                    child: Column(
                      children: [
                        _DetailRow(
                          label: '充值金额',
                          value: '¥${formatFen(order.amountFen)}',
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(label: '到账算力', value: '${order.credits} 点'),
                        const SizedBox(height: 12),
                        _DetailRow(label: '支付渠道', value: order.channelCode),
                        const SizedBox(height: 12),
                        _DetailRow(label: '订单号', value: order.rechargeNo),
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: '创建时间',
                          value: formatWalletDate(
                            order.createdAt,
                            withTime: true,
                          ),
                        ),
                        if (order.paidAt != null) ...[
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: '支付时间',
                            value: formatWalletDate(
                              order.paidAt,
                              withTime: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
            label: pending ? (_refreshing ? '正在刷新…' : '刷新支付状态') : '返回我的钱包',
            icon: pending
                ? Icons.refresh_rounded
                : Icons.account_balance_wallet,
            caption: pending ? '支付完成并收到渠道确认后，算力会自动到账' : '状态已更新，可返回钱包查看余额和流水',
            onPressed: _refreshing
                ? null
                : pending
                ? _refresh
                : () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _RechargeStatusHero extends StatelessWidget {
  const _RechargeStatusHero({required this.order});

  final CreatorRechargeOrder order;

  @override
  Widget build(BuildContext context) {
    final (icon, color, message) = switch (order.status) {
      CreatorRechargeStatus.pending => (
        Icons.schedule_rounded,
        AppColors.gold,
        '订单已创建，等待支付渠道确认。请勿重复创建同一笔充值。',
      ),
      CreatorRechargeStatus.paid => (
        Icons.check_circle_rounded,
        AppColors.sage,
        '支付成功，${order.credits} 算力已到账。',
      ),
      CreatorRechargeStatus.failed => (
        Icons.error_rounded,
        AppColors.statusFailed,
        '支付失败，本次充值不会增加算力。',
      ),
      CreatorRechargeStatus.closed => (
        Icons.cancel_rounded,
        AppColors.statusFailed,
        '订单已关闭，请返回后重新选择渠道。',
      ),
      CreatorRechargeStatus.refunded => (
        Icons.replay_rounded,
        AppColors.taupe,
        '该充值订单已退款，算力余额以后端记录为准。',
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
            order.statusLabel,
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
