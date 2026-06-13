import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

class WatchlistRepository {
  WatchlistRepository(this._dio);

  final Dio _dio;

  Future<List<String>> fetch() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/watchlist');
      return [
        for (final item in res.data!['items'] as List)
          (item as Map<String, dynamic>)['symbol'] as String,
      ];
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> add(String symbol) async {
    try {
      await _dio.post<Map<String, dynamic>>('/watchlist', data: {'symbol': symbol});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> remove(String symbol) async {
    try {
      await _dio.delete<void>('/watchlist/$symbol');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final watchlistRepositoryProvider =
    Provider<WatchlistRepository>((ref) => WatchlistRepository(ref.watch(dioProvider)));
