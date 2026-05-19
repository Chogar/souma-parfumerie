import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/services/sync_service.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/features/auth/data/auth_repository.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/auth/screens/login_screen.dart';
import 'package:souma_parfumerie/features/pos/data/pos_repository.dart';
import 'package:souma_parfumerie/features/pos/providers/pos_provider.dart';
import 'package:souma_parfumerie/features/shell/app_shell.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class SoumaApp extends StatelessWidget {
  const SoumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
        ChangeNotifierProvider(create: (_) => SyncService()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => PosProvider(PosRepository()),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) {
          return MaterialApp(
            title: 'SOUMAPARFUMERIE',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: locale.locale,
            supportedLocales: const [
              Locale('fr'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection:
                    locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              );
            },
            home: const _RootRouter(),
          );
        },
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    return const AppShell();
  }
}
