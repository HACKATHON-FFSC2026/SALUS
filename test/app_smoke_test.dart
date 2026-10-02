import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/widgets/google_logo.dart';
import 'package:salus/features/auth/presentation/pages/login_page.dart';
import 'package:salus/features/home/presentation/pages/main_page.dart';
import 'package:salus/features/risks/domain/repositories/safe_zone.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';

/// La barre d'onglets héberge la carte, qui appelle les API GDACS et altitude
/// via `dio`. Ces appels laissent des timers en vol et font échouer le test
/// au démontage.
class _StubSafeZoneRepository implements SafeZoneRepository {
  @override
  Future<List<Zone>> getSafeZonesAround(GeoPoint center) async => const [];
}

void main() {
  testWidgets('login exposes both entry points', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          riskZonesProvider.overrideWith((ref) async => const <Zone>[]),
          safeZoneRepositoryProvider.overrideWithValue(_StubSafeZoneRepository()),
        ],
        child: const MaterialApp(home: MainPage()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
