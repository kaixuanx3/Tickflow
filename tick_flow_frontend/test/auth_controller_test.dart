import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/api/api_client.dart';
import 'package:tick_flow_app/data/auth/auth_repository.dart';
import 'package:tick_flow_app/data/auth/auth_user.dart';
import 'package:tick_flow_app/data/auth/session_events.dart';
import 'package:tick_flow_app/features/auth/viewmodel/auth_controller.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.stored});

  AuthUser? stored;
  bool failLogin = false;

  @override
  Future<AuthUser> login({required String email, required String password}) async {
    if (failLogin) throw const ApiException(401, 'invalid credentials');
    return stored = AuthUser(id: '1', email: email);
  }

  @override
  Future<AuthUser> register({required String email, required String password}) async =>
      stored = AuthUser(id: '1', email: email);

  @override
  Future<AuthUser?> restore() async => stored;

  @override
  Future<void> signOut() async => stored = null;

  @override
  Future<void> deleteAccount() async => stored = null;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<AuthUser> updateProfile({String? name, bool? pushEnabled}) async =>
      stored ?? const AuthUser(id: '1', email: 'test@test.dev');
}

ProviderContainer makeContainer(FakeAuthRepository repo) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts signed out when nothing is stored', () async {
    final container = makeContainer(FakeAuthRepository());
    expect(await container.read(authControllerProvider.future), isNull);
  });

  test('restores a stored session', () async {
    final container = makeContainer(
      FakeAuthRepository(stored: const AuthUser(id: '1', email: 'kai@tickflow.dev')),
    );
    final user = await container.read(authControllerProvider.future);
    expect(user?.email, 'kai@tickflow.dev');
  });

  test('signIn stores the session', () async {
    final container = makeContainer(FakeAuthRepository());
    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).signIn('a@b.com', 'password1');
    expect(container.read(authControllerProvider).value?.email, 'a@b.com');
  });

  test('failed signIn throws and leaves the session signed out', () async {
    final container = makeContainer(FakeAuthRepository()..failLogin = true);
    await container.read(authControllerProvider.future);
    await expectLater(
      container.read(authControllerProvider.notifier).signIn('a@b.com', 'wrong-pass'),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(authControllerProvider).value, isNull);
  });

  test('signOut clears the session', () async {
    final container = makeContainer(
      FakeAuthRepository(stored: const AuthUser(id: '1', email: 'kai@tickflow.dev')),
    );
    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).signOut();
    expect(container.read(authControllerProvider).value, isNull);
  });

  test('deleteAccount clears the session', () async {
    final container = makeContainer(
      FakeAuthRepository(stored: const AuthUser(id: '1', email: 'kai@tickflow.dev')),
    );
    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).deleteAccount();
    expect(container.read(authControllerProvider).value, isNull);
  });

  test('a session-expired event signs the user out', () async {
    final container = makeContainer(
      FakeAuthRepository(stored: const AuthUser(id: '1', email: 'kai@tickflow.dev')),
    );
    await container.read(authControllerProvider.future);
    expect(container.read(authControllerProvider).value, isNotNull);

    // Transport layers (REST 401 / WS 4401) fire this when the JWT is rejected.
    container.read(sessionExpiredProvider.notifier).expired();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(container.read(authControllerProvider).value, isNull);
  });
}
