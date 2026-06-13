import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped by transport layers (WS 4401, REST 401) when the server rejects the
/// JWT. The auth controller listens and signs out — keeps `data/` from
/// importing `features/`.
class SessionEvents extends Notifier<int> {
  @override
  int build() => 0;

  void expired() => state++;
}

final sessionExpiredProvider = NotifierProvider<SessionEvents, int>(SessionEvents.new);
