import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'notification_models.dart';

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  /// Triggered-alert history, newest first (ordering set by the backend).
  Future<List<TriggeredNotification>> fetch() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/notifications');
      return (res.data!['notifications'] as List)
          .map((n) => TriggeredNotification.fromJson(n as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => NotificationsRepository(ref.watch(dioProvider)));
