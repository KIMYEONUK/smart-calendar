import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calendar/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smart_calendar/features/auth/domain/entities/user_entity.dart';
import 'package:smart_calendar/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDatasourceProvider));
});

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;

  const AuthRepositoryImpl(this._remote);

  @override
  Future<UserEntity?> getCurrentUser() async {
    final model = await _remote.getCurrentUser();
    return model?.toEntity();
  }

  @override
  Future<UserEntity> loginWithUsername({
    required String username,
    required String password,
  }) async {
    final model = await _remote.loginWithUsername(
      username: username,
      password: password,
    );
    return model.toEntity();
  }

  @override
  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String? connectedCalendar,
    String? recoveryMessage,
  }) async {
    final model = await _remote.register(
      username: username,
      email: email,
      password: password,
      name: name,
      phoneNumber: phoneNumber,
      connectedCalendar: connectedCalendar,
      recoveryMessage: recoveryMessage,
    );
    return model.toEntity();
  }

  @override
  Future<void> logout() => _remote.logout();

  @override
  Future<bool> findPassword(String email) => _remote.findPassword(email);
}
