import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

extension MapAnimation on MapController {
  /// Anime la carte vers une nouvelle position avec un zoom spécifique.
  /// Retourne le controller : l'appelant le possède (stop/dispose), ce qui
  /// permet d'annuler une animation en cours (double-tap) et d'éviter tout
  /// `move()` après dispose de la carte.
  AnimationController animatedMove({
    required TickerProvider vsync,
    required LatLng destLocation,
    required double destZoom,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    // 1. Position et zoom de départ
    final camera = this.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: destZoom,
    );

    // 2. Création de l'AnimationController
    final controller = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    // 3. Courbe d'animation fluide (Curves.fastOutSlowIn)
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.forward();
    return controller;
  }
}
