import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_calendar/core/router/app_router.dart';
import 'package:smart_calendar/features/auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notifyEvent = true;
  bool _notifyTodo = true;
  bool _notifyReminder = true;
  String _startDay = '일요일';
  String _theme = '시스템';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── 알림 섹션 ──
          _SectionHeader(label: '알림'),
          _SwitchTile(
            icon: Icons.event_outlined,
            label: '일정 알림',
            value: _notifyEvent,
            onChanged: (v) => setState(() => _notifyEvent = v),
          ),
          _SwitchTile(
            icon: Icons.checklist_outlined,
            label: 'To-Do 알림',
            value: _notifyTodo,
            onChanged: (v) => setState(() => _notifyTodo = v),
          ),
          _SwitchTile(
            icon: Icons.notifications_outlined,
            label: '리마인더 알림',
            value: _notifyReminder,
            onChanged: (v) => setState(() => _notifyReminder = v),
          ),
          const Divider(height: 32),

          // ── 캘린더 섹션 ──
          _SectionHeader(label: '캘린더'),
          _SelectTile(
            icon: Icons.calendar_today_outlined,
            label: '한 주의 시작',
            value: _startDay,
            options: const ['일요일', '월요일'],
            onChanged: (v) => setState(() => _startDay = v),
          ),
          const Divider(height: 32),

          // ── 화면 섹션 ──
          _SectionHeader(label: '화면'),
          _SelectTile(
            icon: Icons.brightness_6_outlined,
            label: '화면 테마',
            value: _theme,
            options: const ['시스템', '라이트', '다크'],
            onChanged: (v) => setState(() => _theme = v),
          ),
          const Divider(height: 32),

          // ── 로그아웃 ──
          const SizedBox(height: 8),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text(
              '로그아웃',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠어요?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('로그아웃',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.landing);
              }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ── Switch Tile ─────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      secondary: Icon(icon, color: cs.onSurfaceVariant, size: 22),
      title: Text(label,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeColor: cs.primary,
    );
  }
}

// ── Select Tile ─────────────────────────────────────────────
class _SelectTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _SelectTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: cs.onSurfaceVariant, size: 22),
      title: Text(label,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant, size: 20),
        ],
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) => ListTile(
                      title: Text(opt),
                      trailing: opt == value
                          ? Icon(Icons.check_rounded, color: cs.primary)
                          : null,
                      onTap: () {
                        onChanged(opt);
                        Navigator.pop(ctx);
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
