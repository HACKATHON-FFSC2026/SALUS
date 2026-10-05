import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre un itinéraire vers un point dans une application de cartes, avec
/// repli en cascade.
///
/// Un simple appel Google Maps échoue sur un appareil sans l'application. On
/// tente successivement la navigation native, le schéma `geo:`, puis la
/// version web (application externe, onglet par défaut, navigateur in-app).
/// En dernier recours, on affiche les coordonnées pour ne laisser personne
/// sans point de repère.
Future<void> openExternalDirections(
  BuildContext context, {
  required double latitude,
  required double longitude,
  required String label,
  String travelMode = 'driving',
}) async {
  final destination = '$latitude,$longitude';
  final navigatingOnFoot = travelMode == 'walking';
  final webUri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': destination,
    'travelmode': travelMode,
  });
  final candidates = <(Uri, LaunchMode)>[
    (
      Uri(
        scheme: 'google.navigation',
        queryParameters: {'q': destination, if (navigatingOnFoot) 'mode': 'w'},
      ),
      LaunchMode.externalApplication,
    ),
    (
      Uri(
        scheme: 'geo',
        path: destination,
        queryParameters: {'q': '$destination($label)'},
      ),
      LaunchMode.externalApplication,
    ),
    (webUri, LaunchMode.externalApplication),
    (webUri, LaunchMode.platformDefault),
    (webUri, LaunchMode.inAppBrowserView),
  ];

  for (final (uri, mode) in candidates) {
    try {
      if (await launchUrl(uri, mode: mode)) return;
    } catch (_) {
      // On passe à la solution suivante.
    }
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Aucune application de cartes ne peut ouvrir cet itinéraire. '
        'Coordonnées : ${latitude.toStringAsFixed(4)}, '
        '${longitude.toStringAsFixed(4)}',
      ),
    ),
  );
}
