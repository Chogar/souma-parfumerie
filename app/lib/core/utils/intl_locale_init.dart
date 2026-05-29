import 'package:intl/date_symbol_data_local.dart';

/// Initialise les formats de date localisés (requis pour `DateFormat(..., 'fr_FR')`).
class IntlLocaleInit {
  static bool _done = false;

  static Future<void> ensureFrench() async {
    if (_done) return;
    await initializeDateFormatting('fr_FR', null);
    _done = true;
  }
}
