import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_calendar/core/router/app_router.dart';
import 'package:smart_calendar/core/theme/app_theme.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // ── 로고 & 타이틀 ──────────────────────────
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'SmartCalendar',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'OCR로 일정을 자동 등록하고\n스마트하게 관리하세요',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // ── Feature highlights ─────────────────────
              _FeatureTile(
                icon: Icons.document_scanner_rounded,
                color: AppColors.primary,
                title: 'OCR 자동 일정 등록',
                subtitle: '사진을 찍으면 일정이 자동으로 추가돼요',
              ),
              const SizedBox(height: 14),
              _FeatureTile(
                icon: Icons.add_circle_rounded,
                color: AppColors.accentOrange,
                title: '여러 일정 한 번에 등록',
                subtitle: '한 번의 입력으로 여러 일정을 동시 등록',
              ),
              const SizedBox(height: 14),
              _FeatureTile(
                icon: Icons.checklist_rounded,
                color: AppColors.accentGreen,
                title: 'To-Do 리스트',
                subtitle: '진행 중인 프로젝트를 한눈에 파악',
              ),

              const Spacer(flex: 2),

              // ── Buttons ────────────────────────────────
              FilledButton(
                onPressed: () => context.push(AppRoutes.login),
                child: const Text('로그인'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.register),
                child: const Text('계정 만들기'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
