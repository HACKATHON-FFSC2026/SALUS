import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/state/location_state.dart';
import 'package:salus/features/shelters/presentation/controllers/validated_shelters_controller.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_bottom_sheet.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_status_ui.dart';
import 'package:salus/features/map/presentation/providers/risk_zones_provider.dart';
import 'package:salus/features/risks/presentation/providers/providers/risk_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SheltersPage extends ConsumerStatefulWidget {
  const SheltersPage({super.key});

  @override
  ConsumerState<SheltersPage> createState() => _SheltersPageState();
}

class _SheltersPageState extends ConsumerState<SheltersPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(locationProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final shelters = ref.watch(allSheltersProvider);
    // Un invité n'a pas d'uid Firebase : la création de refuge serait refusée.
    final isGuest = ref.watch(currentUidProvider) == null;
    final location = ref.watch(locationProvider);
    final externalRisks = ref.watch(riskZonesProvider);
    final firestoreRisks = ref.watch(activeRiskZonesProvider);
    final hasRiskData = externalRisks.hasValue || firestoreRisks.hasValue;
    final hasCompleteRiskData =
        externalRisks.hasValue && firestoreRisks.hasValue;
    final riskDataUnavailable =
        !hasRiskData && externalRisks.hasError && firestoreRisks.hasError;
    final riskDataIncomplete =
        !hasCompleteRiskData ||
        externalRisks.hasError ||
        firestoreRisks.hasError;
    final riskZonesById = <String, Zone>{
      for (final zone in externalRisks.value ?? const <Zone>[])
        if (zone.isActive && zone.type == ZoneType.risk) zone.id: zone,
      for (final zone in firestoreRisks.value ?? const <Zone>[])
        if (zone.isActive && zone.type == ZoneType.risk) zone.id: zone,
    };
    final position = location.position;

    return Scaffold(
      appBar: AppBar(title: const Text('Refuges')),
      body: shelters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _MessageState(
          icon: Icons.cloud_off_outlined,
          text: 'Impossible de charger les refuges.',
          action: TextButton(
            onPressed: () => ref.invalidate(allSheltersProvider),
            child: const Text('Réessayer'),
          ),
        ),
        data: (items) {
          final unsafeShelterIds = ref.read(findSheltersInRiskZonesProvider)(
            shelters: items,
            zones: riskZonesById.values.toList(growable: false),
          );
          final ranked =
              items
                  .where(
                    (shelter) =>
                        shelter.validationStatus == ValidationStatus.validated,
                  )
                  .map(
                    (shelter) => _RankedShelter(
                      shelter,
                      position?.distanceTo(
                        GeoPoint(
                          latitude: shelter.location.latitude,
                          longitude: shelter.location.longitude,
                        ),
                      ),
                      isInRiskZone: unsafeShelterIds.contains(shelter.id),
                    ),
                  )
                  .toList()
                ..sort((a, b) {
                  final aDistance = a.distanceKm ?? double.infinity;
                  final bDistance = b.distanceKm ?? double.infinity;
                  return aDistance.compareTo(bDistance);
                });
          final eligible = ranked
              .where(
                (item) =>
                    !item.isInRiskZone &&
                    _hasSpace(item.shelter) &&
                    (item.shelter.status == ShelterStatus.open ||
                        item.shelter.status == ShelterStatus.almostFull),
              )
              .toList();
          // Sans GPS, ne pas présenter l'ordre alphabétique comme une
          // recommandation de proximité.
          final recommended =
              position == null || eligible.isEmpty || riskDataIncomplete
              ? null
              : eligible.first;
          final others = ranked.where((item) => item != recommended).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allSheltersProvider);
              await ref.read(locationProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Trouvez un endroit sûr près de vous.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!isGuest) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () =>
                            context.router.push(const CreateShelterRoute()),
                        icon: const Icon(
                          Icons.add_home_work_outlined,
                          size: 17,
                        ),
                        label: const Text('Créer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ],
                ),
                if (location.status == LocationStatus.loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  )
                else if (position == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _LocationNotice(
                      message:
                          location.errorMessage ??
                          'Activez la localisation pour calculer les distances.',
                      onRetry: () =>
                          ref.read(locationProvider.notifier).refresh(),
                    ),
                  ),
                if (riskDataIncomplete)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _RiskDataNotice(
                      message: riskDataUnavailable
                          ? 'Les zones de risque sont indisponibles. Aucune recommandation automatique ne sera faite.'
                          : externalRisks.hasError || firestoreRisks.hasError
                          ? 'Certaines sources de risque sont indisponibles. La recommandation automatique est suspendue. Vérifiez les consignes locales avant de vous déplacer.'
                          : 'Vérification des zones de risque en cours. La recommandation est suspendue jusqu’au chargement de toutes les sources.',
                    ),
                  ),
                const SizedBox(height: 24),
                const _SectionLabel('REFUGE RECOMMANDÉ'),
                const SizedBox(height: 10),
                if (recommended == null)
                  _InfoCard(
                    text: ranked.isEmpty
                        ? 'Aucun refuge validé à afficher pour le moment.'
                        : position == null
                        ? 'Activez la localisation pour obtenir une recommandation selon votre proximité.'
                        : riskDataIncomplete
                        ? 'La recommandation attend le chargement de toutes les sources de zones de risque.'
                        : ranked.every((item) => item.isInRiskZone)
                        ? 'Tous les refuges connus se trouvent dans une zone de risque active.'
                        : 'Aucun refuge validé, ouvert avec des places disponibles n’a été trouvé.',
                  )
                else
                  _RecommendationCard(
                    item: recommended,
                    onTap: () => _openDirections(
                      context,
                      recommended.shelter,
                      riskDataIncomplete: riskDataIncomplete,
                    ),
                    onDetails: () => showShelterDetailSheet(
                      context,
                      recommended.shelter,
                      onStartRoute: () => _openDirections(
                        context,
                        recommended.shelter,
                        riskDataIncomplete: riskDataIncomplete,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const _SectionLabel('AUTRES REFUGES'),
                const SizedBox(height: 10),
                if (others.isEmpty)
                  const _InfoCard(text: 'Aucun autre refuge à afficher.')
                else
                  ...others.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ShelterTile(
                        item: item,
                        isInRiskZone: item.isInRiskZone,
                        onTap: () => showShelterDetailSheet(
                          context,
                          item.shelter,
                          routeUnavailableReason: item.isInRiskZone
                              ? 'Ce refuge est situé dans une zone de risque active connue.'
                              : null,
                          onStartRoute: item.isInRiskZone
                              ? null
                              : () => _openDirections(
                                  context,
                                  item.shelter,
                                  riskDataIncomplete: riskDataIncomplete,
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> _openDirections(
  BuildContext context,
  Shelter shelter, {
  required bool riskDataIncomplete,
}) async {
  final shouldContinue =
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Vérifiez votre trajet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Le trajet est calculé par une application externe. '
                'SALUS ne vérifie ni son tracé ni son passage dans les zones à risque. '
                'Aucun itinéraire sûr n’est garanti.',
              ),
              if (riskDataIncomplete) ...[
                const SizedBox(height: 12),
                const Text(
                  'La vérification des zones à risque est incomplète. '
                  'Vérifiez les consignes locales avant de partir.',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continuer vers Maps'),
            ),
          ],
        ),
      ) ??
      false;
  if (!shouldContinue) return;

  final destination =
      '${shelter.location.latitude},${shelter.location.longitude}';
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': destination,
    'travelmode': 'walking',
  });
  final nativeMapUris = [
    Uri(
      scheme: 'google.navigation',
      queryParameters: {'q': destination, 'mode': 'w'},
    ),
    Uri(
      scheme: 'geo',
      path: destination,
      queryParameters: {'q': '$destination(${shelter.name})'},
    ),
  ];
  var opened = false;
  for (final mapUri in nativeMapUris) {
    if (await _tryLaunch(mapUri, LaunchMode.externalApplication)) {
      opened = true;
      break;
    }
  }
  if (!opened) {
    opened =
        await _tryLaunch(uri, LaunchMode.externalApplication) ||
        await _tryLaunch(uri, LaunchMode.platformDefault) ||
        await _tryLaunch(uri, LaunchMode.inAppBrowserView);
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Aucune application de cartes ou aucun navigateur ne peut ouvrir cet itinéraire.",
        ),
      ),
    );
  }
}

Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
  try {
    return await launchUrl(uri, mode: mode);
  } catch (error) {
    debugPrint('Échec ouverture navigation ($mode, $uri): $error');
    return false;
  }
}

class _RankedShelter {
  const _RankedShelter(
    this.shelter,
    this.distanceKm, {
    this.isInRiskZone = false,
  });
  final Shelter shelter;
  final double? distanceKm;
  final bool isInRiskZone;
}

bool _hasSpace(Shelter shelter) => shelter.availablePlaces > 0;

String _distanceLabel(double? km) => km == null
    ? '—'
    : km < 1
    ? '${(km * 1000).round()} m'
    : '${km.toStringAsFixed(1)} km';

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.item,
    required this.onTap,
    required this.onDetails,
  });
  final _RankedShelter item;
  final VoidCallback onTap;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final shelter = item.shelter;
    final available = shelter.availablePlaces;
    final capacityColor = shelter.availabilityColor;
    final capacityTextColor = capacityColor == AppColors.secondary
        ? AppColors.primary
        : capacityColor;
    return Card(
      margin: EdgeInsets.zero,
      color: shelter.availabilityBackgroundColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: shelter.availabilityColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const Text(
                    'RECOMMANDÉ',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  ShelterStatusText(status: shelter.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shelter.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.inactive),
                ],
              ),
              const SizedBox(height: 4),
              if (item.distanceKm != null)
                Row(
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      size: 16,
                      color: AppColors.inactive,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _distanceLabel(item.distanceKm),
                      style: const TextStyle(
                        color: AppColors.inactive,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Occupation',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '${shelter.capacityOccupied}/${shelter.capacityTotal} · $available libres',
                          style: TextStyle(
                            color: capacityTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: shelter.occupancyRatio,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(5),
                      color: capacityColor,
                      backgroundColor: Colors.black12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('Démarrer l’itinéraire'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterTile extends StatelessWidget {
  const _ShelterTile({
    required this.item,
    required this.isInRiskZone,
    required this.onTap,
  });
  final _RankedShelter item;
  final bool isInRiskZone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shelter = item.shelter;
    final available = shelter.availablePlaces;
    final capacityColor = shelter.availabilityColor;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: shelter.availabilityBackgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shelter.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShelterValidationChip(
                    status: shelter.validationStatus,
                    prominent: true,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ShelterStatusText(status: shelter.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shelter.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inactive,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.distanceKm != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _distanceLabel(item.distanceKm),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isInRiskZone) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.sos,
                      size: 17,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Situé dans une zone de risque active connue · itinéraire désactivé',
                        style: TextStyle(
                          color: AppColors.sos,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Occupation',
                            style: TextStyle(
                              color: AppColors.inactive,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '${shelter.capacityOccupied}/${shelter.capacityTotal} · $available libres',
                          style: TextStyle(
                            color: capacityColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: shelter.occupancyRatio,
                        minHeight: 5,
                        color: capacityColor,
                        backgroundColor: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 10,
      letterSpacing: .7,
      color: AppColors.inactive,
      fontWeight: FontWeight.bold,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: const TextStyle(color: AppColors.inactive)),
    ),
  );
}

class _RiskDataNotice extends StatelessWidget {
  const _RiskDataNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF6E2),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.sos),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppColors.inactive),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}

class _LocationNotice extends StatelessWidget {
  const _LocationNotice({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.secondary.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
        IconButton(
          onPressed: onRetry,
          icon: const Icon(Icons.my_location),
          tooltip: 'Réessayer la localisation',
        ),
      ],
    ),
  );
}
