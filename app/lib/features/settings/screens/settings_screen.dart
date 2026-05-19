import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/services/sync_service.dart';
import 'package:souma_parfumerie/features/pos/services/receipt_print_service.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiUrl = TextEditingController(text: AppConfig.defaultApiBaseUrl);
  bool _autoPrint = true;
  String _printLang = 'fr';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiUrl.text = prefs.getString('api_base_url') ?? AppConfig.defaultApiBaseUrl;
    _autoPrint = await ReceiptPrintService.isAutoPrintEnabled();
    _printLang = await ReceiptPrintService.printLanguage();
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _apiUrl.text.trim());
    await ReceiptPrintService.setAutoPrint(_autoPrint);
    await ReceiptPrintService.setPrintLanguage(_printLang);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres enregistrés')),
      );
    }
  }

  Future<void> _runBackup() async {
    try {
      final result = await Process.run(
        'bash',
        ['scripts/backup_db.sh'],
        workingDirectory: '/Applications/MAMP/htdocs/Souma Parfumerie',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.exitCode == 0
                  ? 'Sauvegarde créée dans backups/'
                  : 'Erreur: ${result.stderr}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sauvegarde: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _apiUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sync = context.watch<SyncService>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text(l10n.settings, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextField(
            controller: _apiUrl,
            decoration: const InputDecoration(
              labelText: 'URL API LWS',
              hintText: 'https://domaine.lws.fr/api/public',
            ),
          ),
          const SizedBox(height: 16),
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
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l10n.syncNow),
            subtitle: Text(sync.status ?? l10n.offline),
            trailing: sync.isSyncing
                ? const CircularProgressIndicator()
                : IconButton(
                    icon: const Icon(Icons.cloud_upload),
                    onPressed: () => sync.sync(),
                  ),
          ),
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
