import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/features/auth/view/login_screen.dart';
import 'package:tick_flow_app/l10n/app_localizations.dart';

Widget _app() => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginScreen(),
      ),
    );

void main() {
  testWidgets('renders the form and validates empty input', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('Tickflow'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('toggles to register mode', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Have an account? Sign in'), findsOneWidget);
  });
}
