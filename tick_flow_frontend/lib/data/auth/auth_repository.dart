import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_user.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<AuthUser> login({required String email, required String password}) =>
      _authenticate('/auth/login', email, password);

  Future<AuthUser> register({required String email, required String password}) =>
      _authenticate('/auth/register', email, password);

  /// Session survives restarts via secure storage; JWT lasts 7d (401 -> re-login).
  Future<AuthUser?> restore() async {
    if (await _storage.readToken() == null) return null;
    return _storage.readUser();
  }

  Future<void> signOut() => _storage.clear();

  Future<AuthUser> _authenticate(String path, String email, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'email': email, 'password': password},
      );
      final body = res.data!;
      final user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
      await _storage.save(token: body['token'] as String, user: user);
      return user;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);
