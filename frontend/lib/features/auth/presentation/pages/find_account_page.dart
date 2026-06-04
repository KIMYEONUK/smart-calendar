import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calendar/features/auth/presentation/providers/auth_provider.dart';

class FindAccountPage extends ConsumerStatefulWidget {
  const FindAccountPage({super.key});

  @override
  ConsumerState<FindAccountPage> createState() => _FindAccountPageState();
}

class _FindAccountPageState extends ConsumerState<FindAccountPage> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일을 입력해주세요.')),
      );
      return;
    }
    setState(() => _loading = true);
    final ok =
        await ref.read(authNotifierProvider.notifier).findPassword(email);
    setState(() {
      _loading = false;
      _sent = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        title: const Text('비밀번호 찾기'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? _SentState(email: _emailCtrl.text.trim())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '가입한 이메일을\n입력해주세요',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '이메일로 비밀번호 재설정 링크를 보내드립니다.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        labelText: '이메일',
                        prefixIcon: Icon(Icons.email_outlined,
                            size: 20, color: cs.onSurfaceVariant),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _loading ? null : _send,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('이메일 전송'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SentState extends StatelessWidget {
  final String email;
  const _SentState({required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_rounded,
            size: 72, color: Color(0xFF4A6CF7)),
        const SizedBox(height: 24),
        Text(
          '이메일을 확인해주세요',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '$email\n으로 비밀번호 재설정 링크를 보내드렸습니다.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('로그인으로 돌아가기'),
        ),
      ],
    );
  }
}
