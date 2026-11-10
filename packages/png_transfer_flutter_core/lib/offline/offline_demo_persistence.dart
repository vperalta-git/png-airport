import 'package:shared_preferences/shared_preferences.dart';
import 'offline_demo_store.dart';

/// One atomic JSON snapshot, isolated by the .offline Android application ID.
/// Practice data only; this never stores or synchronizes operational records.
class PreferencesDemoPersistence implements OfflineDemoPersistence {
  static const key = 'aerotrans.offline.practice.v1';
  final SharedPreferencesAsync preferences;
  PreferencesDemoPersistence({SharedPreferencesAsync? preferences})
      : preferences = preferences ?? SharedPreferencesAsync();
  @override
  Future<String?> read() => preferences.getString(key);
  @override
  Future<void> write(String value) => preferences.setString(key, value);
  @override
  Future<void> clear() => preferences.remove(key);
}
