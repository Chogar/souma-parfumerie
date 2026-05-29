import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:uuid/uuid.dart';

class UsersRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  Future<List<Map<String, dynamic>>> list() async {
    return _db.query(
      '''
      SELECT u.id, u.username, u.full_name, u.is_active,
             r.code AS role_code, r.label_fr,
             COALESCE(u.permissions, '{}'::jsonb) AS permissions
      FROM users u
      JOIN roles r ON r.id = u.role_id
      ORDER BY u.full_name
      ''',
    );
  }

  Future<String> roleIdByCode(String code) async {
    final row = await _db.queryOne(
      'SELECT id FROM roles WHERE code = @code',
      parameters: {'code': code},
    );
    return row!['id'] as String;
  }

  Future<void> createUser({
    required String username,
    required String password,
    required String fullName,
    required String roleCode,
    Map<String, dynamic>? permissions,
  }) async {
    final roleId = await roleIdByCode(roleCode);
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    await _db.execute(
      '''
      INSERT INTO users (id, role_id, username, password_hash, full_name, permissions, is_synced)
      VALUES (@id, @role, @user, @hash, @name, @perms::jsonb, FALSE)
      ''',
      parameters: {
        'id': _uuid.v4(),
        'role': roleId,
        'user': username,
        'hash': hash,
        'name': fullName,
        'perms': jsonEncode(permissions ?? {}),
      },
    );
  }

  Future<void> updateUser({
    required String id,
    required String fullName,
    required String roleCode,
    String? password,
    Map<String, dynamic>? permissions,
  }) async {
    final roleId = await roleIdByCode(roleCode);
    final params = <String, dynamic>{
      'id': id,
      'name': fullName,
      'role': roleId,
      'perms': jsonEncode(permissions ?? {}),
    };
    var sql = '''
      UPDATE users SET
        full_name = @name, role_id = @role, permissions = @perms::jsonb,
        is_synced = FALSE, updated_at = NOW()
    ''';
    if (password != null && password.isNotEmpty) {
      sql += ', password_hash = @hash';
      params['hash'] = BCrypt.hashpw(password, BCrypt.gensalt());
    }
    sql += ' WHERE id = @id';
    await _db.execute(sql, parameters: params);
  }

  Future<void> setActive(String userId, bool active) async {
    await _db.execute(
      'UPDATE users SET is_active = @active, is_synced = FALSE WHERE id = @id',
      parameters: {'id': userId, 'active': active},
    );
  }

  Future<int> salesCountForUser(String userId) async {
    final row = await _db.queryOne(
      'SELECT COUNT(*)::int AS c FROM sales WHERE user_id = @id',
      parameters: {'id': userId},
    );
    return (row?['c'] as int?) ?? int.tryParse('${row?['c']}') ?? 0;
  }

  /// Suppression définitive (gestionnaire sans ventes liées).
  Future<void> deleteUser(String userId) async {
    final sales = await salesCountForUser(userId);
    if (sales > 0) {
      throw Exception('USER_HAS_SALES');
    }
    await _db.execute('DELETE FROM users WHERE id = @id', parameters: {'id': userId});
  }
}
