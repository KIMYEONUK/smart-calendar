import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_calendar/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smart_calendar/features/auth/domain/entities/user_entity.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<UserEntity?> build() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.getCurrentUser();
  }

  Future<void> loginWithUsername({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).loginWithUsername(
            username: username,
            password: password,
          ),
    );
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String? connectedCalendar,
    String? recoveryMessage,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            username: username,
            email: email,
            password: password,
            name: name,
            phoneNumber: phoneNumber,
            connectedCalendar: connectedCalendar,
            recoveryMessage: recoveryMessage,
          ),
    );
  }

  Future<void> logout() async {
    await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).logout(),
    );
    state = const AsyncData(null);
  }

  Future<bool> findPassword(String email) async {
    try {
      return await ref.read(authRepositoryProvider).findPassword(email);
    } catch (_) {
      return false;
    }
  }
}
