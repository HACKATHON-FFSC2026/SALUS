# salus

# PARCOURS
PARCOURS CITOYEN :
- SANS CONNEXION :
  - Accéder aux informations publiques (carte, alertes, zones safe/risque, contacts d'urgence)
  - GUIDE EN CAS D'URGENCE
- AVEC CONNEXION :
  - ESPACE IA (CTA , CHAT, VOCAL)
  - ITINERAIRES ZONES SECURES
  - Accéder aux informations publiques
  - PERSONNE DETRESS EN COURS
  - SUGGESTIONS DE REFUGE
  - REPONDRE A UN DETRESSE
  - BOUTONS DE SOS (ENVOYER UN MESSAGE DE DETRESSE)

PARCOURS GESTIONNAIRE REFUGE :
- CREER UN REFUGE
- ACCEDER AUX DONNEES DES REFUGES
- CHANGER LE STATUS D'UN REFUGE

PARCOURS ORGANISATION :
- VISUALISER LA CARTE/LISTE AVEC INFORMATIONS (DETRESSES, ZONES SAFE/RISQUE)
- GERER UNE ZONE SAFE/RISQUE 
- REPONDRE A UN DETRESSE

PARCOURS ADMINISTRATEUR :
- GERER LES ORGANISATIONS
- GERER LES REFUGES
- GERER LES UTILISATEURS

# PORTAIL WEB ÉQUIPES
Le même projet Flutter fournit le portail web. Enregistrer d’abord une application Web
dans Firebase puis générer sa configuration (`flutterfire configure --platforms=web`);
`lib/firebase_options.dart` ne contient actuellement que la configuration Android.
Après connexion Google, le portail lit le profil `users/{uid}` : seuls les comptes actifs
portant le rôle `admin`, `organizationMember` ou `shelterManager` y accèdent. Attribuer
les rôles et `organizationId` depuis un environnement d’administration de confiance ;
ne jamais donner au client le droit de s’attribuer son propre rôle.

- `admin` : tableau de bord, vérification des organisations, création d’organisation,
  validation de refuges, activation/désactivation de comptes et suivi des SOS.
- `organizationMember` / `shelterManager` : file SOS, signalements et activation des
  zones qu’ils ont créées.

Les règles Firestore du dépôt autorisent les opérations correspondantes aux rôles.
Les règles doivent être déployées avec `firebase deploy --only firestore:rules` avant
de publier le portail.
