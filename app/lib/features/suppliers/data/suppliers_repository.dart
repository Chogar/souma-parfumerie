import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:uuid/uuid.dart';

class SuppliersRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  Future<List<Map<String, dynamic>>> list({String? search, bool activeOnly = true}) async {
    var sql = 'SELECT * FROM suppliers WHERE 1=1';
    final params = <String, dynamic>{};
    if (activeOnly) {
      sql += ' AND is_active = TRUE';
    }
    if (search != null && search.trim().isNotEmpty) {
      sql += ' AND (name ILIKE @q OR phone ILIKE @q OR email ILIKE @q)';
      params['q'] = '%${search.trim()}%';
    }
    sql += ' ORDER BY name ASC LIMIT 300';
    return _db.query(sql, parameters: params);
  }

  Future<void> upsert({
    String? id,
    required String name,
    String? phone,
    String? email,
    String? address,
    bool isActive = true,
  }) async {
    if (id != null) {
      await _db.execute(
        '''
        UPDATE suppliers SET
          name = @name, phone = @phone, email = @email,
          address = @address, is_active = @active,
          updated_at = NOW(), is_synced = FALSE
        WHERE id = @id
        ''',
        parameters: {
          'id': id,
          'name': name.trim(),
          'phone': phone?.trim(),
          'email': email?.trim(),
          'address': address?.trim(),
          'active': isActive,
        },
      );
    } else {
      await _db.execute(
        '''
        INSERT INTO suppliers (id, name, phone, email, address, is_active, is_synced)
        VALUES (@id, @name, @phone, @email, @address, @active, FALSE)
        ''',
        parameters: {
          'id': _uuid.v4(),
          'name': name.trim(),
          'phone': phone?.trim(),
          'email': email?.trim(),
          'address': address?.trim(),
          'active': isActive,
        },
      );
    }
  }

  Future<void> deactivate(String id) async {
    await _db.execute(
      '''
      UPDATE suppliers SET is_active = FALSE, updated_at = NOW(), is_synced = FALSE
      WHERE id = @id
      ''',
      parameters: {'id': id},
    );
  }
}
