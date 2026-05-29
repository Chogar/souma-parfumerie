import 'dart:io';

import 'package:flutter/material.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/features/pos/services/receipt_print_service.dart';
import 'package:souma_parfumerie/features/settings/widgets/security_settings_section.dart';
import 'package:souma_parfumerie/features/settings/widgets/store_settings_section.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoPrint = false;
  String _printLang = 'fr';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _autoPrint = await ReceiptPrintService.isAutoPrintEnabled();
    _printLang = await ReceiptPrintService.printLanguage();
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    await ReceiptPrintService.setAutoPrint(_autoPrint);
    await ReceiptPrintService.setPrintLanguage(_printLang);
    if (mounted) {
      AppNotifier.success('Paramètres enregistrés', context: context);
    }
  }

  static String get _projectRoot =>
      '/Applications/MAMP/htdocs/Souma Parfumerie';

  Future<void> _runBackup() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final env = Map<String, String>.from(Platform.environment);
      env['DB_NAME'] = AppConfig.dbName;
      env['DB_USER'] = AppConfig.dbUser;
      env['DB_HOST'] = AppConfig.dbHost;
      env['DB_PORT'] = '${AppConfig.dbPort}';
      env['PATH'] =
          '/opt/homebrew/bin:/opt/homebrew/opt/postgresql@14/bin:'
          '/usr/local/bin:/usr/local/opt/postgresql@14/bin:'
          '${env['PATH'] ?? ''}';

      final result = await Process.run(
        'bash',
        ['scripts/backup_db.sh'],
        workingDirectory: _projectRoot,
        environment: env,
      );
      if (!mounted) return;
      if (result.exitCode == 0) {
        final out = '${result.stdout}'.trim();
        final path = out.contains(':')
            ? out.split(':').last.trim()
            : 'backups/';
        AppNotifier.success(
          '${l10n.backupDone}\n$path',
          context: context,
        );
      } else {
        final err = '${result.stderr}'.trim().isNotEmpty
            ? '${result.stderr}'.trim()
            : '${result.stdout}'.trim();
        AppNotifier.error(
          err.contains('pg_dump introuvable')
              ? l10n.backupPgDumpMissing
              : '${l10n.backupFailed}: $err',
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotifier.error('${l10n.backupFailed}: $e', context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text(l10n.settings, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const StoreSettingsSection(),
          const SizedBox(height: 24),
          Text(
            l10n.storeSettingsTechnical,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Impression automatique du reçu'),
            subtitle: const Text('À chaque validation de vente (80 mm)'),
            value: _autoPrint,
            onChanged: (v) => setState(() => _autoPrint = v),
          ),
          DropdownButtonFormField<String>(
            initialValue: _printLang,
            decoration: const InputDecoration(labelText: 'Langue des reçus'),
            items: const [
              DropdownMenuItem(value: 'fr', child: Text('Français')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
              DropdownMenuItem(
                value: 'bilingual',
                child: Text('Bilingue FR / AR'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _printLang = v);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: Text(l10n.save)),
          const Divider(height: 32),
          const SecuritySettingsSection(),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(l10n.backup),
            subtitle: Text(l10n.runBackup),
            onTap: _runBackup,
          ),
        ],
      ),
    );
  }
}
