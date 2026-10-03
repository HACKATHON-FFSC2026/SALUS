import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:toastification/toastification.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/features/map/presentation/utils/map_animation_helper.dart';
import 'package:salus/features/map/domain/models/geocoding_result.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/features/shelters/domain/models/shelter_location_selection.dart';

/// Sélection de la localisation d'un refuge : recherche de lieu, position GPS
/// et ajustement manuel du pin (la carte se déplace sous un pin fixe).
@RoutePage()
class ShelterLocationPickerPage extends ConsumerStatefulWidget {
  const ShelterLocationPickerPage({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  final GeoPoint? initialLocation;
  final String? initialAddress;

  @override
  ConsumerState<ShelterLocationPickerPage> createState() =>
      _ShelterLocationPickerPageState();
}

class _ShelterLocationPickerPageState
    extends ConsumerState<ShelterLocationPickerPage>
        // TickerProviderStateMixin (et non SingleTicker…) : chaque déplacement de
        // caméra crée un ticker via MapController.animatedMove.
        with
        TickerProviderStateMixin {
  /// Même position par défaut que SalusMapWidget (Antananarivo).
  static const _defaultLocation = LatLng(-18.8792, 47.5079);
  static const _defaultZoom = 13.0;
  static const _selectionZoom = 17.0;
  static const _animationDuration = Duration(milliseconds: 600);
  static const _reverseDebounce = Duration(milliseconds: 700);

  final _mapController = MapController();
  final _searchController = TextEditingController();

  late GeoPoint _location;
  String? _address;
  List<GeocodingResult> _results = const [];
  bool _isSearching = false;
  bool _isLocating = false;
  bool _hasGpsFix = false;
  bool _mapReady = false;

  Timer? _reverseTimer;
  LatLng? _lastAddressRequest;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    _location =
        initial ??
        GeoPoint(_defaultLocation.latitude, _defaultLocation.longitude);
    _address = widget.initialAddress;
  }

  @override
  void dispose() {
    _reverseTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  LatLng get _latLng => LatLng(_location.latitude, _location.longitude);

  void _notify(String message, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  /// Ajuste la sélection : le pin est fixe au centre, la carte est déplacée.
  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!_mapReady) return;

    final center = camera.center;
    if (center.latitude == _location.latitude &&
        center.longitude == _location.longitude) {
      return;
    }

    setState(() => _location = GeoPoint(center.latitude, center.longitude));

    // Pendant un déplacement manuel : adresse rafraîchie une fois le geste fini.
    if (hasGesture) {
      _reverseTimer?.cancel();
      _reverseTimer = Timer(_reverseDebounce, () => _resolveAddress(_latLng));
    }
  }

  void _moveTo(LatLng point) {
    if (!_mapReady) return;
    _mapController.animatedMove(
      vsync: this,
      destLocation: point,
      destZoom: _selectionZoom,
      duration: _animationDuration,
    );
  }

  /// Geocoding inverse : complète l'adresse sans bloquer la carte.
  Future<void> _resolveAddress(LatLng point) async {
    if (!mounted) return;
    _lastAddressRequest = point;

    try {
      final label = await ref.read(geocodingServiceProvider).reverse(point);
      if (!mounted || label == null) return;

      // Une demande plus récente est passée entre-temps : on ignore celle-ci.
      final request = _lastAddressRequest;
      if (request == null ||
          request.latitude != point.latitude ||
          request.longitude != point.longitude) {
        return;
      }
      setState(() => _address = label);
    } catch (e) {
      Log.warning('Adresse introuvable pour $point: $e');
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);

    try {
      final results = await ref.read(geocodingServiceProvider).search(query);
      if (!mounted) return;
      setState(() => _results = results);
      if (results.isEmpty) {
        _notify(
          'Aucun lieu trouvé pour « $query ».',
          ToastificationType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Log.warning('Recherche de lieu impossible: $e');
      setState(() => _results = const []);
      _notify(
        'Recherche indisponible. Vérifiez votre connexion.',
        ToastificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectResult(GeocodingResult result) {
    setState(() {
      _results = const [];
      _address = result.label;
      _location = GeoPoint(result.latitude, result.longitude);
    });
    _searchController.text = result.label;
    FocusScope.of(context).unfocus();
    _moveTo(result.point);
  }

  /// « Utiliser / actualiser ma position actuelle » : nouvelle position GPS à
  /// chaque appel (aucune position en cache).
  Future<void> _useCurrentPosition() async {
    setState(() => _isLocating = true);

    try {
      final position = await ref
          .read(locationRepositoryProvider)
          .currentPosition();
      if (!mounted) return;

      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _location = GeoPoint(point.latitude, point.longitude);
        _hasGpsFix = true;
      });
      _moveTo(point);
      await _resolveAddress(point);

      if (mounted) {
        _notify('Position GPS récupérée.', ToastificationType.success);
      }
    } catch (e) {
      if (!mounted) return;
      // LocationService remonte déjà des messages compréhensibles.
      Log.warning('Position GPS indisponible: $e');
      _notify(
        e is String ? e : 'Impossible de récupérer la position GPS.',
        ToastificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _confirm() {
    context.router.pop(
      ShelterLocationSelection(location: _location, address: _address),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Localisation du refuge')),
      body: Stack(
        children: [
          // Même fond de carte que la carte principale (OpenStreetMap).
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _latLng,
              initialZoom: widget.initialLocation == null
                  ? _defaultZoom
                  : _selectionZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              onMapReady: () => setState(() => _mapReady = true),
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.salus.app',
              ),
            ],
          ),

          // Pin fixe au centre de la carte.
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: const Icon(
                    Icons.location_on,
                    size: 44,
                    color: AppColors.sos,
                  ),
                ),
              ),
            ),
          ),

          _buildSearchField(),
          _buildBottomCard(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppColors.surface,
            elevation: 4,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12, right: 4),
                  child: Icon(Icons.search, color: AppColors.inactive),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un lieu',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    onPressed: _search,
                    color: AppColors.primary,
                    icon: const Icon(Icons.arrow_forward),
                  ),
              ],
            ),
          ),
          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: Card(
                color: AppColors.surface,
                elevation: 4,
                margin: const EdgeInsets.only(top: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final result in _results)
                        ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.place_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            result.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectResult(result),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: SafeArea(
        top: false,
        child: Card(
          color: AppColors.surface,
          elevation: 4,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _address ?? 'Position sélectionnée sur la carte',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Latitude ${_location.latitude.toStringAsFixed(5)}, '
                  'longitude ${_location.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: AppColors.inactive,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLocating ? null : _useCurrentPosition,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _hasGpsFix
                        ? 'Actualiser ma position'
                        : 'Utiliser ma position actuelle',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _confirm,
                  child: const Text('Confirmer la localisation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
