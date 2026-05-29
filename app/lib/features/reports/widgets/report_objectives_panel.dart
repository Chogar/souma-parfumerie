import 'package:flutter/material.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Objectifs du module rapports (CDC §5.10).
class ReportObjectivesPanel extends StatelessWidget {
  const ReportObjectivesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = l10n.reportObjectives.split('\n');

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.flag_outlined, color: AppTheme.accent),
        title: Text(
          l10n.reportObjectivesTitle,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          l10n.reportObjectivesSubtitle,
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in items)
                  if (line.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              line.trim().replaceFirst(RegExp(r'^•\s*'), ''),
                              style: const TextStyle(fontSize: 13, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
