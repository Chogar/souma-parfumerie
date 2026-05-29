import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';

/// Ouvre une URL dans le navigateur par défaut (macOS, Windows, Linux).
Future<bool> openExternalUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    if (Platform.isMacOS) {
      await Process.run('open', [uri.toString()]);
      return true;
    }
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', uri.toString()],
          runInShell: true);
      return true;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [uri.toString()]);
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('openExternalUrl failed: $e');
    return false;
  }
}

Future<bool> openExperienceTechWebsite() =>
    openExternalUrl(AppConfig.experienceTechUrl);
