part of 'operations_portal_page.dart';

extension _OperationsPortalAccess on _OperationsPortalPageState {
  Widget _noAccess(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Accès réservé',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ce compte doit être activé par un administrateur et associé au rôle organisation ou secouriste.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _signOut,
                  child: const Text('Changer de compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _signedOut(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => context.router.replace(const LoginRoute()),
        child: const Text('Se connecter'),
      ),
    ),
  );
  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.router.replace(const LoginRoute());
  }
}
