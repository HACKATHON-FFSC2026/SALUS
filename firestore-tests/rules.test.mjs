// Vérifie le bloc /sos_alerts de firestore.rules sur l'émulateur Firebase.
//
// Prérequis: un JDK 21+ dans le PATH ou JAVA_HOME (firebase-tools refuse les
// versions antérieures). Lancer depuis la racine du dépôt ou ce dossier:
//   npm --prefix firestore-tests test
//
// Les assertions couvrent les règles métier du SOS: qui voit quoi, qui peut
// annuler/partager/répondre, et l'impossibilité de se déclarer faux intervenant.
import assert from 'node:assert';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  getDoc,
  getDocs,
  query,
  where,
  documentId,
  GeoPoint,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';

// Les règles testées sont celles du dépôt, jamais une copie: une dérive est
// immédiatement détectée.
const RULES = readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');

const testEnv = await initializeTestEnvironment({
  projectId: 'salus-rules-check',
  firestore: { rules: RULES },
});

const VICTIM = 'victim-1';
const CITIZEN = 'citizen-2';
const RESPONDER = 'responder-3';
const ADMIN = 'admin-0';
const SUSPENDED = 'suspended-4';

const asUser = (uid) => testEnv.authenticatedContext(uid).firestore();

// Les règles `users` imposent un profil complet: on sème les comptes sans les
// règles, leur validation n'est pas ce que ce fichier teste.
await testEnv.withSecurityRulesDisabled(async (context) => {
  const db = context.firestore();
  const put = (uid, data) => setDoc(doc(db, 'users', uid), data);
  await put(VICTIM, { roles: ['citizen'], isActive: true });
  await put(CITIZEN, { roles: ['citizen'], isActive: true });
  await put(RESPONDER, {
    roles: ['organizationMember'],
    organizationId: 'org-1',
    isActive: true,
  });
  await setDoc(doc(db, 'organizations', 'org-1'), {
    verified: true,
    isActive: true,
  });
  await setDoc(doc(db, 'organizations', 'public-org'), {
    name: 'Organisation publique',
    verified: true,
    isActive: true,
  });
  await setDoc(doc(db, 'organizations', 'pending-org'), {
    name: 'Organisation en attente',
    verified: false,
    isActive: true,
  });
  await put(ADMIN, { roles: ['admin'], isActive: true });
  await put(SUSPENDED, { roles: ['organizationMember'], isActive: false });
});

const alertAt = (db, id) => doc(db, 'sos_alerts', id);

const payload = (id, overrides = {}) => ({
  id,
  userId: VICTIM,
  // GeoPoint explicite : le SDK Dart écrit un vrai `latlng`, et un objet
  // `{latitude, longitude}` se sérialiserait en map, que `is latlng` refuse.
  location: new GeoPoint(-18.8792, 47.5079),
  geoCell: '-944:2375',
  distressType: 'medical',
  description: 'Personne inconsciente',
  status: 'waiting',
  responderIds: [],
  createdAt: new Date('2026-01-01T00:00:00Z'),
  locationUpdatedAt: new Date('2026-01-01T00:00:00Z'),
  ...overrides,
});

let passed = 0;
async function ok(label, fn) {
  await assertSucceeds(Promise.resolve().then(fn));
  passed++;
  console.log(`  OK      ${label}`);
}
async function denied(label, fn) {
  await assertFails(Promise.resolve().then(fn));
  passed++;
  console.log(`  DENIED  ${label}`);
}

// ponytail: toute lecture passe par `getDocs` + `where(documentId(), ...)`
// plutôt que par `getDoc`. L'émulateur fait remonter une evaluation error
// quand une règle de lecture accède à `resource` et rend `false` — vérifié :
// `resource.data.id == 'autre'` échoue, `request.auth.uid == ...` non. Le refus
// est donc constaté sur le résultat de la requête plutôt que sur une exception,
// ce qui rend chaque assertion franchement verte ou rouge.
//
// Le filtrage par ID rend la requête équivalente à un `getDoc` pour nos
// assertions. Un résultat vide signifie « la règle a refusé » : on lève, sinon
// `denied()` validerait un document simplement absent.
async function readOne(db, collectionName, id) {
  const snap = await getDocs(
    query(collection(db, collectionName), where(documentId(), '==', id)),
  );
  if (snap.size === 0) throw new Error(`refus ou absence : ${collectionName}/${id}`);
  return snap.docs[0];
}

const readAlert = (db, id) => readOne(db, 'sos_alerts', id);

const victimDb = asUser(VICTIM);
const citizenDb = asUser(CITIZEN);
const responderDb = asUser(RESPONDER);
const adminDb = asUser(ADMIN);

const reportAt = (db, id) => doc(db, 'reports', id);
const shelterAt = (db, id) => doc(db, 'shelters', id);
const zoneAt = (db, id) => doc(db, 'zones', id);

await testEnv.withSecurityRulesDisabled(async (context) => {
  const db = context.firestore();
  await setDoc(shelterAt(db, 'managed-shelter'), {
    id: 'managed-shelter',
    name: 'Refuge géré',
    organizationId: 'org-1',
    validationStatus: 'validated',
    capacityTotal: 50,
    capacityOccupied: 10,
    status: 'open',
    updatedAt: new Date(),
  });
  await setDoc(zoneAt(db, 'org-zone'), {
    id: 'org-zone',
    type: 'risk',
    origin: 'manual',
    source: 'Alerte équipe',
    description: 'Description',
    disasterType: 'flood',
    severity: 'high',
    geometry: [
      new GeoPoint(-18.8, 47.5),
      new GeoPoint(-18.8, 47.6),
      new GeoPoint(-18.9, 47.5),
    ],
    isActive: true,
    createdBy: RESPONDER,
    organizationId: 'org-1',
    startedAt: new Date(),
  });
});

// -- reports ---------------------------------------------------------------
const REPORT = 'citizen-report';
const report = (overrides = {}) => ({
  id: REPORT,
  reporterId: CITIZEN,
  targetType: 'shelter',
  targetId: 'managed-shelter',
  reason: 'unavailable',
  description: 'Le refuge semble fermé.',
  status: 'open',
  reviewedBy: null,
  createdAt: new Date(),
  ...overrides,
});

await ok('un citoyen actif peut créer un signalement ouvert', () =>
  setDoc(reportAt(citizenDb, REPORT), report()),
);
await ok('un signalement routier inclut sa position GPS', () =>
  setDoc(
    reportAt(citizenDb, 'road-report'),
    report({
      id: 'road-report',
      targetType: 'road',
      targetId: 'Position GPS',
      targetLocation: new GeoPoint(-18.88, 47.51),
      reason: 'blocked',
    }),
  ),
);
await denied('un signalement routier sans position GPS est refuse', () =>
  setDoc(
    reportAt(citizenDb, 'road-report-no-location'),
    report({
      id: 'road-report-no-location',
      targetType: 'road',
      targetId: 'Position GPS',
      reason: 'blocked',
    }),
  ),
);
await denied('un citoyen ne signale pas au nom d’un autre', () =>
  setDoc(
    reportAt(citizenDb, 'spoofed-report'),
    report({ id: 'spoofed-report', reporterId: VICTIM }),
  ),
);
await denied('un signalement ne peut pas être créé déjà résolu', () =>
  setDoc(
    reportAt(citizenDb, 'closed-report'),
    report({ id: 'closed-report', status: 'resolved' }),
  ),
);

// -- shelter operations ----------------------------------------------------
await ok('un membre gère capacité et disponibilité de son refuge validé', () =>
  updateDoc(shelterAt(responderDb, 'managed-shelter'), {
    status: 'almostFull',
    capacityOccupied: 25,
    updatedAt: new Date(),
  }),
);
await denied('un membre ne peut pas dépasser la capacité du refuge', () =>
  updateDoc(shelterAt(responderDb, 'managed-shelter'), {
    capacityOccupied: 51,
    updatedAt: new Date(),
  }),
);
await denied('un citoyen ne gère pas la disponibilité d’un refuge', () =>
  updateDoc(shelterAt(citizenDb, 'managed-shelter'), {
    status: 'closed',
    updatedAt: new Date(),
  }),
);

// -- organization zones ----------------------------------------------------
await ok('un membre gère une zone manuelle de son organisation', () =>
  updateDoc(zoneAt(responderDb, 'org-zone'), {
    isActive: false,
    endedAt: new Date(),
  }),
);
await denied('un membre ne peut pas changer l’organisation propriétaire d’une zone', () =>
  updateDoc(zoneAt(responderDb, 'org-zone'), { organizationId: 'public-org' }),
);

// --------------------------------------------------- répertoire public Aide
const publicDb = testEnv.unauthenticatedContext().firestore();
await ok('Aide lit les organisations vérifiées et actives sans connexion', async () => {
  const result = await getDocs(
    query(
      collection(publicDb, 'organizations'),
      where('verified', '==', true),
      where('isActive', '==', true),
    ),
  );
  assert.ok(result.docs.some((organization) => organization.id === 'public-org'));
});
await denied('Aide ne lit pas toute la collection, y compris les organisations non vérifiées', () =>
  getDocs(collection(publicDb, 'organizations')),
);

// ---------------------------------------------------------------- création
await ok('la victime émet une alerte dont elle est userId', () =>
  setDoc(alertAt(victimDb, 'a1'), payload('a1')),
);
await ok('la victime relit sa propre alerte', () => readAlert(victimDb, 'a1'));
await ok('un citoyen lit une alerte active (file communautaire)', () =>
  readAlert(citizenDb, 'a1'),
);
await denied('un utilisateur non connecté ne lit rien', () =>
  readAlert(testEnv.unauthenticatedContext().firestore(), 'a1'),
);
await ok('un citoyen émet sa propre alerte', () =>
  setDoc(alertAt(citizenDb, 'a2'), payload('a2', { userId: CITIZEN })),
);
await denied('un tiers ne peut pas émettre au nom de quelqu\'un', () =>
  setDoc(alertAt(responderDb, 'a2b'), payload('a2b', { userId: VICTIM })),
);

// -------------------------------------------------- mises à jour de la victime
await ok('la victime annule', () =>
  updateDoc(alertAt(victimDb, 'a1'), { status: 'cancelled' }),
);
await denied('une alerte annulée ne se relance pas', () =>
  updateDoc(alertAt(victimDb, 'a1'), { status: 'waiting' }),
);
await denied('un citoyen ne lit plus une alerte annulée', () =>
  readAlert(citizenDb, 'a1'),
);
await ok('la victime relit toujours son alerte annulée', () =>
  readAlert(victimDb, 'a1'),
);

// a1 est annulée: on repart d'une alerte active neuve pour la suite.
await setDoc(alertAt(victimDb, 'a1b'), payload('a1b'));

await ok('la victime partage sa position', () =>
  updateDoc(alertAt(victimDb, 'a1b'), {
    location: new GeoPoint(-18.88, 47.51),
    geoCell: '-944:2376',
    locationUpdatedAt: new Date(),
  }),
);
await denied('la victime ne se résout pas elle-même', () =>
  updateDoc(alertAt(victimDb, 'a1b'), { status: 'resolved' }),
);
await denied('la victime ne réécrit pas les intervenants', () =>
  updateDoc(alertAt(victimDb, 'a1b'), { responderIds: ['x'] }),
);
await denied('la victime ne change pas userId', () =>
  updateDoc(alertAt(victimDb, 'a1b'), { userId: CITIZEN }),
);
await denied('un compte suspendu n\'agit plus', () =>
  updateDoc(alertAt(asUser(SUSPENDED), 'a1b'), { status: 'resolved' }),
);

// ------------------------------------------------- réponse d'un citoyen
await setDoc(alertAt(victimDb, 'a3'), payload('a3'));

await denied('un citoyen ne force pas inProgress', () =>
  updateDoc(alertAt(citizenDb, 'a3'), { status: 'inProgress' }),
);
await ok('un citoyen se déclare intervenant', () =>
  updateDoc(alertAt(citizenDb, 'a3'), { responderIds: [CITIZEN] }),
);
await denied('un citoyen ne forge pas un autre uid', () =>
  updateDoc(alertAt(citizenDb, 'a3'), { responderIds: [CITIZEN, VICTIM] }),
);
await ok('un intervenant se retire du registre (désistement)', () =>
  updateDoc(alertAt(citizenDb, 'a3'), { responderIds: [] }),
);
await ok('il se redéclare intervenant', () =>
  updateDoc(alertAt(citizenDb, 'a3'), { responderIds: [CITIZEN] }),
);
const a3 = await readAlert(victimDb, 'a3');
assert.deepStrictEqual(
  a3.get('responderIds'),
  [CITIZEN],
  'la liste des intervenants doit contenir exactement le citoyen, une fois',
);
passed++;
console.log('  OK      responderIds reste à [citizen-2]: ni doublon ni perte');

// ---------------------------------------------------------- aidant identifié
await setDoc(alertAt(victimDb, 'a4'), payload('a4'));
await ok('un admin affecte le SOS sans annoncer une intervention commencée', () =>
  updateDoc(alertAt(adminDb, 'a4'), {
    status: 'assigned',
    assignedOrganizationId: 'org-1',
  }),
);
await ok('l’organisation confirme la prise en charge qui lui est affectée', () =>
  updateDoc(alertAt(responderDb, 'a4'), {
    status: 'inProgress',
    assignedOrganizationId: 'org-1',
  }),
);
assert.strictEqual(
  (await readAlert(victimDb, 'a4')).get('status'),
  'inProgress',
  'la prise en charge doit persister',
);
passed++;
console.log('  OK      la prise en charge est bien enregistrée');

await ok('un aidant clôture', () =>
  updateDoc(alertAt(responderDb, 'a4'), {
    status: 'resolved',
    resolvedAt: new Date(),
  }),
);
assert.strictEqual(
  (await readAlert(victimDb, 'a4')).get('status'),
  'resolved',
  'la clôture doit persister',
);
passed++;
console.log('  OK      la clôture est bien enregistrée');

await denied('une alerte close ne se rouvre pas', () =>
  updateDoc(alertAt(responderDb, 'a4'), { status: 'inProgress' }),
);
await denied('personne ne supprime une alerte sans rôle admin', () =>
  deleteDoc(alertAt(responderDb, 'a1')),
);
await denied('la victime ne supprime pas son alerte', () =>
  deleteDoc(alertAt(victimDb, 'a1')),
);

// ------------------------------------------------------------------ lectures
await setDoc(alertAt(victimDb, 'a5'), payload('a5'));
// `create` impose `status: 'waiting'` : une alerte ne peut pas naitre close.
// a6 est donc creee active puis resolue, ce qui verifie au passage que seule
// une alerte active reapparait dans la file communautaire.
await setDoc(alertAt(victimDb, 'a6'), payload('a6'));
await updateDoc(alertAt(adminDb, 'a6'), {
  status: 'assigned',
  assignedOrganizationId: 'org-1',
});
await updateDoc(alertAt(responderDb, 'a6'), {
  status: 'inProgress',
  assignedOrganizationId: 'org-1',
});
await updateDoc(alertAt(responderDb, 'a6'), {
  status: 'resolved',
  resolvedAt: new Date('2026-01-02T00:00:00Z'),
});

const activeForResponder = await getDocs(
  query(
    collection(responderDb, 'sos_alerts'),
    where('status', 'in', ['waiting', 'inProgress']),
  ),
);
assert.deepStrictEqual(
  activeForResponder.docs.map((d) => d.id).sort(),
  ['a1b', 'a2', 'a3', 'a5'],
  'seules les alertes actives doivent ressortir',
);
passed++;
console.log('  OK      un aidant liste uniquement les alertes actives');

const citizenList = await getDocs(
  query(
    collection(citizenDb, 'sos_alerts'),
    where('status', 'in', ['waiting', 'inProgress']),
  ),
);
assert.strictEqual(
  citizenList.docs.find((d) => d.id === 'a1'),
  undefined,
  'une alerte annulée ne doit pas apparaître dans la file communautaire',
);
passed++;
console.log('  OK      un citoyen liste la file active, sans les alertes closes');

await denied('une requête sans filtre de statut est refusée', () =>
  getDocs(collection(citizenDb, 'sos_alerts')),
);
await ok('la requête réelle du client (status in + geoCell in) est acceptée', () =>
  getDocs(
    query(
      collection(citizenDb, 'sos_alerts'),
      where('status', 'in', ['waiting', 'inProgress']),
      where('geoCell', 'in', ['-944:2375', '-944:2376', '-943:2375']),
    ),
  ),
);
await ok('un admin liste tout', () =>
  getDocs(collection(asUser(ADMIN), 'sos_alerts')),
);
await ok('un admin supprime', () => deleteDoc(alertAt(asUser(ADMIN), 'a5')));

// ===========================================================================
// help_responses + location_shares
// ===========================================================================
//
// Ces deux collections portent le suivi d'intervention. Les payloads ci-dessous
// recopient ce que le datasource Dart ecrit reellement, pour que le harnais
// teste le contrat du client et pas une intention: `toJson()` a la creation,
// et une ecriture brute `{status, updatedAt}` / `{isActive, updatedAt}` au
// suivi, parce que les regles n'autorisent que `changedOnly`.
const SEER = 'citizen-5';
const STRANGER = 'user-6';

await testEnv.withSecurityRulesDisabled(async (context) => {
  const db = context.firestore();
  await setDoc(doc(db, 'users', SEER), { roles: ['citizen'], isActive: true });
  await setDoc(doc(db, 'users', STRANGER), { roles: ['citizen'], isActive: true });
});
const seerDb = asUser(SEER);
const strangerDb = asUser(STRANGER);

// -- help_responses ---------------------------------------------------------
const responseAt = (db, id) => doc(db, 'help_responses', id);
const RID = 'a3_r1'; // identifiant deterministe `${alertId}_${responderId}`

const response = (id, overrides = {}) => ({
  id,
  responderId: CITIZEN,
  sosAlertId: 'a3',
  responseType: 'comingInPerson',
  status: 'offered',
  createdAt: new Date('2026-01-01T00:00:00Z'),
  updatedAt: new Date('2026-01-01T00:00:00Z'),
  ...overrides,
});

await ok('un citoyen se declare intervenant sur une alerte active', () =>
  setDoc(responseAt(citizenDb, RID), response(RID)),
);
// Le datasource fait `docRef.get()` AVANT le `set`, pour ne pas regresser un
// suivi en cours. Sur un document inexistant `resource` est null: toute lecture
// qui touche `resource.data` doit rester evaluable, sinon le bouton
// « Je reponds » echoue en production.
await ok('lire un suivi qui n\'existe pas encore ne leve pas d\'erreur', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'help_responses', RID),
      response(RID),
    );
    await deleteDoc(doc(context.firestore(), 'help_responses', RID));
  });
  await assertSucceeds(getDoc(responseAt(citizenDb, RID)));
  // On rebat le document: les assertions suivantes le lisent.
  await setDoc(responseAt(citizenDb, RID), response(RID));
});
await ok('la victime lit les reponses a son alerte', () =>
  readOne(victimDb, 'help_responses', RID),
);
await ok('un aidant inscrit sur l\'alerte lit les reponses (role organizationMember)', () =>
  readOne(responderDb, 'help_responses', RID),
);
await denied('un tiers ne lit pas les reponses', () =>
  readOne(strangerDb, 'help_responses', RID),
);
await denied('on ne se declare pas au nom d\'un autre intervenant', () =>
  setDoc(
    responseAt(citizenDb, 'a3_r2'),
    response('a3_r2', { responderId: VICTIM }),
  ),
);
await denied('une reponse ne se cree pas deja en route', () =>
  setDoc(
    responseAt(citizenDb, 'a3_r3'),
    response('a3_r3', { id: 'a3_r3', status: 'enRoute' }),
  ),
);
await denied('un type de reponse hors nomenclature est refuse', () =>
  setDoc(
    responseAt(citizenDb, 'a3_r4'),
    response('a3_r4', { responseType: 'driveThem' }),
  ),
);
await denied('un compte suspendu ne se declare pas', () =>
  setDoc(
    responseAt(asUser(SUSPENDED), 'a3_r5'),
    response('a3_r5', { responderId: SUSPENDED }),
  ),
);

// Le suivi: ecriture brute {status, updatedAt}, ce que fait le datasource.
await ok('l\'intervenant passe en route', () =>
  updateDoc(responseAt(citizenDb, RID), {
    status: 'enRoute',
    updatedAt: new Date(),
  }),
);
await ok('l\'intervenant signale son arrivee', () =>
  updateDoc(responseAt(citizenDb, RID), {
    status: 'arrived',
    updatedAt: new Date(),
  }),
);
await ok('l\'intervenant se retracte', () =>
  updateDoc(responseAt(citizenDb, RID), {
    status: 'cancelled',
    updatedAt: new Date(),
  }),
);
assert.strictEqual((await readOne(citizenDb, 'help_responses', RID)).data().status, 'cancelled');
passed++;
console.log('  OK      le retrait laisse le document, seul status change');
await denied('le type de reponse est fige a la creation', () =>
  updateDoc(responseAt(citizenDb, RID), { responseType: 'textAdvice' }),
);
await denied('on ne vole pas le suivi d\'un autre intervenant', () =>
  updateDoc(responseAt(seerDb, RID), {
    status: 'arrived',
    updatedAt: new Date(),
  }),
);
await denied('l\'intervenant ne se remplace pas par un autre uid', () =>
  updateDoc(responseAt(citizenDb, RID), { responderId: VICTIM }),
);
await denied('l\'alertId est fige: pas de reponse orpheline', () =>
  updateDoc(responseAt(citizenDb, RID), { sosAlertId: 'a1b' }),
);

// -- location_shares --------------------------------------------------------
const shareAt = (db, id) => doc(db, 'location_shares', id);
const SHARE = 'a3_r1';
// Champs de `LocationShare` au 1:1. Pas de `createdAt`: l'entite n'en a pas,
// et le payload doit rester la copie exacte de ce que `toJson()` ecrit.
const share = (id, overrides = {}) => ({
  id,
  userId: CITIZEN,
  sosAlertId: 'a3',
  currentLocation: new GeoPoint(-18.88, 47.51),
  isActive: true,
  updatedAt: new Date('2026-01-01T00:00:00Z'),
  ...overrides,
});

await ok('l\'intervenant publie sa position', () =>
  setDoc(shareAt(citizenDb, SHARE), share(SHARE)),
);
await ok('la victime voit la position de l\'intervenant', () =>
  readOne(victimDb, 'location_shares', SHARE),
);
// Asymetrie deliberee: `help_responses` s'ouvre a tout aidant
// (`isResponder()`), mais la position GPS exacte ne sort pas de l'alerte.
await denied('un aidant non inscrit sur l\'alerte ne voit pas la position', () =>
  readOne(responderDb, 'location_shares', SHARE),
);
await denied('un tiers ne voit pas la position', () =>
  readOne(strangerDb, 'location_shares', SHARE),
);
// `joinsAsResponder` n'accepte que son propre uid, et un seul ajout par
// update: la victime ne peut inscrire personne a la main.
await denied('la victime ne peut inscrire un tiers elle-meme', () =>
  updateDoc(alertAt(victimDb, 'a3'), { responderIds: [CITIZEN, SEER] }),
);
await ok('un citoyen inscrit sur l\'alerte lit la position', async () => {
  await updateDoc(alertAt(seerDb, 'a3'), { responderIds: [CITIZEN, SEER] });
  await readOne(seerDb, 'location_shares', SHARE);
});
await ok('l\'aidant inscrit sur l\'alerte lit la position', async () => {
  await updateDoc(alertAt(responderDb, 'a3'), {
    responderIds: [CITIZEN, SEER, RESPONDER],
  });
  await readOne(responderDb, 'location_shares', SHARE);
});
await ok('lire un point jamais publie ne leve pas d\'erreur', async () => {
  await assertSucceeds(getDoc(shareAt(citizenDb, 'a3_jamais')));
});
await denied('on ne publie pas la position d\'un autre', () =>
  setDoc(shareAt(citizenDb, 'a3_r9'), share('a3_r9', { userId: VICTIM })),
);
await denied('une position sans latlng est refusee', () =>
  setDoc(
    shareAt(citizenDb, 'a3_r8'),
    share('a3_r8', { currentLocation: { lat: -18.88, lng: 47.51 } }),
  ),
);
await denied('un compte suspendu ne publie pas sa position', () =>
  setDoc(
    shareAt(asUser(SUSPENDED), 'a3_r7'),
    share('a3_r7', { userId: SUSPENDED }),
  ),
);

// Le suivi de position: seule la position bouge.
await ok('la position avance', () =>
  updateDoc(shareAt(citizenDb, SHARE), {
    currentLocation: new GeoPoint(-18.885, 47.515),
    updatedAt: new Date(),
  }),
);
await ok('l\'intervenant fige sa position en fin d\'intervention', async () => {
  await updateDoc(shareAt(citizenDb, SHARE), {
    isActive: false,
    updatedAt: new Date(),
  });
});
// `isActive: false` doit rester lisible par la victime: c'est ce qui lui
// permet de distinguer un point fige d'un point en direct.
assert.strictEqual(
  (await readOne(victimDb, 'location_shares', SHARE)).data().isActive,
  false,
  'la victime doit voir que la position est figee',
);
passed++;
console.log('  OK      la victime voit que la position est figee');
await denied('le proprietaire de la position ne change pas', () =>
  updateDoc(shareAt(citizenDb, SHARE), { userId: VICTIM }),
);
await denied('un tiers ne deplace pas la position', () =>
  updateDoc(shareAt(strangerDb, SHARE), {
    currentLocation: new GeoPoint(0, 0),
    updatedAt: new Date(),
  }),
);

await testEnv.cleanup();
console.log(`\n${passed} assertions sur firestore.rules : toutes passées.`);
