import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_calendar/core/theme/app_theme.dart';
import 'package:smart_calendar/features/auth/presentation/pages/find_account_page.dart';
import 'package:smart_calendar/features/auth/presentation/pages/landing_page.dart';
import 'package:smart_calendar/features/auth/presentation/pages/login_page.dart';
import 'package:smart_calendar/features/auth/presentation/pages/register_page.dart';
import 'package:smart_calendar/features/auth/domain/entities/user_entity.dart';
import 'package:smart_calendar/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_calendar/features/calendar/presentation/pages/calendar_page.dart';
import 'package:smart_calendar/features/event/presentation/pages/create_event_page.dart';
import 'package:smart_calendar/features/event/presentation/pages/ocr_scan_page.dart';
import 'package:smart_calendar/features/todo/presentation/pages/todo_page.dart';
import 'package:smart_calendar/features/event/presentation/pages/event_detail_page.dart';

class AppRoutes {
  AppRoutes._();

  static const landing = '/auth/landing';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const findAccount = '/auth/find-account';
  static const home = '/calendar';
  static const createEvent = '/calendar/create';
  static const ocrScan = '/calendar/ocr';
  static const todo = '/todo';

  static String eventDetail(String id) => '/calendar/events/$id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthStateListenable(ref);
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = listenable.authState;
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final path = state.uri.path;
      final isOnAuthPath = path.startsWith('/auth');

      if (!isLoggedIn && !isOnAuthPath) return AppRoutes.landing;
      if (isLoggedIn && isOnAuthPath) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.findAccount,
        builder: (context, state) => const FindAccountPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CalendarPage()),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final extra = state.extra as Map<String, DateTime?>?;
                  return CreateEventPage(
                    initialStartAt: extra?['startAt'],
                    initialEndAt: extra?['endAt'],
                  );
                },
              ),
              GoRoute(
                path: 'ocr',
                builder: (context, state) => const OcrScanPage(),
              ),
              GoRoute(
                path: 'events/:id',
                builder: (context, state) => EventDetailPage(
                  eventId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.todo,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TodoPage()),
          ),
        ],
      ),
    ],
  );
});

// ── Auth State Listenable ─────────────────────────────────────
class _AuthStateListenable extends ChangeNotifier {
  AsyncValue<UserEntity?> authState = const AsyncLoading();

  _AuthStateListenable(Ref ref) {
    ref.listen(authNotifierProvider, (prev, next) {
      authState = next;
      notifyListeners();
    });
  }
}

// ── Main Shell (BottomNavigationBar) ─────────────────────────
class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month_rounded),
      label: '캘린더',
    ),
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist_rounded),
      label: 'To-Do',
    ),
  ];

  static const _routes = [
    AppRoutes.home,
    AppRoutes.todo,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int index = 0;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) index = i;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: _destinations,
        onDestinationSelected: (i) => context.go(_routes[i]),
      ),
    );
  }
}
