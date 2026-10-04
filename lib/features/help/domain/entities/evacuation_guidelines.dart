import 'package:salus/core/entities/zone_entity.dart';

/// Contenu statique du mode évacuation (spec §1.1 « Guide en cas d'urgence »,
/// MUST). Aucune IA, aucune connexion : arbre de décision plat, disponible
/// hors ligne.
class EvacuationGuideline {
  final String title;
  final List<String> steps;

  const EvacuationGuideline({required this.title, required this.steps});
}

const _generale = EvacuationGuideline(
  title: 'Évacuation - Consignes générales',
  steps: [
    'Éloignez-vous du danger à pied, ne prenez pas la voiture si la voie est bloquée.',
    'Emportez eau, nourriture, lampe et une pièce d\'identité, rien de plus.',
    'Rejoignez le refuge validé le plus proche (voir l\'onglet REFUGES).',
    'Suivez les consignes locales et ne revenez qu\'après l\'all-clear officiel.',
  ],
);

const _seisme = EvacuationGuideline(
  title: 'Évacuation - Séisme',
  steps: [
    'Pendant la secousse : abritez-vous sous une table ou près d\'un mur porteur, loin des vitres.',
    'Ne descendez pas l\'escalier pendant la secousse, ne prenez pas l\'ascenseur.',
    'Après : évacuez le bâtiment à pied, par les escaliers, une fois la secousse stabilisée.',
    'Éloignez-vous des façades, fils électriques et objets tombés.',
    'Tenez compte des répliques : restez dehors jusqu\'au calme durable.',
  ],
);

const _inondation = EvacuationGuideline(
  title: 'Évacuation - Inondation',
  steps: [
    'Ne tardez pas : montez à pied dès que l\'eau progresse rapidement.',
    'Ne marchez jamais ni ne conduisez dans une eau vive : 30 cm suffisent pour emporter un adulte.',
    'Coupez l\'électricité de la maison si vous y êtes encore, sans toucher d\'appareil mouillé.',
    'Gagnez un point haut proche (étage, colline) plutôt que de traverser l\'eau au loin.',
  ],
);

const _cyclone = EvacuationGuideline(
  title: 'Évacuation - Cyclone',
  steps: [
    'Ne sortez pas au passage de l\'œil du cyclone : le vent repart souvent en sens inverse.',
    'Abritez-vous dans la pièce la plus solide, à l\'écart des ouvertures, regroupez la famille.',
    'Si l\'habitation ne tient pas : rejoignez le refuge le plus proche avant les vents destructeurs.',
    'Éloignez-vous des toitures arrachées, lignes électriques et cours d\'eau gonflés.',
    'Après : attendez l\'all-clear, le danger reste fort (débris, chutes, réseaux).',
  ],
);

const _tsunami = EvacuationGuideline(
  title: 'Évacuation - Tsunami',
  steps: [
    'Mer qui se retire ou rugissement fort : courez vers les hauteurs sans attendre l\'alerte officielle.',
    'Visez au moins 30 m d\'altitude ou 2-3 km à l\'intérieur des terres, à pied si possible.',
    'N\'allez jamais voir la vague, même si la mer paraît calme.',
    'Restez en hauteur : les vagues suivantes arrivent pendant des heures.',
  ],
);

const _glissement = EvacuationGuideline(
  title: 'Évacuation - Glissement de terrain',
  steps: [
    'Bruits sourds ou fissures qui s\'agrandissent sur la pente : partez immédiatement.',
    'Ne remontez pas la pente : écartez-vous latéralement de la coulée.',
    'Rejoignez un terrain plat et stable ou une zone rocheuse.',
  ],
);

const _volcan = EvacuationGuideline(
  title: 'Évacuation - Volcan',
  steps: [
    'Éloignez-vous des vallées : les coulées de boue y circulent plus vite qu\'on ne court.',
    'Protégez vos voies respiratoires (tissu mouillé) contre les cendres.',
    'Ne conduisez pas sous une pluie de cendres : la visibilité tombe à zéro et le moteur encrasse.',
    'Suivez le périmètre d\'exclusion et rejoignez le point de rassemblement officiel.',
  ],
);

class EvacuationGuides {
  EvacuationGuides._();

  /// Types proposés dans l'ordre d'affichage des chips (MUST du spec d'abord).
  static const List<DisasterType> orderedTypes = [
    DisasterType.earthquake,
    DisasterType.flood,
    DisasterType.cyclone,
    DisasterType.tsunami,
    DisasterType.landslide,
    DisasterType.volcano,
  ];

  static Map<DisasterType, EvacuationGuideline> get _byType => {
        DisasterType.earthquake: _seisme,
        DisasterType.flood: _inondation,
        DisasterType.cyclone: _cyclone,
        DisasterType.tsunami: _tsunami,
        DisasterType.landslide: _glissement,
        DisasterType.volcano: _volcan,
      };

  /// Guide pour un type de catastrophe ; fallback général sinon.
  static EvacuationGuideline forType(DisasterType type) =>
      _byType[type] ?? _generale;
}
