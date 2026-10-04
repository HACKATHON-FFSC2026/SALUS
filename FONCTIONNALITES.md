# Fonctionnalités et fonctionnement de SALUS

Ce document décrit le comportement constaté dans le code du dépôt. Il distingue
les fonctions utilisables, les traitements partiels et les fonctions absentes.
Les actions Firestore dépendent également des règles déployées dans le projet
Firebase correspondant.

## 1. Applications et architecture

SALUS est une application Flutter mobile et web. Le mobile sert aux citoyens et
aux intervenants de terrain. Le web ouvre le portail opérationnel, dont les
écrans et les droits dépendent du rôle Firestore du compte connecté.

Le code est organisé par fonctionnalités (`auth`, `sos`, `shelters`, `risks`,
`admin`, etc.) avec des dossiers `presentation`, `domain` et `data`. Le
câblage des implémentations se trouve dans
`lib/app/di/app_dependencies.dart`. L’accès aux données est principalement
fourni par Firebase Authentication et Cloud Firestore. GDACS, Open-Meteo,
Nominatim et OpenStreetMap sont également utilisés par certaines fonctions.

**État de l’architecture :** la séparation en couches est partielle. Certains
repositories et cas d’utilisation ont des contrats de domaine, mais les
entités partagées de `lib/core/entities` utilisent encore `GeoPoint`,
`Timestamp` et des convertisseurs Firestore. Des fichiers de présentation
utilisent également des types ou erreurs Firebase, et les couches de
présentation des fonctionnalités se composent directement entre elles. Le
point de composition a été centralisé, mais plusieurs providers de
présentation importent encore `app/di`; le domaine n’est pas encore
indépendant des SDK et modèles Firebase.

## 2. Comptes, rôles et accès

### Connexion

- La connexion utilise Google et Firebase Authentication.
- Sur mobile, le mode invité est mémorisé localement. Il permet de consulter
  l’application, mais ne crée pas d’identité Firebase et ne peut pas effectuer
  les écritures qui exigent un compte.
- Sur le web, une connexion Google ouvre le portail. Celui-ci vérifie ensuite
  le profil `users/{uid}` et refuse l’accès aux comptes inactifs ou qui n’ont
  pas un rôle autorisé.
- À la première synchronisation, un nouveau profil reçoit le rôle `citizen`.
  Les rôles et l’association à une organisation ne peuvent pas être modifiés
  par l’utilisateur lui-même.

### Rôles opérationnels

- **citizen** : consultation mobile, création de SOS et réponse communautaire
  aux SOS, sous réserve d’une session Firebase pour les écritures.
- **organizationMember** : compte utilisateur existant associé à une
  organisation active et vérifiée. Il accède au portail d’organisation et peut
  traiter les éléments affectés à cette organisation et gérer ses propres
  zones manuelles.
- **admin** : accès aux opérations globales du portail.

L’admin associe un compte utilisateur existant à une organisation depuis la
gestion des utilisateurs. Cette action conserve son rôle citoyen, ajoute
`organizationMember` et renseigne `organizationId`. Le rôle peut aussi être
retiré depuis le même écran. L’email de contact enregistré sur une fiche
d’organisation **n’est pas un compte de connexion** : l’équipe se connecte avec
son compte Google personnel autorisé par l’admin. La création d’organisation
ne crée donc ni adresse Firebase Auth ni utilisateur membre automatiquement.

Le modèle contient encore le rôle `shelterManager`, mais il n’existe pas de
parcours de connexion ou de tableau de bord dédié à ce rôle. Le parcours actif
pour les organisations utilise `organizationMember`.

## 3. Parcours mobile citoyen

### Accueil et carte

- La carte utilise les tuiles OpenStreetMap, affiche la position GPS après
  autorisation, permet de recentrer la vue et regroupe les marqueurs proches.
- La vue AR reste accessible en permanence au bas de la carte. Le recentrage
  GPS est placé en haut à droite ; le signalement routier et la légende sont
  regroupés dans le menu des actions secondaires.
- Le résumé SOS/alertes et l’avertissement d’évacuation, lorsqu’il est
  pertinent, partagent un même panneau compact en haut de la carte.
- Les refuges affichés sur la carte sont filtrés aux refuges validés.
- La carte superpose les zones à risque issues de GDACS et les zones actives
  conservées dans Firestore. Les zones sûres calculées par le client peuvent
  également être affichées.
- Une bannière compacte indique le nombre de SOS actifs et d’alertes de risque
  quand les flux correspondants sont disponibles.

### Refuges

- La liste mobile écoute la collection `shelters` et n’affiche que les refuges
  validés.
- La recommandation de proximité utilise la position connue et la distance à
  vol d’oiseau. Elle sélectionne un refuge validé, ouvert ou presque complet,
  qui dispose encore de places et qui n’est pas situé dans une zone à risque
  active connue.
- Les détails incluent adresse, capacité, statut et ressources disponibles.
- L’itinéraire est ouvert dans une application ou un site cartographique
  externe ; SALUS ne fournit pas le guidage routier lui-même.
- Le formulaire mobile recueille nom, adresse, position, capacité et ressources
  (eau, nourriture, électricité, kit médical). La localisation peut être choisie
  sur la carte, obtenue par GPS ou recherchée via Nominatim.
- Une création mobile par un compte citoyen produit une fiche `pending` au
  statut `open`. Un invité sans compte Firebase ne peut pas l’enregistrer.
- Un citoyen connecté peut signaler un problème depuis la fiche d’un refuge ;
  le signalement rejoint la file de traitement du portail.
- Depuis la carte, un citoyen connecté peut placer le signalement routier sur la
  carte ; le GPS fournit le centre initial. Les coordonnées sont enregistrées
  comme position géographique structurée et consultables par l’équipe
  opérationnelle.

### SOS et réponse à une détresse

1. L’utilisateur connecté choisit un type de détresse et maintient le bouton
   SOS pour envoyer sa position à Firestore. Le statut initial est `waiting`.
2. La personne qui a envoyé le SOS voit son état évoluer en temps réel et peut
   l’annuler. Tant que l’application fonctionne et que le GPS est accessible,
   sa position est actualisée au plus toutes les 15 secondes.
3. Les comptes connectés peuvent consulter les SOS actifs. La liste utilise la
   dernière position connue pour trier les alertes par proximité quand elle est
   disponible.
4. Un citoyen peut proposer son aide, choisir un suivi en personne ou un conseil
   texte, et mettre à jour son propre suivi (en route, arrivé ou annulé). La
   victime voit les suivis associés à son alerte.
5. Un admin peut affecter un SOS à une organisation. Le membre de cette
   organisation confirme la prise en charge (`inProgress`) puis peut le clore
   (`resolved`). Le tableau de bord affiche le statut et l’organisation
   affectée ; l’écran SOS de la victime affiche aussi l’organisation.

Le flux GPS d’un SOS est géré par l’application au premier plan. Ce dépôt ne
met pas en place un service mobile permanent garantissant le partage après
fermeture ou suspension de l’application.

La page SOS présente également des numéros d’urgence intégrés au code : 117
(police) et 118 (pompiers) à Madagascar, 15/17/18 en France et à La Réunion,
avec repli sur 112 pour un pays non répertorié.

### Alertes et aide

- Un calculateur d’alertes personnalisées selon la position et la distance
  est raccordé à l’onglet **Alertes**. Il combine les risques actifs GDACS et
  Firestore, distingue les événements dans la zone ou en rapprochement et
  conserve localement l’état lu/non lu.
- Les données GDACS sont affichées sur la carte, mais ne sont pas envoyées comme
  notifications aux téléphones par ce parcours.
- Un citoyen connecté peut signaler un problème depuis la fiche d’une zone à
  risque. Les signalements de refuges et de zones sont traités dans le portail.
- L’onglet **Aide** écoute les organisations vérifiées et actives, puis affiche
  les coordonnées de contact renseignées. Les boutons peuvent ouvrir le
  composeur téléphonique ou l’application email.

### Vue en réalité augmentée

Depuis la carte, la vue AR peut afficher dans le champ de la caméra les
refuges validés utilisables ainsi que les centres des zones à risque et des
zones sûres calculées. Elle nécessite les permissions de localisation et les
capteurs de l’appareil ; la distance d’affichage est limitée à environ 2 km.

## 4. Portail web Admin et Organisation

Le portail est accessible via la route opérations après connexion Google. Le
profil utilisateur est relu depuis Firestore. Un admin actif accède à la vue
globale ; un membre d’organisation doit également être associé à une
organisation vérifiée et active.

### Fonctions Admin

- **Vue générale** : compteurs et tableaux des dernières alertes SOS et des
  signalements à traiter.
- **Organisations** : créer et modifier une fiche (nom, type, email et téléphone
  de contact), vérifier une organisation, l’activer ou la suspendre.
- **Utilisateurs** : consulter les comptes, activer ou suspendre un compte,
  associer un membre à une organisation active et vérifiée, ou retirer cet
  accès.
- **Refuges** : consulter toutes les fiches, en créer une déjà validée, affecter
  une proposition à une organisation, et définir son statut `validated`,
  `pending` ou `rejected`. Un membre d’organisation peut actualiser le statut
  opérationnel et les places occupées de ses refuges validés.
- **SOS** : consulter les alertes, affecter ou réaffecter une organisation et
  résoudre une alerte. Chaque ligne permet d’ouvrir les détails du SOS (type,
  statut, description, nombre d’aidants, référence de la personne et dernière
  position connue sur une carte avec marqueur) puis d’ouvrir un itinéraire
  externe vers cette position.
- **Signalements** : consulter, affecter à une organisation, marquer comme
  examiné ou résolu. Les signalements routiers avec position GPS ont une action
  pour ouvrir leurs coordonnées dans une application cartographique externe.
  La liste affiche aussi une carte des incidents routiers affectés ; toucher un
  repère ouvre le détail du signalement.
- **Zones** : dessiner une zone d’alerte manuelle avec nom, message, type de
  risque, gravité et polygone ; modifier, clôturer ou réactiver les zones.

La création d’une organisation produit une fiche avec `verified: false` et
`isActive: true`. Elle doit être vérifiée avant de pouvoir accueillir un compte
membre ou apparaître dans l’annuaire public.

### Fonctions Organisation

Le portail organisation présente la vue générale ainsi que les sections SOS,
signalements, refuges et zones. Les SOS, signalements, refuges et zones sont
filtrés par l’identifiant de l’organisation. Un membre peut prendre en charge
et résoudre un SOS qui lui est affecté, traiter les signalements qui lui sont
affectés, valider ou rejeter les propositions de refuge qui lui sont affectées,
actualiser la disponibilité des refuges validés affectés et gérer les zones
manuelles de son organisation. Les règles verrouillent l’identité et
l’organisation propriétaire d’une zone. L’admin garde la gestion globale.

Les documents Firestore restent la source commune : le portail et le mobile
lisent les mêmes collections et les mises à jour de statut sont diffusées par
les flux Firestore temps réel.

## 5. Données, règles et synchronisation

Les principales collections utilisées sont `users`, `organizations`,
`shelters`, `zones`, `sos_alerts`, `help_responses`, `location_shares` et
`reports`. Les règles `firestore.rules` limitent notamment les rôles, les
affectations et les changements de statut. Les profils des utilisateurs ne
sont pas listables publiquement ; les refuges et zones ont des règles de
lecture publique ou limitée selon leur collection.

La collection `notifications` et des règles correspondantes existent dans
Firestore, mais cela ne signifie pas que l’application envoie des notifications
push. Aucune intégration FCM, permission push ou service d’envoi backend n’est
présente dans l’application décrite par ce dépôt.

## 6. Éléments incomplets ou absents

- **Notifications push FCM** : absentes. Le suivi fonctionne lorsque
  l’application lit Firestore ; aucun push ne réveille l’application.
- **Signalements routiers** : un citoyen connecté peut signaler un incident
  depuis la carte en choisissant le point concerné. Le GPS centre la carte
  initialement. Ses propres incidents non résolus sont visibles sur sa carte ;
  ceux affectés à une organisation sont visibles sur la carte du portail
  réservée à cette organisation.
- **Assistant IA, chat ou assistance vocale** : absents.
- **Escalade automatique d’un SOS vers les services d’urgence** : absente ; le
  traitement passe par les aidants et l’affectation manuelle aux organisations.
- **Connexion par email de l’organisation** : absente intentionnellement ;
  l’accès est rattaché au compte Google d’un utilisateur existant.
- **Rôle de gestionnaire de refuge dédié** : non intégré ; la disponibilité des
  refuges affectés est gérée par le rôle organisation.
- **Zones sûres** : estimation heuristique d’altitude via Open-Meteo, calculée
  côté client. Ce n’est ni une validation officielle d’évacuation, ni un
  itinéraire de secours garanti.
- **Itinéraires d’évacuation** : l’application ouvre une navigation externe
  vers le refuge ; elle écarte les destinations connues dans une zone à risque,
  mais ne calcule pas un trajet sûr évitant les risques sur le parcours routier.
  Une confirmation avertit l’utilisateur que le trajet externe n’est pas vérifié ;
  elle précise aussi si les données de risque sont indisponibles ou incomplètes.
- **Tests** : les tests Flutter présents couvrent des contrôleurs, pages,
  données SOS, carte et refuges. `firestore-tests/rules.test.mjs` couvre les
  règles via l’émulateur si sa configuration et ses dépendances sont installées.

## 7. Configuration et opérations

- La configuration FlutterFire est requise pour chaque plateforme utilisée.
- Les règles et index Firestore doivent correspondre à ceux déployés dans le
  projet Firebase ciblé. Le déploiement des règles se fait avec
  `firebase deploy --only firestore:rules` après vérification du projet actif.
- OpenStreetMap sert les fonds de carte ; Nominatim fournit la recherche et le
  géocodage inverse ; GDACS fournit les événements à risque ; Open-Meteo fournit
  les altitudes nécessaires à l’heuristique de zones sûres.
- L’accès GPS dépend des permissions et du service de localisation de l’appareil.
