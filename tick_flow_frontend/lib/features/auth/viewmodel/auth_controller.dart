import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth/auth_repository.dart';
import '../../../data/auth/auth_user.dart';
import '../../../data/auth/session_events.dart';

/// Session state: null = signed out. Sign-in/up failures are thrown to the
/// caller (form shows them inline) and leave the session state untouched, so
/// the router never bounces mid-attempt.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() {
    // Transport layers bump this when the server rejects the JWT (WS 4401).
    ref.listen(sessionExpiredProvider, (_, _) => signOut());
    return ref.watch(authRepositoryProvider).restore();
  }

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

  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
