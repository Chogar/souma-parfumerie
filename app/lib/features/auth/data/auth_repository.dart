import 'package:bcrypt/bcrypt.dart';
import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/models/user_model.dart';
import 'package:uuid/uuid.dart';

class AuthRepository {
  final _db = DatabaseService.instance;

  Future<UserModel?> login(String username, String password) async {
    final row = await _db.queryOne(
      '''
      SELECT u.*, r.code AS role_code, r.label_fr, r.label_ar
      FROM users u
      JOIN roles r ON r.id = u.role_id
      WHERE u.username = @username AND u.is_active = TRUE
      LIMIT 1
      ''',
      parameters: {'username': username},
    );
    if (row == null) return null;

    final hash = row['password_hash'] as String;
    if (!BCrypt.checkpw(password, hash)) return null;

    await _db.execute(
      'UPDATE users SET last_login_at = NOW() WHERE id = @id',
      parameters: {'id': row['id']},
    );

    await _logAudit(row['id'] as String, 'login_success');
    return UserModel.fromMap(row);
  }

  Future<void> _logAudit(String userId, String action) async {
    const uuid = Uuid();
    await _db.execute(
      '''
      INSERT INTO audit_logs (id, user_id, action, entity)
      VALUES (@id, @user_id, @action, 'users')
      ''',
      parameters: {
        'id': uuid.v4(),
        'user_id': userId,
        'action': action,
      },
    );
  }
}
