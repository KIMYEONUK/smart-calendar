import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_calendar/core/router/app_router.dart';
import 'package:smart_calendar/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 locale 초기화 (table_calendar 요구)
  await initializeDateFormatting('ko_KR', null);

  // .env 로드
  await dotenv.load(fileName: '.env');

  runApp(
    const ProviderScope(
      child: SmartCalendarApp(),
    ),
  );
}

class SmartCalendarApp extends ConsumerWidget {
  const SmartCalendarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SmartCalendar',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
