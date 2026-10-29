import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../creator_flow_provider.dart';
import '../widgets/creator_widgets.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
    final available = flow.withdrawable;
    return CreatorScreen(
      title: '提现',
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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6E8B70),
                        Color(0xFF9FAF8D),
                        Color(0xFFC8AD79),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
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
                        '¥ ${available.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '仅审核通过的作品收入可提现',
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
                  title: '提现金额',
                  subtitle: '最低提现金额 10 元，单笔最高 5000 元',
                ),
                const SizedBox(height: 12),
                GlassPanel(
                  child: Column(
                    children: [
                      TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '¥ ',
                          hintText: '0.00',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Text(
                            '当前可提现 ¥${available.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              _amount.text = available.toStringAsFixed(2);
                              setState(() {});
                            },
                            child: const Text('全部提现'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GlassPanel(
                  child: Column(
                    children: [
                      _RuleRow(
                        icon: Icons.schedule_rounded,
                        text: '预计 1～2 个工作日到账',
                      ),
                      const SizedBox(height: 12),
                      _RuleRow(
                        icon: Icons.receipt_long_outlined,
                        text: '平台将记录每笔提现流水',
                      ),
                      const SizedBox(height: 12),
                      _RuleRow(
                        icon: Icons.verified_user_outlined,
                        text: '收款账户需与实名认证信息一致',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CreatorBottomAction(
            label: '下一步：选择提现渠道',
            icon: Icons.arrow_forward_rounded,
            caption: _value > 0
                ? '本次提现 ¥${_value.toStringAsFixed(2)}'
                : '请输入提现金额',
            onPressed: _value >= 10 && _value <= available
                ? () => context.push(
                    '/withdraw/channel?amount=${_value.toStringAsFixed(2)}',
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class WithdrawChannelPage extends StatefulWidget {
  const WithdrawChannelPage({super.key, required this.amount});

  final double amount;

  @override
  State<WithdrawChannelPage> createState() => _WithdrawChannelPageState();
}

class _WithdrawChannelPageState extends State<WithdrawChannelPage> {
  int _selected = 0;
  final _account = TextEditingController(text: 'creator@example.com');
  bool _submitting = false;

  final _channels = const [
    ('支付宝', '预计 2 小时内到账', Icons.account_balance_wallet_rounded, AppColors.sage),
    ('微信零钱', '预计 2 小时内到账', Icons.chat_bubble_rounded, Color(0xFF2AAE67)),
    ('银行卡', '预计 1～2 个工作日到账', Icons.credit_card_rounded, Color(0xFFC04A5A)),
  ];

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_account.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入收款账户')));
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final ok = context.read<CreatorFlowProvider>().withdraw(
      amount: widget.amount,
      channel: _channels[_selected].$1,
    );
    setState(() => _submitting = false);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('可提现余额不足')));
      return;
    }
    await showCreatorSuccessDialog(
      context,
      title: '提现申请已提交',
      message:
          '¥${widget.amount.toStringAsFixed(2)} 将转入 ${_channels[_selected].$1}，可在流水中查看状态。',
    );
    if (mounted) context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    return CreatorScreen(
      title: '选择提现渠道',
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
                        '¥ ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.sage,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '到账时间以渠道说明为准',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const CreatorSectionHeader(title: '提现方式'),
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
                const SizedBox(height: 12),
                const FormFieldLabel('收款账户', required: true),
                TextField(
                  controller: _account,
                  decoration: InputDecoration(
                    hintText: _selected == 2 ? '请输入银行卡号' : '请输入支付宝 / 微信账号',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '提交后平台会进行打款审核，恶意提现或账户信息错误可能导致提现失败。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          CreatorBottomAction(
            label: _submitting
                ? '提交中…'
                : '确认提现 ¥${widget.amount.toStringAsFixed(2)}',
            icon: Icons.verified_rounded,
            caption: '演示模式仅更新本地钱包状态',
            onPressed: _submitting ? null : _confirm,
          ),
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
