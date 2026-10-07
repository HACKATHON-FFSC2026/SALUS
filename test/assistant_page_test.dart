import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/assistant/presentation/pages/assistant_page.dart';
import 'package:salus/features/auth/domain/user_profile.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/auth/presentation/state/auth_state.dart';

class _SignedInNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    user: UserProfile(uid: 'test-user'),
  );
}

void main() {
  testWidgets('shows the contextual prompts without overflowing a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_SignedInNotifier.new)],
        child: const MaterialApp(home: AssistantPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Copilote de crise'), findsOneWidget);
    expect(find.text('On va procéder étape par étape.'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      find.text('L’eau monte près de chez moi, que faire ?'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
