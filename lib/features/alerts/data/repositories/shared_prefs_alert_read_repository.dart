import 'package:salus/features/alerts/data/repositories/alert_read_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
class SharedPrefsAlertReadRepository implements AlertReadRepository {
  static const _key = 'read_alert_ids';
 
  @override
  Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    // toSet() conserve l'ordre d'insertion (utile pour la purge des plus anciens).
    return (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }
 
  @override
  Future<void> saveReadIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}