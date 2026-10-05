import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/shelter_manager/presentation/pages/create_shelter_page.dart';
import 'package:salus/features/shelter_manager/presentation/pages/shelter_detail_page.dart';
import 'package:salus/features/shelter_manager/presentation/providers/shelter_manager_providers.dart';
import 'package:salus/features/shelter_manager/presentation/widgets/shelter_detail_panel.dart';
import 'package:salus/features/shelter_manager/presentation/widgets/shelter_list_panel.dart';
import 'package:salus/features/shelters/domain/models/shelter_location_selection.dart';
import 'package:salus/core/entities/shelter_entity.dart';


/// Écran du gestionnaire de refuge (route `ShelterManagerRoute`).
/// Accessible uniquement avec le rôle `shelterManager` (users/{uid}.roles),
/// posé à la main par un admin dans Firestore.
@RoutePage()
class ShelterManagerPage extends ConsumerWidget {
  const ShelterManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) {
      return const _Info(
        icon: Icons.lock_outline,
        title: 'Connexion requise',
        body: 'Connecte-toi avec ton compte pour accéder à la gestion des refuges.',
      );
    }

    return ref.watch(isShelterManagerProvider).when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => _Info(
            icon: Icons.wifi_off,
            title: 'Chargement impossible',
            body: 'Vérifie ta connexion puis réessaie.',
            actionLabel: 'Réessayer',
            onAction: () => ref.invalidate(isShelterManagerProvider),
          ),
          data: (isManager) => isManager
              ? const _ShelterManagerHome()
              : const _Info(
                  icon: Icons.gpp_maybe_outlined,
                  title: 'Accès réservé',
                  body: 'Ton compte n’a pas le rôle gestionnaire de refuge. '
                      'Contacte un administrateur pour l’obtenir.',
                ),
        );
  }
}

class _ShelterManagerHome extends ConsumerStatefulWidget {
  const _ShelterManagerHome();

  @override
  ConsumerState<_ShelterManagerHome> createState() =>
      _ShelterManagerHomeState();
}

class _ShelterManagerHomeState extends ConsumerState<_ShelterManagerHome> {
  static const _wideBreakpoint = 900.0;
  String? _selectedId;

  Future<ShelterLocationSelection?> _pickLocation(
    GeoPoint? location,
    String? address,
  ) =>
      context.router.push<ShelterLocationSelection>(
        ShelterLocationPickerRoute(
          initialLocation: location,
          initialAddress: address,
        ),
      );

  Future<void> _create() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ManagerCreateShelterPage(onPickLocation: _pickLocation),
      ),
    );
    if (id == null || !mounted) return;
    setState(() => _selectedId = id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Refuge créé. Il sera visible après validation.'),
    ));
  }

  void _open(Shelter shelter, {required bool wide}) {
    if (wide) {
      setState(() => _selectedId = shelter.id);
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ShelterDetailPage(shelterId: shelter.id),
      ));
    }
  }

  Future<void> _signOut() async {
    final router = context.router;
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(authProvider); // se réhydrate à « non connecté »
    router.replaceAll([const LoginRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(shelterActionsProvider, (_, next) {
      if (next.hasError) {
        final e = next.error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ArgumentError
              ? '${e.message}'
              : 'Action impossible, vérifie ta connexion et réessaie'),
        ));
      }
    });

    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final sheltersAsync = ref.watch(managedSheltersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion des refuges'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: wide || (sheltersAsync.value?.isEmpty ?? true)
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Créer un refuge'),
            ),
      body: SafeArea(
        child: sheltersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: ElevatedButton(
              onPressed: () => ref.invalidate(managedSheltersProvider),
              child: const Text('Réessayer'),
            ),
          ),
          data: (shelters) {
            final selected =
                shelters.where((s) => s.id == _selectedId).firstOrNull ??
                    (wide ? shelters.firstOrNull : null);

            final list = ShelterListPanel(
              shelters: shelters,
              selectedId: wide ? selected?.id : null,
              onSelect: (s) => _open(s, wide: wide),
              onCreate: _create,
              showCreateButton: wide,
            );

            if (!wide) return list;
            return Row(
              children: [
                SizedBox(width: 380, child: list),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selected == null
                      ? const Center(
                          child: Text(
                            'Sélectionne ou crée un refuge',
                            style: TextStyle(color: AppColors.inactive),
                          ),
                        )
                      : ShelterDetailPanel(shelterId: selected.id),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: const AutoLeadingButton(),
          title: const Text('Gestion des refuges'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      )),
                  const SizedBox(height: 8),
                  Text(body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.inactive)),
                  if (onAction != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: onAction, child: Text(actionLabel!)),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
