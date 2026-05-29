import 'package:shared_preferences/shared_preferences.dart';

/// Délai d'inactivité avant déconnexion automatique.
class SessionService {
  static const _lastActivityKey = 'session_last_activity_ms';
  static const _timeoutKey = 'session_timeout_minutes';

  static const timeoutChoices = [15, 30, 60, 120, 0];

  static Future<int> getTimeoutMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_timeoutKey) ?? 30;
  }

  static Future<void> setTimeoutMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeoutKey, minutes);
  }

  static Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastActivityKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> clearActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);
  }

  static Future<bool> isExpired() async {
    final timeout = await getTimeoutMinutes();
    if (timeout <= 0) return false;

    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastActivityKey);
    if (last == null) return false;

    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(last),
    );
    return elapsed > Duration(minutes: timeout);
  }
}
