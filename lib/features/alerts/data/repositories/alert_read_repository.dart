/// Mémorise quelles alertes l'utilisateur a déjà lues (état propre à l'appareil).
abstract class AlertReadRepository {
  Future<Set<String>> getReadIds();
  Future<void> saveReadIds(Set<String> ids);
}