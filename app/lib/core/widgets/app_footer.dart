import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/core/utils/external_url.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Pied de page : « Réalisé par Expérience Tech » (lien vers le site).
class AppFooter extends StatelessWidget {
  const AppFooter({super.key, this.onDarkBackground = false});

  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = onDarkBackground
        ? Colors.white.withValues(alpha: 0.75)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final linkColor = onDarkBackground ? AppTheme.accent : AppTheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: onDarkBackground
            ? Colors.black.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        border: onDarkBackground
            ? null
            : Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
      ),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontStyle: FontStyle.italic,
                ),
            children: [
              TextSpan(text: '${l10n.projectFooterPrefix} '),
              TextSpan(
                text: l10n.experienceTechLink,
                style: TextStyle(
                  color: linkColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: linkColor.withValues(alpha: 0.8),
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => openExperienceTechWebsite(),
                mouseCursor: SystemMouseCursors.click,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
