import 'package:salus/core/entities/sos_alert_entity.dart';

class FirstAidGuideline {
  final String title;
  final List<String> steps;

  const FirstAidGuideline({
    required this.title,
    required this.steps,
  });

  static FirstAidGuideline getGuidelinesFor(DistressType type) {
    switch (type) {
      case DistressType.medical:
        return const FirstAidGuideline(
          title: 'Conseils - Urgence Médicale',
          steps: [
            'Assurez-vous que la zone est sécurisée avant d’approcher.',
            'Vérifiez la respiration et l’état de conscience de la personne.',
            'Si la personne ne respire pas, commencez le massage cardiaque si vous êtes formé.',
            'Placez la personne en Position Latérale de Sécurité (PLS) si elle est inconsciente mais respire.',
            'Ne lui donnez rien à boire ni à manger.',
          ],
        );
      case DistressType.security:
        return const FirstAidGuideline(
          title: 'Conseils - Sécurité & Agression',
          steps: [
            'Ne vous mettez pas en danger direct.',
            'Restez à une distance de sécurité si la menace est toujours présente.',
            'Essayez de repérer des témoins ou d’alerter les forces de l’ordre locales.',
            'Parlez à la victime d’une voix calme pour réduire son stress.',
          ],
        );
      case DistressType.accident:
        return const FirstAidGuideline(
          title: 'Conseils - Accident / Choc',
          steps: [
            'Baliserez la zone pour éviter un suraccident.',
            'Ne déplacez pas la victime, sauf en cas de danger imminent (incendie, explosion).',
            'Maintenez la tête et le cou de la victime immobiles.',
            'Couvrez la victime pour éviter l’hypothermie.',
          ],
        );
      case DistressType.fire:
        return const FirstAidGuideline(
          title: 'Conseils - Incendie',
          steps: [
            'Éloignez-vous et éloignez la victime des fumées toxiques.',
            'Si des vêtements brûlent, faites rouler la personne au sol.',
            'Appliquez de l’eau claire tiède sur les brûlures pendant au moins 10 minutes.',
            'N’essayez pas de retirer les vêtements collés à la peau.',
          ],
        );
      case DistressType.other:
        return const FirstAidGuideline(
          title: 'Conseils - Assistance Générale',
          steps: [
            'Gardez votre calme et rassurez la personne.',
            'Évaluez la situation et attendez les secours spécialisés si nécessaire.',
            'Restez en ligne avec la victime ou gardez le contact visuel.',
          ],
        );
    }
  }
}