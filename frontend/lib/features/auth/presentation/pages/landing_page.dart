import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_calendar/core/router/app_router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),

              Text(
                '일.내.조',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE8E5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.login),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.push(AppRoutes.register),
                child: Text(
                  '아직 계정이 없으십니까?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black38,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
