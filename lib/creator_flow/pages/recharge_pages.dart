import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../creator_flow_provider.dart';
import '../widgets/creator_widgets.dart';

class RechargePage extends StatefulWidget {
  const RechargePage({super.key});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  final _custom = TextEditingController();
  int _selected = 2;
  final _amounts = const [50.0, 100.0, 200.0, 500.0, 1000.0];

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  double get _amount {
    final custom = double.tryParse(_custom.text.trim());
    if (custom != null && custom > 0) return custom;
    return _amounts[_selected];
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
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
                        '${flow.credits.toStringAsFixed(0)} 点',
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
                  subtitle: '充值成功后算力立即到账',
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _amounts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemBuilder: (context, index) {
                    final amount = _amounts[index];
                    final selected =
                        _custom.text.trim().isEmpty && _selected == index;
                    return GlassPanel(
                      onTap: () {
                        _custom.clear();
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
                            '¥${amount.toStringAsFixed(0)}',
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
                            '${(amount * 100).toStringAsFixed(0)} 算力',
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
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixText: '¥ ',
                    hintText: '请输入充值金额',
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
                              '安全支付',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '支付渠道、订单号和交易结果会在渠道页确认。',
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
            caption:
                '本次充值 ¥${_amount.toStringAsFixed(2)}，到账 ${(_amount * 100).toStringAsFixed(0)} 算力',
            onPressed: _amount > 0
                ? () => context.push(
                    '/recharge/channel?amount=${_amount.toStringAsFixed(2)}',
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class RechargeChannelPage extends StatefulWidget {
  const RechargeChannelPage({super.key, required this.amount});

  final double amount;

  @override
  State<RechargeChannelPage> createState() => _RechargeChannelPageState();
}

class _RechargeChannelPageState extends State<RechargeChannelPage> {
  int _selected = 0;
  bool _agree = true;
  bool _paying = false;

  final _channels = const [
    ('支付宝', '推荐使用，实时到账', Icons.account_balance_wallet_rounded, AppColors.sage),
    ('微信支付', '微信安全支付', Icons.chat_bubble_rounded, Color(0xFF2AAE67)),
    ('银联云闪付', '支持储蓄卡与信用卡', Icons.credit_card_rounded, Color(0xFFC04A5A)),
  ];

  Future<void> _confirm() async {
    if (!_agree) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先同意充值服务协议')));
      return;
    }
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    context.read<CreatorFlowProvider>().recharge(
      amount: widget.amount,
      channel: _channels[_selected].$1,
    );
    setState(() => _paying = false);
    if (!mounted) return;
    await showCreatorSuccessDialog(
      context,
      title: '充值成功',
      message: '已到账 ${(widget.amount * 100).toStringAsFixed(0)} 算力，可立即用于作品生成。',
    );
    if (mounted) context.go('/profile');
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
                        '应付金额',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '¥ ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '到账 ${(widget.amount * 100).toStringAsFixed(0)} 算力点',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const CreatorSectionHeader(title: '支付方式'),
                const SizedBox(height: 12),
                for (var i = 0; i < _channels.length; i++) ...[
                  ChannelTile(
                    title: _channels[i].$1,
                    subtitle: _channels[i].$2,
                    icon: _channels[i].$3,
                    color: _channels[i].$4,
                    selected: _selected == i,
                    onTap: () => setState(() => _selected = i),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _agree,
                  onChanged: (value) => setState(() => _agree = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '我已阅读并同意《充值服务协议》',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          CreatorBottomAction(
            label: _paying
                ? '支付确认中…'
                : '确认支付 ¥${widget.amount.toStringAsFixed(2)}',
            icon: Icons.lock_rounded,
            caption: '演示模式不会发起真实扣款',
            onPressed: _paying ? null : _confirm,
          ),
        ],
      ),
    );
  }
}
