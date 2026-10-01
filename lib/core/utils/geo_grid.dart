/// Grille géographique grossière pour « SOS à proximité ».
///
/// Firestore ne sait pas filtrer une boîte englobante sur un champ `GeoPoint`
/// (une seule plage de valeurs par champ et par requête). On stocke donc une
/// cellule textuelle dénormalisée et on requête un `whereIn` d'égalité, puis on
/// affine la distance côté client.
abstract class GeoGrid {
  /// ~2,2 km de côté. Assez fin pour une zone urbaine, assez gros pour que la
  /// liste ne contienne pas les alertes d'une autre ville.
  static const double cellSize = 0.02;

  static String cellFor(double latitude, double longitude) {
    final latCell = (latitude / cellSize).floor();
    final lngCell = (longitude / cellSize).floor();
    return '$latCell:$lngCell';
  }

  /// Cellules couvrant le carré centré sur [latitude]/[longitude].
  ///
  /// [rings] = 1 -> 3x3 cellules (~6,6 km de côté), 2 -> 5x5 (~11 km).
  static List<String> cellsAround(
    double latitude,
    double longitude, {
    int rings = 1,
  }) {
    final latCell = (latitude / cellSize).floor();
    final lngCell = (longitude / cellSize).floor();
    final cells = <String>[];
    for (var dLat = -rings; dLat <= rings; dLat++) {
      for (var dLng = -rings; dLng <= rings; dLng++) {
        cells.add('${latCell + dLat}:${lngCell + dLng}');
      }
    }
    return cells;
  }
}