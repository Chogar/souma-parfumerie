import 'dart:math';

import 'package:otp/otp.dart';

/// TOTP compatible Google Authenticator (RFC 6238).
class TotpService {
  static const _base32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static String generateSecret() {
    final r = Random.secure();
    return List.generate(20, (_) => _base32[r.nextInt(_base32.length)]).join();
  }

  static bool verify(String secret, String code) {
    final normalized = code.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{6}$').hasMatch(normalized)) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final window in [-1, 0, 1]) {
      final expected = OTP.generateTOTPCodeString(
        secret,
        now + window * 30000,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
        length: 6,
      );
      if (expected == normalized) return true;
    }
    return false;
  }
}
