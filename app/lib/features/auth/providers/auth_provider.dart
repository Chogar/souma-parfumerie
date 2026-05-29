import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:souma_parfumerie/core/models/user_model.dart';
import 'package:souma_parfumerie/core/services/session_service.dart';
import 'package:souma_parfumerie/features/auth/data/auth_repository.dart';
import 'package:souma_parfumerie/features/auth/data/login_result.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  UserModel? _user;
  String? _pendingTotpUserId;
  bool _loading = false;
  String? _error;
  bool _sessionExpired = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get needsTotp => _pendingTotpUserId != null;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get sessionExpired => _sessionExpired;

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    _pendingTotpUserId = null;
    _sessionExpired = false;
    notifyListeners();

    try {
      final result = await _repository.authenticate(username.trim(), password);
      switch (result.type) {
        case LoginResultType.success:
          _user = result.user;
          await SessionService.recordActivity();
        case LoginResultType.needsTotp:
          _pendingTotpUserId = result.userId;
        case LoginResultType.invalidCredentials:
          _error = 'loginError';
        case LoginResultType.accountLocked:
          _error = 'accountLocked';
      }
    } on SocketException catch (e) {
      _error = 'connectionError';
      debugPrint('Login DB connection: $e');
    } catch (e) {
      debugPrint('Login error: $e');
      _error = _messageErrorKey(e.toString());
    }

    _loading = false;
    notifyListeners();
    return _user != null;
  }

  Future<bool> verifyTotp(String code) async {
    final userId = _pendingTotpUserId;
    if (userId == null) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.verifyTotpAndLogin(userId, code);
      if (result.type == LoginResultType.success) {
        _user = result.user;
        _pendingTotpUserId = null;
        await SessionService.recordActivity();
      } else {
        _error = 'totpInvalid';
      }
    } catch (e) {
      debugPrint('TOTP error: $e');
      _error = _messageErrorKey(e.toString());
    }

    _loading = false;
    notifyListeners();
    return _user != null;
  }

  void cancelTotp() {
    _pendingTotpUserId = null;
    _error = null;
    notifyListeners();
  }

  void logout({bool sessionExpired = false}) {
    _user = null;
    _pendingTotpUserId = null;
    _sessionExpired = sessionExpired;
    SessionService.clearActivity();
    notifyListeners();
  }

  void clearSessionExpiredFlag() {
    _sessionExpired = false;
  }

  String _messageErrorKey(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('connection') ||
        lower.contains('refused') ||
        lower.contains('timeout') ||
        lower.contains('08006')) {
      return 'connectionError';
    }
    if (lower.contains('totp_enabled') ||
        lower.contains('failed_login_attempts') ||
        (lower.contains('column') && lower.contains('does not exist'))) {
      return 'dbMigrationRequired';
    }
    return 'errorGeneric';
  }
}
