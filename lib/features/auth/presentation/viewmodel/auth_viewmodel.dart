import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_providers.dart';

/// Maneja las acciones de login/registro y expone su estado async
/// (loading / error / data) para que las vistas reaccionen sin lógica propia.
class AuthViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(
      () => repository.signIn(email: email, password: password),
    );
    return !state.hasError;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(
      () => repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
    return !state.hasError;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, void>(
  AuthViewModel.new,
);
