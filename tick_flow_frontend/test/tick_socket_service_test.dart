import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/ws/tick_socket_service.dart';

class FakeChannel implements TickChannel {
  final _incoming = StreamController<dynamic>();
  final sent = <Map<String, dynamic>>[];

  @override
  int? closeCode;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  void send(String data) => sent.add(jsonDecode(data) as Map<String, dynamic>);

  @override
  Future<void> close() async {}

  void serverSend(Map<String, dynamic> msg) => _incoming.add(jsonEncode(msg));

  Future<void> serverClose([int? code]) async {
    closeCode = code;
    await _incoming.close();
  }
}

Future<void> pump([int ms = 30]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late List<FakeChannel> channels;
  late TickSocketService service;
  late bool authFailed;

  setUp(() {
    channels = [];
    authFailed = false;
    service = TickSocketService(
      connector: () async {
        final channel = FakeChannel();
        channels.add(channel);
        return channel;
      },
      tokenProvider: () async => 'jwt-token',
      onAuthFailed: () => authFailed = true,
      reconnectBase: const Duration(milliseconds: 10),
    );
  });

  tearDown(() => service.dispose());

  test('sends auth as the first message and subscribes only after auth_ok', () async {
    service.setDesiredSymbols({'AAPL'});
    service.start();
    await pump();

    expect(channels, hasLength(1));
    expect(channels[0].sent, hasLength(1)); // nothing but auth before auth_ok
    expect(channels[0].sent.first, {'type': 'auth', 'token': 'jwt-token'});

    channels[0].serverSend({'type': 'auth_ok'});
    await pump();
    expect(channels[0].sent[1], {
      'type': 'subscribe',
      'symbols': ['AAPL'],
    });
  });

  test('routes ticks to the stream', () async {
    service.setDesiredSymbols({'AAPL'});
    service.start();
    await pump();
    channels[0].serverSend({'type': 'auth_ok'});

    final next = service.ticks.first;
    channels[0].serverSend({'type': 'tick', 'symbol': 'AAPL', 'price': 101.5, 'ts': 123});
    final tick = await next;

    expect(tick.symbol, 'AAPL');
    expect(tick.price, 101.5);
    expect(tick.ts, 123);
  });

  test('sends subscribe/unsubscribe diffs as the desired set changes', () async {
    service.setDesiredSymbols({'AAPL'});
    service.start();
    await pump();
    channels[0].serverSend({'type': 'auth_ok'});
    await pump();

    service.setDesiredSymbols({'AAPL', 'TSLA'});
    expect(channels[0].sent[2], {
      'type': 'subscribe',
      'symbols': ['TSLA'],
    });

    service.setDesiredSymbols({'TSLA'});
    expect(channels[0].sent[3], {
      'type': 'unsubscribe',
      'symbols': ['AAPL'],
    });
  });

  test('reconnects, re-auths and resubscribes after a server drop', () async {
    service.setDesiredSymbols({'AAPL'});
    service.start();
    await pump();
    channels[0].serverSend({'type': 'auth_ok'});
    await pump();

    await channels[0].serverClose(); // abnormal drop
    await pump(120);

    expect(channels, hasLength(2));
    expect(channels[1].sent.first, {'type': 'auth', 'token': 'jwt-token'});

    channels[1].serverSend({'type': 'auth_ok'});
    await pump();
    expect(channels[1].sent[1], {
      'type': 'subscribe',
      'symbols': ['AAPL'],
    });
  });

  test('a 4401 close reports auth failure and does not reconnect', () async {
    service.start();
    await pump();

    await channels[0].serverClose(4401);
    await pump(120);

    expect(authFailed, isTrue);
    expect(channels, hasLength(1));
  });
}
