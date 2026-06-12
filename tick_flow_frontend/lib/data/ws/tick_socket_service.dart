import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/web_socket_channel.dart';

class Tick {
  const Tick({required this.symbol, required this.price, required this.ts});

  factory Tick.fromJson(Map<String, dynamic> json) => Tick(
        symbol: json['symbol'] as String,
        price: (json['price'] as num).toDouble(),
        ts: json['ts'] as int,
      );

  final String symbol;
  final double price;
  final int ts;
}

/// Thin seam over a websocket so the service is testable with a fake.
abstract class TickChannel {
  Stream<dynamic> get stream;
  int? get closeCode;
  void send(String data);
  Future<void> close();
}

class WebSocketTickChannel implements TickChannel {
  WebSocketTickChannel._(this._channel);

  final WebSocketChannel _channel;

  static Future<WebSocketTickChannel> connect(Uri uri) async {
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    return WebSocketTickChannel._(channel);
  }

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  int? get closeCode => _channel.closeCode;

  @override
  void send(String data) => _channel.sink.add(data);

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}

typedef TickChannelConnector = Future<TickChannel> Function();

/// Backend WS protocol: auth must be the FIRST message within 5s (else server
/// closes 4401); subscribe only after `auth_ok`; `subscribed` acks carry the
/// full authoritative set. Reconnects with exponential backoff + jitter and
/// re-auths + resubscribes. A 4401 close means the JWT was rejected — surfaced
/// via [onAuthFailed], no reconnect loop.
class TickSocketService {
  TickSocketService({
    required this.connector,
    required this.tokenProvider,
    this.onAuthFailed,
    this.reconnectBase = const Duration(seconds: 1),
  });

  final TickChannelConnector connector;
  final Future<String?> Function() tokenProvider;
  final void Function()? onAuthFailed;
  final Duration reconnectBase;

  final _ticks = StreamController<Tick>.broadcast();
  final _rng = math.Random();

  Set<String> _desired = const {};
  Set<String> _subscribed = const {};
  TickChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  int _attempts = 0;
  bool _authed = false;
  bool _running = false;

  Stream<Tick> get ticks => _ticks.stream;

  void start() {
    if (_running) return;
    _running = true;
    _connect();
  }

  void stop() {
    _running = false;
    _reconnectTimer?.cancel();
    _teardown();
  }

  void dispose() {
    stop();
    _ticks.close();
  }

  void setDesiredSymbols(Set<String> symbols) {
    _desired = {...symbols};
    if (_authed) _syncSubscriptions();
  }

  Future<void> _connect() async {
    if (!_running) return;
    try {
      final token = await tokenProvider();
      if (token == null) return; // signed out — caller stops the service
      final channel = await connector();
      if (!_running) {
        await channel.close();
        return;
      }
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onDone: _onDone,
        onError: (_) => _onDone(),
      );
      channel.send(jsonEncode({'type': 'auth', 'token': token}));
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (msg['type']) {
      case 'auth_ok':
        _authed = true;
        _attempts = 0;
        _subscribed = const {};
        _syncSubscriptions();
      case 'subscribed':
        _subscribed = {...(msg['symbols'] as List).cast<String>()};
      case 'tick':
        _ticks.add(Tick.fromJson(msg));
    }
  }

  void _syncSubscriptions() {
    final channel = _channel;
    if (channel == null || !_authed) return;
    final toAdd = _desired.difference(_subscribed);
    final toRemove = _subscribed.difference(_desired);
    if (toAdd.isNotEmpty) {
      channel.send(jsonEncode({'type': 'subscribe', 'symbols': toAdd.toList()}));
    }
    if (toRemove.isNotEmpty) {
      channel.send(jsonEncode({'type': 'unsubscribe', 'symbols': toRemove.toList()}));
    }
    // Optimistic; the next `subscribed` ack is authoritative.
    _subscribed = {..._desired};
  }

  void _onDone() {
    final code = _channel?.closeCode;
    _teardown();
    if (code == 4401) {
      onAuthFailed?.call();
      return;
    }
    _scheduleReconnect();
  }

  void _teardown() {
    _authed = false;
    _sub?.cancel();
    _sub = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(channel.close());
  }

  void _scheduleReconnect() {
    if (!_running) return;
    _reconnectTimer?.cancel();
    final exponent = math.min(_attempts, 5);
    _attempts++;
    final jitter = 0.5 + _rng.nextDouble() * 0.5;
    final delay = reconnectBase * (math.pow(2, exponent).toInt()) * jitter;
    _reconnectTimer = Timer(delay, _connect);
  }
}
