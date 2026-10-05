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

  /// 112 : numéro d'urgence européen, joignable sur tout réseau GSM.
  static const universal = '112';

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

  /// Codes ISO 3166-1 alpha-2 vers une entrée de [byCountry].
  /// Mayotte (YT) dépend de la liste France.
  static const _byCountryCode = <String, String>{
    'MG': 'Madagascar',
    'FR': 'France',
    'RE': 'Réunion',
    'YT': 'France',
  };

  /// Numéros pour un code pays d'appareil. `null` si le pays est inconnu,
  /// pour laisser l'appelant choisir un repli explicite.
  static EmergencyNumbers? forCountryCode(String? code) {
    final country = code == null ? null : _byCountryCode[code.toUpperCase()];
    return country == null ? null : byCountry[country];
  }

  /// Le repli sur 112 si le pays n'est pas connu: c'est le seul numéro qui
  /// redirige correctement à l'international.
  static EmergencyNumbers forCountry(String? country) {
    if (country != null) {
      for (final entry in byCountry.entries) {
        if (entry.key.toLowerCase() == country.toLowerCase()) {
          return entry.value;
        }
      }
    }
    return const EmergencyNumbers(police: universal, fire: universal);
  }

  /// Numéros à afficher, service + numéro, 112 ajouté s'il n'est pas déjà
  /// couvert. Le libellé porte le service pour qu'on sache où on appelle.
  List<(String, String)> get labelledEntries => [
        ('Police', police),
        ('Pompiers', fire),
        if (ambulance != null) ('SAMU', ambulance!),
        if (police != universal && fire != universal)
          ('Urgences', universal),
      ];
}