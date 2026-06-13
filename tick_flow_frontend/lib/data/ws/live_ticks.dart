import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../auth/session_events.dart';
import '../auth/token_storage.dart';
import '../markets/quotes_cache.dart';
import '../markets/symbol_subscriptions.dart';
import 'tick_socket_service.dart';

final tickServiceProvider = Provider.autoDispose<TickSocketService>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final service = TickSocketService(
    connector: () => WebSocketTickChannel.connect(Uri.parse(Env.wsUrl)),
    tokenProvider: storage.readToken,
    onAuthFailed: () => ref.read(sessionExpiredProvider.notifier).expired(),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Watched by the authed app shell: the socket runs exactly while a signed-in
/// shell is on screen. Mirrors the ref-counted desired-symbol set into the
/// socket and merges incoming ticks into the quote cache.
final liveTicksProvider = Provider.autoDispose<void>((ref) {
  final service = ref.watch(tickServiceProvider);
  service.setDesiredSymbols(ref.watch(symbolSubscriptionsProvider));
  final sub = service.ticks.listen(
    (tick) => ref.read(quotesProvider.notifier).applyTick(tick),
  );
  ref.onDispose(sub.cancel);
  service.start();
});
