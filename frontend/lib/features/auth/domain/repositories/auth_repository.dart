import 'package:smart_calendar/features/auth/domain/entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> loginWithUsername({
    required String username,
    required String password,
  });
  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String? connectedCalendar,
    String? recoveryMessage,
  });
  Future<void> logout();
  Future<bool> findPassword(String email);
}
