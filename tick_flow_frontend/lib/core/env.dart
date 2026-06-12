/// Build-time environment. Pass with:
/// `flutter run -d chrome --dart-define=API_URL=https://tickflow-staging.up.railway.app`
abstract final class Env {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// `http://x` -> `ws://x/ws`, `https://x` -> `wss://x/ws`
  static String get wsUrl => '${apiUrl.replaceFirst('http', 'ws')}/ws';
}
