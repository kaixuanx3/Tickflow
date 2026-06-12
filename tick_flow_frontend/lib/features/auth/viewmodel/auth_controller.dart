import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth/auth_repository.dart';
import '../../../data/auth/auth_user.dart';

/// Session state: null = signed out. Sign-in/up failures are thrown to the
/// caller (form shows them inline) and leave the session state untouched, so
/// the router never bounces mid-attempt.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() => ref.watch(authRepositoryProvider).restore();

  Future<void> signIn(String email, String password) async {
    final user = await ref.read(authRepositoryProvider).login(email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> signUp(String email, String password) async {
    final user =
        await ref.read(authRepositoryProvider).register(email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
