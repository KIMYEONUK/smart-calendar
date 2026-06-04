import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_calendar/core/network/api_endpoints.dart';
import 'package:smart_calendar/core/network/dio_client.dart';
import 'package:smart_calendar/features/auth/data/models/auth_token_model.dart';
import 'package:smart_calendar/features/auth/data/models/user_model.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(
    dio: ref.read(dioClientProvider),
    storage: ref.read(secureStorageProvider),
  );
});

class AuthRemoteDatasource {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  const AuthRemoteDatasource({
    required Dio dio,
    required FlutterSecureStorage storage,
  }) : _dio = dio,
       _storage = storage;

  Future<UserModel> loginWithUsername({
    required String username,
    required String password,
  }) async {
    // OAuth2 form login
    final response = await _dio.post(
      ApiEndpoints.login,
      data: FormData.fromMap({
        'username': username,
        'password': password,
        'grant_type': 'password',
      }),
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );

    final token = AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
    await _saveTokens(token);

    return _fetchMe();
  }

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String? connectedCalendar,
    String? recoveryMessage,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
        'name': name,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (connectedCalendar != null) 'connected_calendar': connectedCalendar,
        if (recoveryMessage != null) 'recovery_message': recoveryMessage,
      },
    );

    final token = AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
    await _saveTokens(token);

    return _fetchMe();
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } finally {
      await _storage.deleteAll();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;
    try {
      return await _fetchMe();
    } catch (_) {
      return null;
    }
  }

  Future<bool> findPassword(String email) async {
    await _dio.post(ApiEndpoints.findPassword, data: {'email': email});
    return true;
  }

  Future<UserModel> _fetchMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> _saveTokens(AuthTokenModel token) async {
    await _storage.write(key: 'access_token', value: token.accessToken);
    await _storage.write(key: 'refresh_token', value: token.refreshToken);
  }
}
