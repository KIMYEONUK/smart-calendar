import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_calendar/core/router/app_router.dart';
import 'package:smart_calendar/core/theme/app_theme.dart';
import 'package:smart_calendar/features/auth/presentation/providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _recoveryCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _selectedCalendar;
  String? _errorMessage;

  static const _calendarOptions = [
    '연동 안함',
    'Google Calendar',
    'Apple Calendar',
    'Naver Calendar',
    'Outlook',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _recoveryCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _errorMessage = null);

    await ref.read(authNotifierProvider.notifier).register(
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
          connectedCalendar: _selectedCalendar == '연동 안함'
              ? null
              : _selectedCalendar,
          recoveryMessage: _recoveryCtrl.text.trim().isEmpty
              ? null
              : _recoveryCtrl.text.trim(),
        );
  }

  String _parseError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 409) return '이미 사용 중인 아이디 또는 이메일입니다.';
      if (status == 422) return '입력 형식을 확인해주세요.';
      if (error.type == DioExceptionType.connectionError) {
        return '서버에 연결할 수 없습니다.';
      }
    }
    return '회원가입 중 오류가 발생했습니다.';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (prev, next) {
      if (next is AsyncError) {
        setState(() => _errorMessage = _parseError(next.error ?? ''));
      }
    });

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.landing),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────
                Text(
                  '계정을 만들어요',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '아래 정보를 입력해 일.내.조를 시작하세요.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // ── 이름 ──────────────────────────────────
                _SectionLabel(label: '이름 *'),
                const SizedBox(height: 8),
                _Field(
                  controller: _nameCtrl,
                  label: '이름',
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '이름을 입력해주세요.' : null,
                ),
                const SizedBox(height: 18),

                // ── 아이디 ────────────────────────────────
                _SectionLabel(label: '아이디 *'),
                const SizedBox(height: 8),
                _Field(
                  controller: _usernameCtrl,
                  label: '아이디 (영문/숫자)',
                  icon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return '아이디를 입력해주세요.';
                    if (v.length < 3) return '아이디는 3자 이상이어야 합니다.';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                      return '영문, 숫자, 밑줄(_)만 사용 가능합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── 전화번호 ──────────────────────────────
                _SectionLabel(label: '전화번호'),
                const SizedBox(height: 8),
                _Field(
                  controller: _phoneCtrl,
                  label: '전화번호 (선택)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 18),

                // ── 이메일 ────────────────────────────────
                _SectionLabel(label: '이메일 *'),
                const SizedBox(height: 8),
                _Field(
                  controller: _emailCtrl,
                  label: '이메일',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return '이메일을 입력해주세요.';
                    if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── 연동 캘린더 ──────────────────────────
                _SectionLabel(label: '연동할 캘린더'),
                const SizedBox(height: 8),
                _CalendarDropdown(
                  value: _selectedCalendar,
                  options: _calendarOptions,
                  onChanged: (v) => setState(() => _selectedCalendar = v),
                ),
                const SizedBox(height: 18),

                // ── 비밀번호 ──────────────────────────────
                _SectionLabel(label: '비밀번호 *'),
                const SizedBox(height: 8),
                _Field(
                  controller: _passwordCtrl,
                  label: '비밀번호 (8자 이상, 특수문자 포함)',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호를 입력해주세요.';
                    if (v.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) {
                      return '특수문자(!@#\$%^&* 등)를 1개 이상 포함해야 합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _confirmPasswordCtrl,
                  label: '비밀번호 확인',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호를 다시 입력해주세요.';
                    if (v != _passwordCtrl.text) return '비밀번호가 일치하지 않습니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── 복구 메시지 ──────────────────────────
                _SectionLabel(label: '복구 메시지'),
                const SizedBox(height: 8),
                _Field(
                  controller: _recoveryCtrl,
                  label: '복구 메시지 (선택) — 비밀번호 찾기에 사용',
                  icon: Icons.vpn_key_outlined,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                ),
                const SizedBox(height: 28),

                // ── 에러 ──────────────────────────────────
                if (_errorMessage != null) ...[
                  _ErrorBox(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],

                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE8E5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton(
                    onPressed: isLoading ? null : _register,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.black54),
                          )
                        : const Text('계정 만들기',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: const Text(
                    '이미 계정이 있으신가요?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black38,
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

// ── Form Field ────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.textInputAction,
    this.keyboardType,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
        prefixIcon: Icon(icon, size: 20, color: Colors.black38),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFEAE8E5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black26, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF4757), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF4757), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ── Calendar Dropdown ─────────────────────────────────────────
class _CalendarDropdown extends StatelessWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _CalendarDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = value == option;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black87 : const Color(0xFFEAE8E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Error Box ─────────────────────────────────────────────────
class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4757).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFF4757).withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded,
                color: Color(0xFFFF4757), size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFFFF4757),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
