import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/security/permission_catalog.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Cases à cocher des droits caissier (gestionnaire).
class GestionnairePermissionsEditor extends StatelessWidget {
  const GestionnairePermissionsEditor({
    super.key,
    required this.values,
    required this.onChanged,
  });

  final Map<String, bool> values;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.permissionsTitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.permissionsSubtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        ...PermissionCatalog.entries.map((e) {
          final checked = values[e.key] ?? e.defaultGestionnaire;
          return Material(
            color: checked
                ? AppTheme.accent.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: CheckboxListTile(
              value: checked,
              onChanged: (v) => onChanged(e.key, v ?? false),
              title: Text(
                PermissionCatalog.labelFor(e.key, locale),
                style: const TextStyle(fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeColor: AppTheme.accent,
            ),
          );
        }),
      ],
    );
  }
}
