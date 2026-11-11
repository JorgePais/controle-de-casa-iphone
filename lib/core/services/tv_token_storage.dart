import 'package:shared_preferences/shared_preferences.dart';

/// Persists Samsung TV WebSocket tokens so the on-TV "Allow" popup
/// only appears the first time a phone connects to a given TV.
class TvTokenStorage {
  TvTokenStorage(this._prefs);

  static const String _prefix = 'tv_token::';

  final SharedPreferences _prefs;

  String? load(String identifier) {
    if (identifier.isEmpty) return null;
    return _prefs.getString('$_prefix$identifier');
  }

  Future<void> save(String identifier, String token) async {
    if (identifier.isEmpty) return;
    await _prefs.setString('$_prefix$identifier', token);
  }

  Future<void> clear(String identifier) async {
    if (identifier.isEmpty) return;
    await _prefs.remove('$_prefix$identifier');
  }

  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
