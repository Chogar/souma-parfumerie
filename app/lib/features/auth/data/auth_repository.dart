import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/models/user_model.dart';
import 'package:souma_parfumerie/core/security/totp_service.dart';
import 'package:souma_parfumerie/features/auth/data/login_result.dart';
import 'package:uuid/uuid.dart';

class AuthRepository {
  AuthRepository();

  final _db = DatabaseService.instance;
  static const _maxAttempts = 5;
  static const _lockMinutes = 15;

  bool? _securityColumnsReady;

  Future<bool> _hasSecurityColumns() async {
    if (_securityColumnsReady != null) return _securityColumnsReady!;
    try {
      final row = await _db.queryOne(
        '''
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'totp_enabled'
        LIMIT 1
        ''',
      );
      _securityColumnsReady = row != null;
    } catch (_) {
      _securityColumnsReady = false;
    }
    return _securityColumnsReady!;
  }

  Future<LoginResult> authenticate(String username, String password) async {
    final row = await _db.queryOne(
      '''
      SELECT u.*, r.code AS role_code, r.label_fr, r.label_ar,
             COALESCE(u.permissions, '{}'::jsonb) AS permissions
      FROM users u
      JOIN roles r ON r.id = u.role_id
      WHERE LOWER(u.username) = LOWER(@username) AND u.is_active = TRUE
      LIMIT 1
      ''',
      parameters: {'username': username},
    );
    if (row == null) return LoginResult.invalidCredentials();

    if (await _hasSecurityColumns()) {
      final lockedUntil = _parseTime(row['locked_until']);
      if (lockedUntil != null && lockedUntil.isAfter(DateTime.now())) {
        return LoginResult.accountLocked(lockedUntil);
      }
    }

    final hash = row['password_hash'] as String;
    if (!BCrypt.checkpw(password, hash)) {
      await _registerFailedAttempt(row['id'] as String);
      return LoginResult.invalidCredentials();
    }

    await _resetFailedAttempts(row['id'] as String);

    if (await _hasSecurityColumns()) {
      final totpEnabled = row['totp_enabled'] == true;
      final secret = row['totp_secret'] as String?;
      if (totpEnabled && secret != null && secret.isNotEmpty) {
        return LoginResult.needsTotp(row['id'] as String);
      }
    }

    await _finalizeLogin(row);
    return LoginResult.success(UserModel.fromMap(row));
  }

  Future<LoginResult> verifyTotpAndLogin(String userId, String code) async {
    if (!await _hasSecurityColumns()) {
      return LoginResult.invalidCredentials();
    }

    final row = await _db.queryOne(
      '''
      SELECT u.*, r.code AS role_code, r.label_fr, r.label_ar,
             COALESCE(u.permissions, '{}'::jsonb) AS permissions
      FROM users u
      JOIN roles r ON r.id = u.role_id
      WHERE u.id = @id AND u.is_active = TRUE
      ''',
      parameters: {'id': userId},
    );
    if (row == null) return LoginResult.invalidCredentials();

    final secret = row['totp_secret'] as String?;
    if (secret == null || !TotpService.verify(secret, code)) {
      return LoginResult.invalidCredentials();
    }

    await _finalizeLogin(row);
    return LoginResult.success(UserModel.fromMap(row));
  }

  Future<void> _finalizeLogin(Map<String, dynamic> row) async {
    await _db.execute(
      'UPDATE users SET last_login_at = NOW() WHERE id = @id',
      parameters: {'id': row['id']},
    );
    try {
      await _logAudit(row['id'] as String, 'login_success');
    } catch (e) {
      debugPrint('Audit login_success ignoré: $e');
    }
  }

  Future<void> _registerFailedAttempt(String userId) async {
    if (!await _hasSecurityColumns()) return;
    try {
      final row = await _db.queryOne(
        '''
        UPDATE users SET
          failed_login_attempts = failed_login_attempts + 1,
          locked_until = CASE
            WHEN failed_login_attempts + 1 >= @max
            THEN NOW() + make_interval(mins => @lock)
            ELSE locked_until
          END
        WHERE id = @id
        RETURNING failed_login_attempts, locked_until
        ''',
        parameters: {
          'id': userId,
          'max': _maxAttempts,
          'lock': _lockMinutes,
        },
      );
      if (row != null) {
        await _logAudit(userId, 'login_failed');
      }
    } catch (e) {
      debugPrint('registerFailedAttempt ignoré: $e');
    }
  }

  Future<void> _resetFailedAttempts(String userId) async {
    if (!await _hasSecurityColumns()) return;
    try {
      await _db.execute(
        '''
        UPDATE users SET failed_login_attempts = 0, locked_until = NULL
        WHERE id = @id
        ''',
        parameters: {'id': userId},
      );
    } catch (e) {
      debugPrint('resetFailedAttempts ignoré: $e');
    }
  }

  Future<bool> isTotpEnabled(String userId) async {
    if (!await _hasSecurityColumns()) return false;
    final row = await _db.queryOne(
      'SELECT totp_enabled FROM users WHERE id = @id',
      parameters: {'id': userId},
    );
    return row?['totp_enabled'] == true;
  }

  Future<String> enableTotpSetup(String userId) async {
    if (!await _hasSecurityColumns()) {
      throw StateError('Migration 004_security_2fa.sql requise');
    }
    final secret = TotpService.generateSecret();
    await _db.execute(
      '''
      UPDATE users SET totp_secret = @secret, totp_enabled = FALSE, is_synced = FALSE
      WHERE id = @id
      ''',
      parameters: {'id': userId, 'secret': secret},
    );
    return secret;
  }

  Future<bool> confirmTotpEnable(String userId, String code) async {
    if (!await _hasSecurityColumns()) return false;
    final row = await _db.queryOne(
      'SELECT totp_secret FROM users WHERE id = @id',
      parameters: {'id': userId},
    );
    final secret = row?['totp_secret'] as String?;
    if (secret == null || !TotpService.verify(secret, code)) return false;

    await _db.execute(
      '''
      UPDATE users SET totp_enabled = TRUE, is_synced = FALSE WHERE id = @id
      ''',
      parameters: {'id': userId},
    );
    return true;
  }

  Future<void> disableTotp(String userId) async {
    if (!await _hasSecurityColumns()) return;
    await _db.execute(
      '''
      UPDATE users SET totp_enabled = FALSE, totp_secret = NULL, is_synced = FALSE
      WHERE id = @id
      ''',
      parameters: {'id': userId},
    );
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

  DateTime? _parseTime(dynamic v) {
    if (v is DateTime) return v;
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
