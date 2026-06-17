import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'portfolio_models.dart';

class PortfolioRepository {
  PortfolioRepository(this._dio);

  final Dio _dio;

  Future<PortfolioSummary> fetchSummary() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/portfolio/summary');
      return PortfolioSummary.fromJson(res.data!);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> add({
    required String symbol,
    required double qty,
    required double buyPrice,
    required AssetType assetType,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>('/portfolio/holdings', data: {
        'symbol': symbol,
        'qty': qty,
        'buyPrice': buyPrice,
        'assetType': assetType.name,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> update(
    String id, {
    double? qty,
    double? buyPrice,
    AssetType? assetType,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>('/portfolio/holdings/$id', data: {
        'qty': ?qty,
        'buyPrice': ?buyPrice,
        'assetType': ?assetType?.name,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _dio.delete<void>('/portfolio/holdings/$id');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Persists the user's manual holding order (full ordered id list).
  Future<void> reorder(List<String> orderedIds) async {
    try {
      await _dio.put<void>('/portfolio/holdings/reorder', data: {'order': orderedIds});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final portfolioRepositoryProvider =
    Provider<PortfolioRepository>((ref) => PortfolioRepository(ref.watch(dioProvider)));
