import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/services/session_service.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/features/auth/data/auth_repository.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class SecuritySettingsSection extends StatefulWidget {
  const SecuritySettingsSection({super.key});

  @override
  State<SecuritySettingsSection> createState() =>
      _SecuritySettingsSectionState();
}

class _SecuritySettingsSectionState extends State<SecuritySettingsSection> {
  final _authRepo = AuthRepository();
  int _sessionTimeout = 30;
  bool _totpEnabled = false;
  bool _loadingTotp = true;
  String? _setupSecret;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    _sessionTimeout = await SessionService.getTimeoutMinutes();
    _totpEnabled = await _authRepo.isTotpEnabled(userId);
    if (mounted) setState(() => _loadingTotp = false);
  }

  Future<void> _saveSessionTimeout(int? minutes) async {
    if (minutes == null) return;
    await SessionService.setTimeoutMinutes(minutes);
    setState(() => _sessionTimeout = minutes);
    if (mounted) {
      AppNotifier.success(AppLocalizations.of(context)!.save);
    }
  }

  Future<void> _startTotpSetup() async {
    final userId = context.read<AuthProvider>().user!.id;
    final secret = await _authRepo.enableTotpSetup(userId);
    if (!mounted) return;
    setState(() => _setupSecret = secret);
    await _showTotpDialog(enableMode: true, secret: secret);
  }

  Future<void> _disableTotp() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.disable2fa),
        content: Text(l10n.disable2faConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.disable2fa),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final userId = context.read<AuthProvider>().user!.id;
      await _authRepo.disableTotp(userId);
      setState(() {
        _totpEnabled = false;
        _setupSecret = null;
      });
    }
  }

  Future<void> _showTotpDialog({
    required bool enableMode,
    String? secret,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final codeCtrl = TextEditingController();
    final userId = context.read<AuthProvider>().user!.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(enableMode ? l10n.enable2fa : l10n.totpCode),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (secret != null) ...[
                Text(l10n.totpSetupHint),
                const SizedBox(height: 8),
                SelectableText(
                  secret,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.totpEnterCode),
              ],
              TextField(
                controller: codeCtrl,
                decoration: InputDecoration(labelText: l10n.totpCode),
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (ok == true && codeCtrl.text.length == 6) {
      final confirmed =
          await _authRepo.confirmTotpEnable(userId, codeCtrl.text);
      if (mounted) {
        if (confirmed) {
          AppNotifier.success(l10n.totpEnabledSuccess);
        } else {
          AppNotifier.error(l10n.totpInvalid);
        }
        if (confirmed) {
          setState(() {
            _totpEnabled = true;
            _setupSecret = null;
          });
        }
      }
    }
    codeCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.securitySettings,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _sessionTimeout,
          decoration: InputDecoration(labelText: l10n.sessionTimeout),
          items: [
            for (final m in SessionService.timeoutChoices)
              DropdownMenuItem(
                value: m,
                child: Text(
                  m == 0 ? l10n.sessionTimeoutNever : l10n.sessionTimeoutMinutes(m),
                ),
              ),
          ],
          onChanged: _saveSessionTimeout,
        ),
        const SizedBox(height: 16),
        if (_loadingTotp)
          const LinearProgressIndicator()
        else
          SwitchListTile(
            title: Text(l10n.twoFactorAuth),
            subtitle: Text(
              _totpEnabled ? l10n.totpEnabledLabel : l10n.totpDisabledLabel,
            ),
            value: _totpEnabled,
            onChanged: (v) {
              if (v) {
                _startTotpSetup();
              } else if (_totpEnabled) {
                _disableTotp();
              }
            },
          ),
        if (_setupSecret != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              onPressed: () => _showTotpDialog(
                enableMode: true,
                secret: _setupSecret,
              ),
              child: Text(l10n.totpFinishSetup),
            ),
          ),
      ],
    );
  }
}
