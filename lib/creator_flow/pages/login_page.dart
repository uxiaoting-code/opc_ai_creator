import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';

class CreatorLoginPage extends StatefulWidget {
  const CreatorLoginPage({super.key});

  @override
  State<CreatorLoginPage> createState() => _CreatorLoginPageState();
}

class _CreatorLoginPageState extends State<CreatorLoginPage> {
  final _username = TextEditingController(text: 'demo');
  final _password = TextEditingController(text: 'demo123');
  final _nickname = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _register = false;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final error = _register
        ? await auth.register(
            username: _username.text.trim(),
            password: _password.text,
            nickname: _nickname.text.trim().isEmpty
                ? null
                : _nickname.text.trim(),
          )
        : await auth.login(
            username: _username.text.trim(),
            password: _password.text,
          );
    if (!mounted) return;
    if (error == null) {
      context.go('/market');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _fillDemo() {
    setState(() {
      _register = false;
      _username.text = 'demo';
      _password.text = 'demo123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppColors.shadowButton,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MUSE AI',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(letterSpacing: 1.2),
                        ),
                        Text(
                          '电商创作接单工作台',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  _register ? '创建创作者账号' : '欢迎回来',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _register ? '注册后即可接单、创作并提交作品' : '登录后继续你的创作订单和审核进度',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.sageTint,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Row(
                    children: [
                      _AuthTab(
                        label: '登录',
                        active: !_register,
                        onTap: () => setState(() => _register = false),
                      ),
                      _AuthTab(
                        label: '注册',
                        active: _register,
                        onTap: () => setState(() => _register = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_register) ...[
                  TextFormField(
                    controller: _nickname,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '昵称',
                      hintText: '例如：小满设计师',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? '请输入账号' : null,
                  decoration: const InputDecoration(
                    labelText: '账号',
                    hintText: '请输入登录账号',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) =>
                      (value == null || value.length < 6) ? '密码至少 6 位' : null,
                  decoration: InputDecoration(
                    labelText: '密码',
                    hintText: '至少 6 位',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    auth.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.statusFailed,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: AppSpacing.buttonHeight,
                  child: FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_register ? '注册并进入' : '登录'),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _fillDemo,
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text('使用演示账号'),
                ),
                const SizedBox(height: 24),
                Text(
                  auth.isBypassMode
                      ? '当前为脚手架演示模式：登录/注册不会请求后端，提交后即可体验完整流程。'
                      : '登录和注册将连接 Spring Boot 后端。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  const _AuthTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: active ? AppColors.shadowSoft : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.charcoal : AppColors.taupe,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
