import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';

class SosResponseDetailPage extends ConsumerWidget {
  final SOSAlert sosAlert;

  const SosResponseDetailPage({
    super.key,
    required this.sosAlert,
  });

  Future<void> _openMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color emeraldColor = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Intervention en cours',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: emeraldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: emeraldColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: emeraldColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Vous avez répondu à cet appel',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Suivez les consignes de sécurité ci-dessous lors de votre déplacement.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SOS Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          sosAlert.distressType.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (sosAlert.distanceInKm != null)
                        Row(
                          children: [
                            const Icon(Icons.navigation, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${sosAlert.distanceInKm!.toStringAsFixed(2)} km',
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sosAlert.description ?? 'Demande d\'assistance urgente signalée.',
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Consignes de sécurité
            const Text(
              'Consignes de sécurité :',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildSafetyInstruction('1. Assurez votre propre sécurité avant toute intervention.'),
            _buildSafetyInstruction('2. Gardez votre téléphone charged et restez joignable.'),
            _buildSafetyInstruction('3. Si la situation dégénère, prévenez immédiatement les autorités.'),

            const SizedBox(height: 32),

            // Bouton Google Maps
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openMaps(sosAlert.location.latitude, sosAlert.location.longitude),
                icon: const Icon(Icons.map_outlined, color: Colors.white),
                label: const Text(
                  'OUVRIR DANS GOOGLE MAPS',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: emeraldColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield, color: Colors.amberAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}