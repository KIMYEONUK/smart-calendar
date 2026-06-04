import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl =>
      dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:8000/api';

  // ─── Auth ────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';
  static const String findPassword = '/auth/find-password';

  // ─── Events ──────────────────────────────────────────────
  static const String events = '/events';
  static String eventDetail(String id) => '/events/$id';
  static const String eventsUpcoming = '/events/upcoming';

  // ─── Todo ────────────────────────────────────────────────
  static const String todos = '/todos';
  static String todoDetail(String id) => '/todos/$id';
  static String todoToggle(String id) => '/todos/$id/toggle';

  // ─── OCR ─────────────────────────────────────────────────
  static const String ocrExtract = '/ocr/extract';
}
