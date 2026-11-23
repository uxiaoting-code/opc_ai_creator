import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../creator_wallet_provider.dart';
import '../models/creator_wallet.dart';
import '../widgets/creator_widgets.dart';
import '../widgets/wallet_widgets.dart';

class WalletTransactionsPage extends StatefulWidget {
  const WalletTransactionsPage({super.key});

  @override
  State<WalletTransactionsPage> createState() => _WalletTransactionsPageState();
}

class _WalletTransactionsPageState extends State<WalletTransactionsPage> {
  static const _pageSize = 20;

  final List<CreatorWalletTransaction> _items = [];
  int _page = 0;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      if (_loading && _items.isEmpty) {
        // 首次加载已经处于 loading 状态。
      } else {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    final nextPage = reset ? 1 : _page + 1;
    try {
      final result = await context
          .read<CreatorWalletProvider>()
          .fetchTransactions(page: nextPage, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.list);
        _page = result.page;
        _total = result.total;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '流水加载失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreatorScreen(
      title: '钱包流水',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      },
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        color: AppColors.sage,
        child: _buildList(),
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          EmptyPanel(
            icon: Icons.receipt_long_outlined,
            title: '流水加载失败',
            subtitle: _error!,
            actionLabel: '重新加载',
            onAction: () => _load(reset: true),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 48),
          EmptyPanel(
            icon: Icons.receipt_long_outlined,
            title: '暂无现金流水',
            subtitle: '作品审核通过、提现申请提交或处理后会在这里记录。',
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length + 1 + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '共 $_total 笔现金变动，按时间倒序排列',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        final itemIndex = index - 1;
        if (itemIndex < _items.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassPanel(
              padding: const EdgeInsets.all(14),
              child: WalletTransactionRow(
                transaction: _items[itemIndex],
                showBalance: true,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _error != null
              ? Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => _load(reset: false),
                      child: const Text('重试加载更多'),
                    ),
                  ],
                )
              : OutlinedButton(
                  onPressed: _loadingMore ? null : () => _load(reset: false),
                  child: _loadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('加载更多'),
                ),
        );
      },
    );
  }
}
