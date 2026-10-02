import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/sos/presentation/widgets/sos_button.dart';

/// Régression du bouton SOS inerte.
///
/// Le widget détectait la fin du maintien via `AnimationStatus`. À la borne,
/// le statut reste `forward` et `completed` n'est jamais notifié (le ticker
/// s'arrête avant le frame suivant) : `_stop()` voyait donc un maintien
/// « non terminé » et annulait l'envoi. Aucun maintien, quelle que soit sa
/// durée, n'envoyait donc rien. La détection se fait désormais sur
/// `AnimationController.value`.
void main() {
  Widget harness(VoidCallback onHold, {bool enabled = true}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SosButton(
          isLoading: false,
          isEnabled: enabled,
          onHold: onHold,
        ),
      ),
    ),
  );

  /// Le premier frame amorce seulement le ticker, les suivants avancent la
  /// jauge : six paliers de 400 ms suffisent à franchir la durée de maintien.
  const steps = [400, 400, 400, 400, 400, 400];

  testWidgets('un maintien complet envoie l\'alerte', (tester) async {
    var held = 0;
    await tester.pumpWidget(harness(() => held++));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SosButton)),
    );
    for (final step in steps) {
      await tester.pump(Duration(milliseconds: step));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(held, 1);
  });

  testWidgets('un maintien interrompu n\'envoie rien', (tester) async {
    var held = 0;
    await tester.pumpWidget(harness(() => held++));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SosButton)),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(held, 0);
  });

  testWidgets('un bouton désactivé n\'envoie rien', (tester) async {
    var held = 0;
    await tester.pumpWidget(harness(() => held++, enabled: false));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SosButton)),
    );
    for (final step in steps) {
      await tester.pump(Duration(milliseconds: step));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(held, 0);
  });

  testWidgets('la jauge revient à zéro après un maintien annulé', (
    tester,
  ) async {
    await tester.pumpWidget(harness(() {}));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SosButton)),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await gesture.up();
    await tester.pumpAndSettle();

    double value() => tester
        .widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        )
        .value!;
    expect(value(), 0.0, reason: 'un maintien annulé doit purger la jauge');
  });
}
