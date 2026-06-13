import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'alert_models.dart';

class AlertsRepository {
  AlertsRepository(this._dio);

  final Dio _dio;

  Future<List<Alert>> fetch() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/alerts');
      return (res.data!['alerts'] as List)
          .map((a) => Alert.fromJson(a as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> create({
    required String symbol,
    required AlertRuleType ruleType,
    required double threshold,
    required AlertKind kind,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>('/alerts', data: {
        'symbol': symbol,
        'ruleType': ruleType.api,
        'threshold': threshold,
        'kind': kind.api,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Clients may patch threshold/kind, or push status back to 'active'
  /// (re-arm) — the alert engine owns every other transition.
  Future<void> update(
    String id, {
    double? threshold,
    AlertKind? kind,
    bool reactivate = false,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>('/alerts/$id', data: {
        'threshold': ?threshold,
        'kind': ?kind?.api,
        if (reactivate) 'status': 'active',
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _dio.delete<void>('/alerts/$id');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final alertsRepositoryProvider =
    Provider<AlertsRepository>((ref) => AlertsRepository(ref.watch(dioProvider)));
