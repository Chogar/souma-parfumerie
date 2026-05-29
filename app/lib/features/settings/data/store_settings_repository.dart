import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:uuid/uuid.dart';

class StoreSettingsRepository {
  final _db = DatabaseService.instance;
  static const _key = 'store';
  static const _uuid = Uuid();

  Future<StoreSettings> load() async {
    try {
      final row = await _db.queryOne(
        'SELECT value FROM app_settings WHERE key = @key',
        parameters: {'key': _key},
      );
      if (row == null) return StoreSettings.defaults;
      final value = row['value'];
      if (value is Map<String, dynamic>) {
        return StoreSettings.fromJson(value);
      }
      if (value is Map) {
        return StoreSettings.fromJson(Map<String, dynamic>.from(value));
      }
      return StoreSettings.defaults;
    } catch (_) {
      return StoreSettings.defaults;
    }
  }

  Future<void> save(StoreSettings settings) async {
    final json = settings.toJson();
    final existing = await _db.queryOne(
      'SELECT id FROM app_settings WHERE key = @key',
      parameters: {'key': _key},
    );

    if (existing != null) {
      await _db.execute(
        '''
        UPDATE app_settings SET value = @value::jsonb, is_synced = FALSE, updated_at = NOW()
        WHERE key = @key
        ''',
        parameters: {'key': _key, 'value': json},
      );
    } else {
      await _db.execute(
        '''
        INSERT INTO app_settings (id, key, value, is_synced)
        VALUES (@id, @key, @value::jsonb, FALSE)
        ''',
        parameters: {
          'id': _uuid.v4(),
          'key': _key,
          'value': json,
        },
      );
    }
  }
}
