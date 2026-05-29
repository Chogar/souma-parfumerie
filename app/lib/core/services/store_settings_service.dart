import 'package:flutter/foundation.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:souma_parfumerie/features/settings/data/store_settings_repository.dart';

/// Paramètres boutique en mémoire (factures, rapports, tickets).
class StoreSettingsService extends ChangeNotifier {
  StoreSettingsService() : _repo = StoreSettingsRepository();

  final StoreSettingsRepository _repo;
  StoreSettings _settings = StoreSettings.defaults;
  bool _loaded = false;

  StoreSettings get settings => _settings;
  bool get isLoaded => _loaded;

  String get currencySymbol => _settings.currencySymbol;

  Future<void> load() async {
    _settings = await _repo.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(StoreSettings settings) async {
    await _repo.save(settings);
    _settings = settings;
    notifyListeners();
  }
}
