import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/models/admin_zone_point.dart';

class OperationsPortalZoneEditor extends StatefulWidget {
  const OperationsPortalZoneEditor({
    super.key,
    this.zone,
    required this.onSave,
  });

  final AdminPortalRecord? zone;
  final Future<void> Function({
    required String? id,
    required String name,
    required String disasterType,
    required String severity,
    required List<AdminZonePoint> geometry,
  })
  onSave;

  @override
  State<OperationsPortalZoneEditor> createState() =>
      _OperationsPortalZoneEditorState();
}

class _OperationsPortalZoneEditorState
    extends State<OperationsPortalZoneEditor> {
  static const _defaultCenter = LatLng(-18.8792, 47.5079);
  static const _disasters = <(String, String)>[
    ('flood', 'Inondation'),
    ('cyclone', 'Cyclone'),
    ('landslide', 'Glissement de terrain'),
    ('earthquake', 'Séisme'),
    ('tsunami', 'Tsunami'),
    ('volcano', 'Éruption volcanique'),
    ('other', 'Autre'),
  ];
  static const _severities = <(String, String)>[
    ('low', 'Faible'),
    ('medium', 'Modérée'),
    ('high', 'Élevée'),
    ('critical', 'Critique'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final List<LatLng> _points;
  late String _disasterType;
  late String _severity;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.zone != null;

  @override
  void initState() {
    super.initState();
    final zone = widget.zone;
    _nameController.text = zone?.source ?? '';
    _points = [
      for (final point in zone?.geometry ?? const <AdminZonePoint>[])
        LatLng(point.latitude, point.longitude),
    ];
    _disasterType = _disasters.any((item) => item.$1 == zone?.disasterType)
        ? zone!.disasterType!
        : 'other';
    _severity = _severities.any((item) => item.$1 == zone?.severity)
        ? zone!.severity!
        : 'medium';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_points
            .map((point) => '${point.latitude},${point.longitude}')
            .toSet()
            .length <
        3) {
      setState(
        () => _error = 'Ajoutez au moins trois points distincts sur la carte.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        id: widget.zone?.id,
        name: _nameController.text.trim(),
        disasterType: _disasterType,
        severity: _severity,
        geometry: [
          for (final point in _points)
            AdminZonePoint(
              latitude: point.latitude,
              longitude: point.longitude,
            ),
        ],
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Enregistrement impossible. Vérifiez votre connexion et vos droits.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: SizedBox(
        width: math.min(size.width * .94, 980).toDouble(),
        height: math.min(size.height * .92, 780).toDouble(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Modifier la zone à risque'
                          : 'Nouvelle zone à risque',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontal = constraints.maxWidth >= 660;
                    final nameField = TextFormField(
                      controller: _nameController,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la zone',
                        hintText: 'Ex. Zone inondable près de la rivière',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Saisissez un nom.'
                          : null,
                    );
                    final disasterField = DropdownButtonFormField<String>(
                      initialValue: _disasterType,
                      decoration: const InputDecoration(
                        labelText: 'Type de risque',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final item in _disasters)
                          DropdownMenuItem(
                            value: item.$1,
                            child: Text(item.$2),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _disasterType = value!),
                    );
                    final severityField = DropdownButtonFormField<String>(
                      initialValue: _severity,
                      decoration: const InputDecoration(
                        labelText: 'Gravité',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final item in _severities)
                          DropdownMenuItem(
                            value: item.$1,
                            child: Text(item.$2),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _severity = value!),
                    );
                    return Column(
                      children: [
                        nameField,
                        const SizedBox(height: 10),
                        if (horizontal)
                          Row(
                            children: [
                              Expanded(child: disasterField),
                              const SizedBox(width: 12),
                              Expanded(child: severityField),
                            ],
                          )
                        else ...[
                          disasterField,
                          const SizedBox(height: 10),
                          severityField,
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cliquez sur la carte pour tracer le contour (3 points minimum).',
                      style: TextStyle(color: AppColors.inactive),
                    ),
                  ),
                  Text('${_points.length} points'),
                  IconButton(
                    tooltip: 'Annuler le dernier point',
                    onPressed: _points.isEmpty || _saving
                        ? null
                        : () => setState(() {
                            _points.removeLast();
                            _error = null;
                          }),
                    icon: const Icon(Icons.undo),
                  ),
                  TextButton(
                    onPressed: _points.isEmpty || _saving
                        ? null
                        : () => setState(() {
                            _points.clear();
                            _error = null;
                          }),
                    child: const Text('Effacer'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _points.isEmpty
                          ? _defaultCenter
                          : _points.first,
                      initialZoom: _points.isEmpty ? 12 : 14,
                      minZoom: 3,
                      maxZoom: 18,
                      onTap: _saving
                          ? null
                          : (_, point) => setState(() {
                              _points.add(point);
                              _error = null;
                            }),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.salus.app',
                      ),
                      if (_points.length >= 3)
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: _points,
                              color: const Color(
                                0xffc94b4b,
                              ).withValues(alpha: .22),
                              borderColor: const Color(0xffc94b4b),
                              borderStrokeWidth: 3,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < _points.length; i++)
                            Marker(
                              point: _points[i],
                              width: 28,
                              height: 28,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xffc94b4b),
                                    width: 3,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.sos)),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isEditing ? 'Enregistrer' : 'Créer la zone'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
