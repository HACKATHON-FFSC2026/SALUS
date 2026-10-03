/// Numéros d'urgence officiels, par pays.
///
/// Le spec exige des contacts « par pays » et non un numéro unique codé en
/// dur. Un pays non connu renvoie 112, seul numéro qui redirige correctement
/// à l'international.
class EmergencyNumbers {
  const EmergencyNumbers({
    required this.police,
    required this.fire,
    this.ambulance,
  });

  final String police;
  final String fire;
  final String? ambulance;

  static const Map<String, EmergencyNumbers> byCountry = {
    // Madagascar: 117 police, 118 pompiers.
    'Madagascar': EmergencyNumbers(police: '117', fire: '118'),
    'France': EmergencyNumbers(
      police: '17',
      fire: '18',
      ambulance: '15',
    ),
    'Réunion': EmergencyNumbers(
      police: '17',
      fire: '18',
      ambulance: '15',
    ),
  };

  /// Se replie sur 112 si le pays n'est pas connu: c'est le seul numéro qui
  /// redirige correctement à l'international.
  static EmergencyNumbers forCountry(String? country) {
    if (country != null) {
      for (final entry in byCountry.entries) {
        if (entry.key.toLowerCase() == country.toLowerCase()) {
          return entry.value;
        }
      }
    }
    return const EmergencyNumbers(police: '112', fire: '112');
  }
}