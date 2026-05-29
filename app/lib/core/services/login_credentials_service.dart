import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mémorisation optionnelle de l'identifiant (et mot de passe) à la connexion.
class LoginCredentialsService {
  static const _rememberKey = 'remember_login';
  static const _usernameKey = 'saved_username';
  static const _passwordKey = 'saved_password';

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    mOptions: MacOsOptions(),
    wOptions: WindowsOptions(),
  );

  Future<bool> isRememberEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberKey) ?? false;
  }

  Future<({String? username, String? password})> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_rememberKey) ?? false)) {
      return (username: null, password: null);
    }
    final username = prefs.getString(_usernameKey);
    final password = await _secure.read(key: _passwordKey);
    return (username: username, password: password);
  }

  Future<void> save({
    required String username,
    required String password,
    required bool remember,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, remember);
    if (remember) {
      await prefs.setString(_usernameKey, username.trim());
      await _secure.write(key: _passwordKey, value: password);
    } else {
      await prefs.remove(_usernameKey);
      await _secure.delete(key: _passwordKey);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, false);
    await prefs.remove(_usernameKey);
    await _secure.delete(key: _passwordKey);
  }
}
