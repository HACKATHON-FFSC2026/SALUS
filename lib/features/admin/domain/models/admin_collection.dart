enum AdminCollection {
  organizations('organizations'),
  shelters('shelters'),
  users('users'),
  sosAlerts('sos_alerts'),
  reports('reports'),
  zones('zones');

  const AdminCollection(this.firestoreName);

  final String firestoreName;
}
