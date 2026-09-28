import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/widgets/google_logo.dart';
import 'package:salus/features/auth/pages/login_page.dart';
import 'package:salus/features/home/pages/main_page.dart';

void main() {
  testWidgets('login exposes both entry points', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('Continuer sans connexion'), findsOneWidget);
    expect(find.byType(GoogleLogo), findsOneWidget);
  });

  testWidgets('main nav bar does not overflow on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 891);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
