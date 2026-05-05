import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logist_app/app.dart';
import 'package:logist_app/core/providers/auth_providers.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: LogistApp(),
      ),
    );

    // Verify that app starts without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('AuthWrapper should show loading initially',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWithValue(AuthState.loading()),
        ],
        child: const MaterialApp(home: AuthWrapper()),
      ),
    );

    // Initially should show loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
