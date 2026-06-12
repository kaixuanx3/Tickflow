import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../auth/token_storage.dart';

/// Backend errors are always `{error: string}` with a proper status code.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}

ApiException toApiException(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return ApiException(e.response?.statusCode, data['error'] as String);
  }
  return ApiException(e.response?.statusCode, 'Cannot reach Tickflow — check your connection.');
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final storage = ref.watch(tokenStorageProvider);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ),
  );
  return dio;
});
