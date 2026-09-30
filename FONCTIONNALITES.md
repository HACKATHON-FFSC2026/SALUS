# Fonctionnalités de SALUS

Ce document décrit l’état actuel de l’application. Les fonctions marquées « à venir » ne sont pas encore reliées à un service opérationnel.

## Fonctionnalités implémentées

### Accès et compte

- Connexion avec Google.
- Création ou mise à jour du profil dans Firestore après la connexion.
- Accès sans compte, mémorisé localement sur l’appareil.
- La lecture et la création des refuges dans Firestore demandent une session Firebase. Le mode invité local ne donne pas cette session.

### Carte

- Carte OpenStreetMap avec affichage des refuges validés.
- Affichage de la position GPS et commande de recentrage, après autorisation.
- Regroupement des marqueurs proches en clusters.
- Légende repliable des statuts des refuges.
- Ouverture d’une fiche rapide au toucher d’un marqueur, avec accès aux détails.

### Liste des refuges

- Liste en temps réel des refuges lisibles dans Firestore, y compris les fiches en attente ou refusées.
- Badge de validation pour chaque refuge.
- Couleur de fond pastel selon la disponibilité : vert pour des places disponibles, jaune pour un refuge presque complet, rouge pour un refuge complet ou fermé.
- Fiche détaillée avec adresse, statut, validation, places disponibles et équipements renseignés.
- Recommandation du refuge validé le plus proche, ouvert ou presque complet, avec des places disponibles. Le calcul de proximité utilise la position GPS et une distance à vol d’oiseau.

### Itinéraires

- Bouton direct pour démarrer l’itinéraire depuis la carte du refuge recommandé.
- Depuis la liste, ouverture des détails d’un refuge ; l’itinéraire y est proposé si le refuge est validé, ouvert ou presque complet, et dispose de places.
- L’itinéraire piéton est transmis à une application de cartes ou à un navigateur. Le guidage en temps réel est assuré par cette application externe, pas par SALUS.

### Création d’un refuge

- Formulaire avec nom, adresse, capacité et équipements : eau, nourriture, électricité et kit médical.
- Sélection de la position sur une carte, position GPS, recherche d’adresse et géocodage inverse avec Nominatim/OpenStreetMap.
- Enregistrement dans Firestore avec validation initiale « en attente » et statut initial « ouvert ».
- Les refuges non validés ne sont pas affichés sur la carte et ne sont pas recommandés.

## Écrans présents, fonctions à venir

- **Alertes** : écran présent, sans flux d’alertes connecté.
- **Aide** : écran présent, contenu annoncé comme bientôt disponible.
- **SOS** : bouton présent, affiche un message temporaire ; aucun signal de détresse n’est envoyé.
- **Administration** : validation des refuges, gestion des utilisateurs, organisations et zones non implémentées.
- **Assistance IA, chat et réponse aux demandes de détresse** : non implémentés.

## Configuration et limites

- Firebase est configuré dans le dépôt pour Android. Les autres plateformes demandent leur configuration FlutterFire.
- Les opérations Firestore suivent les règles du fichier `firestore.rules` et nécessitent une authentification Firebase.
- La géolocalisation nécessite que le service GPS soit activé et que l’utilisateur accorde la permission.
- Le calcul de distance de recommandation est une estimation à vol d’oiseau ; le trajet routier est calculé par l’application de cartes externe.

