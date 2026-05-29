import 'package:souma_parfumerie/core/models/user_model.dart';

enum LoginResultType {
  success,
  needsTotp,
  invalidCredentials,
  accountLocked,
}

class LoginResult {
  const LoginResult._({
    required this.type,
    this.user,
    this.userId,
    this.lockedUntil,
  });

  final LoginResultType type;
  final UserModel? user;
  final String? userId;
  final DateTime? lockedUntil;

  factory LoginResult.success(UserModel user) => LoginResult._(
        type: LoginResultType.success,
        user: user,
      );

  factory LoginResult.needsTotp(String userId) => LoginResult._(
        type: LoginResultType.needsTotp,
        userId: userId,
      );

  factory LoginResult.invalidCredentials() => const LoginResult._(
        type: LoginResultType.invalidCredentials,
      );

  factory LoginResult.accountLocked(DateTime until) => LoginResult._(
        type: LoginResultType.accountLocked,
        lockedUntil: until,
      );
}
