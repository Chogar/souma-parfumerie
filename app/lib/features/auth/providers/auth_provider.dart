import 'package:flutter/foundation.dart';
import 'package:souma_parfumerie/core/models/user_model.dart';
import 'package:souma_parfumerie/features/auth/data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _repository.login(username, password);
      if (_user == null) {
        _error = 'loginError';
      }
    } catch (e) {
      _error = 'errorGeneric';
      debugPrint('Login error: $e');
    }

    _loading = false;
    notifyListeners();
    return _user != null;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
