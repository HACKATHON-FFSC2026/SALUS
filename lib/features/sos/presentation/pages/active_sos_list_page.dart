import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import '../../data/repositories/sos_repository_impl.dart';
import '../providers/active_sos_provider.dart';
import 'sos_response_detail_page.dart';

class ActiveSosListPage extends ConsumerWidget {
  const ActiveSosListPage({super.key});

  Future<void> _openMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosAsync = ref.watch(activeSosStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'SOS Actifs à Proximité',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: sosAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Aucun SOS actif à proximité',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final sos = alerts[index];
              return _buildSosCard(context, ref, sos);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
        error: (err, stack) => Center(
          child: Text('Erreur: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildSosCard(BuildContext context, WidgetRef ref, SOSAlert sos) {
    final isCritical = sos.distressType == DistressType.medical || sos.distressType == DistressType.security;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCritical ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: isCritical
            ? [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Carte
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sos.distressType.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (sos.distanceInKm != null)
                Row(
                  children: [
                    const Icon(Icons.navigation, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${sos.distanceInKm!.toStringAsFixed(2)} km',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            sos.description ?? 'Demande d\'assistance urgente signalée.',
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 12),

          // Nombre d'intervenants
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline, color: Colors.indigoAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  sos.respondersCount > 0
                      ? '${sos.respondersCount} intervenant(s) en route'
                      : 'Aucun intervenant pour le moment',
                  style: TextStyle(
                    color: sos.respondersCount > 0 ? Colors.indigoAccent : Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              // Bouton Maps
              IconButton(
                onPressed: () => _openMaps(sos.location.latitude, sos.location.longitude),
                icon: const Icon(Icons.map_outlined, color: Colors.indigoAccent),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 8),

              // Bouton Je Réponds
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 1. Incrémenter le nombre d'intervenants dans Firestore
                    await ref.read(sosRepositoryProvider).respondToSos(sos.id);

                    if (context.mounted) {
                      // 2. Naviguer vers la page de conseils et de déplacement (Tâche 15)
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SosResponseDetailPage(sosAlert: sos),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  label: const Text('JE REPONDS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}