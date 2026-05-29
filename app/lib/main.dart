import 'dart:io';

import 'package:flutter/material.dart';
import 'package:souma_parfumerie/app.dart';
import 'package:souma_parfumerie/core/utils/intl_locale_init.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IntlLocaleInit.ensureFrench();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1024, 700),
      center: true,
      title: 'Souma Perfumery Management System',
    );
    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const SoumaApp());
}
