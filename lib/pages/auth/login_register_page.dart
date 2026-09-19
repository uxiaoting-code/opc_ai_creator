import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';

/// 页面 1：登录 / 注册页
///
/// 需求清单里的第 12 项就已经是「设置页」，所以登录与注册合成一个页面，
/// 用 Tab 切换，正好凑满 13 个业务页面。
///
/// 说明：这个页面在第一步就做成可用的，因为路由守卫会把所有未登录的跳转
/// 都拦到这里 —— 它跑不起来的话，另外 12 个页面根本进不去。
class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // --- 登录表单 ---
  final _loginUsername = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _obscureLoginPwd = true;

  // --- 注册表单 ---
  final _regUsername = TextEditingController();
  final _regNickname = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm = TextEditingController();
  bool _obscureRegPwd = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 切换 Tab 时清掉上一侧的错误提示，避免串台
    _tab.addListener(() {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginUsername.dispose();
    _loginPassword.dispose();
    _regUsername.dispose();
    _regNickname.dispose();
    _regPassword.dispose();
    _regConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.mobileMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------- Logo 区 ----------
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'OPC AI 创作平台',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '文生图 · 图生视频 · 多线路 Skill 调度',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ---------- 脚手架模式提示 ----------
                  if (AppConfig.bypassLogin) const _BypassBanner(),

                  // ---------- 登录 / 注册 Tab ----------
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: theme.dividerTheme.color ?? Colors.transparent,
                      ),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd - 2),
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor:
                          theme.textTheme.bodySmall?.color,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: '登录', height: 46),
                        Tab(text: '注册', height: 46),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ---------- 表单区 ----------
                  SizedBox(
                    // 固定高度，避免切换 Tab 时页面跳动
                    height: 340,
                    child: TabBarView(
                      controller: _tab,
                      children: [
                        _buildLoginForm(context, auth),
                        _buildRegisterForm(context, auth),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 登录表单
  // ===========================================================================

  Widget _buildLoginForm(BuildContext context, AuthProvider auth) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginUsername,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '账号',
              hintText: '请输入用户名',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => _validateUsername(v),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _loginPassword,
            obscureText: _obscureLoginPwd,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitLogin(auth),
            decoration: InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                // 密码可见性切换：点击热区 48x48，符合手指操作
                icon: Icon(_obscureLoginPwd
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureLoginPwd = !_obscureLoginPwd),
              ),
            ),
            validator: (v) => _validatePassword(v),
          ),

          _buildError(context),

          const Spacer(),

          FilledButton(
            onPressed: auth.isLoading ? null : () => _submitLogin(auth),
            child: auth.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('登 录'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 注册表单
  // ===========================================================================

  Widget _buildRegisterForm(BuildContext context, AuthProvider auth) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _regUsername,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '账号',
              hintText: '4-20 位字母或数字',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => _validateUsername(v),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _regNickname,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '昵称（选填）',
              hintText: '展示在个人中心',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _regPassword,
            obscureText: _obscureRegPwd,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '密码',
              hintText: '至少 6 位',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureRegPwd
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureRegPwd = !_obscureRegPwd),
              ),
            ),
            validator: (v) => _validatePassword(v),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _regConfirm,
            obscureText: _obscureRegPwd,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitRegister(auth),
            decoration: const InputDecoration(
              labelText: '确认密码',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return '请再次输入密码';
              if (v != _regPassword.text) return '两次输入的密码不一致';
              return null;
            },
          ),

          _buildError(context),

          const SizedBox(height: AppSpacing.lg),

          FilledButton(
            onPressed: auth.isLoading ? null : () => _submitRegister(auth),
            child: auth.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('注册并登录'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 交互逻辑
  // ===========================================================================

  Widget _buildError(BuildContext context) {
    final message = _errorMessage ?? context.watch<AuthProvider>().errorMessage;
    if (message == null) return const SizedBox(height: AppSpacing.lg);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              size: 16, color: AppColors.statusFailed),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.statusFailed,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitLogin(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;

    final error = await auth.login(
      username: _loginUsername.text.trim(),
      password: _loginPassword.text,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }
    _goAfterAuth();
  }

  Future<void> _submitRegister(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;

    final error = await auth.register(
      username: _regUsername.text.trim(),
      password: _regPassword.text,
      nickname: _regNickname.text.trim().isEmpty
          ? null
          : _regNickname.text.trim(),
    );

    if (!mounted) return;
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }
    _goAfterAuth();
  }

  /// 登录成功后的跳转。
  ///
  /// 如果进登录页时带了 `redirect` 参数（被守卫拦下来的原地址），
  /// 登录后直接回到那里；否则回首页。
  void _goAfterAuth() {
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    final target = (redirect != null && redirect.isNotEmpty &&
            redirect != RouteNames.loginPath)
        ? redirect
        : RouteNames.homePath;
    context.go(target);
  }

  // ===========================================================================
  // 校验规则
  // ===========================================================================

  String? _validateUsername(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '请输入账号';
    if (v.length < 4 || v.length > 20) return '账号长度需为 4-20 位';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return '请输入密码';
    if (v.length < 6) return '密码至少 6 位';
    return null;
  }
}

/// 脚手架模式提示横幅：明确告诉使用者当前没有连后端。
class _BypassBanner extends StatelessWidget {
  const _BypassBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.construction_rounded,
              size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '脚手架模式：后端尚未接入，点击登录将建立本地模拟会话。'
              '联调前请把 AppConfig.bypassLogin 改为 false。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
