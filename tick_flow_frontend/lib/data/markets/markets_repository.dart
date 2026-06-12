import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'market_models.dart';

class MarketsRepository {
  MarketsRepository(this._dio);

  final Dio _dio;

  Future<SymbolPage> fetchSymbols(int page) async {
    try {
      final res = await _dio
          .get<Map<String, dynamic>>('/symbols', queryParameters: {'page': page});
      return SymbolPage.fromJson(res.data!);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<SymbolInfo>> search(String query) async {
    try {
      final res = await _dio
          .get<Map<String, dynamic>>('/symbols/search', queryParameters: {'q': query});
      return (res.data!['results'] as List)
          .map((s) => SymbolInfo.fromJson(s as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Batched; the backend caps at 50 symbols per call. Unknown symbols are
  /// simply absent from the response.
  Future<List<Quote>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return const [];
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/quotes',
        queryParameters: {'symbols': symbols.join(',')},
      );
      return (res.data!['quotes'] as List)
          .map((q) => Quote.fromJson(q as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final marketsRepositoryProvider =
    Provider<MarketsRepository>((ref) => MarketsRepository(ref.watch(dioProvider)));
