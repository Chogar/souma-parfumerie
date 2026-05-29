import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/services/store_settings_service.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/core/widgets/loyalty_stamp_row.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/features/clients/services/loyalty_card_print_service.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Carte de fidélité : 10 validations (logo dans chaque cercle validé).
class LoyaltyCardDialog extends StatefulWidget {
  const LoyaltyCardDialog({
    super.key,
    required this.client,
    required this.loyaltyPoints,
    this.onGiftOffered,
    this.onEdit,
  });

  final Map<String, dynamic> client;
  final int loyaltyPoints;

  /// Remet la carte à zéro après confirmation ; retourne true si succès.
  final Future<bool> Function()? onGiftOffered;
  final VoidCallback? onEdit;

  @override
  State<LoyaltyCardDialog> createState() => _LoyaltyCardDialogState();
}

class _LoyaltyCardDialogState extends State<LoyaltyCardDialog> {
  bool _printing = false;
  late int _points;
  late int _giftsReceived;

  @override
  void initState() {
    super.initState();
    _points = widget.loyaltyPoints;
    final g = widget.client['gifts_received'];
    if (g is int) {
      _giftsReceived = g;
    } else {
      _giftsReceived = int.tryParse(g?.toString() ?? '') ?? 0;
    }
  }

  Future<void> _printCard() async {
    if (_printing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _printing = true);
    try {
      final store = context.read<StoreSettingsService>().settings;
      final locale = context.read<LocaleProvider>().locale.languageCode;
      final result = await LoyaltyCardPrintService.printCard(
        client: widget.client,
        loyaltyPoints: _points,
        store: store,
        locale: locale,
      );
      if (!mounted) return;
      if (result.ok) {
        final pathMsg = result.path != null ? '\n${result.path}' : '';
        AppNotifier.success('${l10n.printLoyaltyCardDone}$pathMsg');
      } else {
        AppNotifier.error(l10n.printError);
      }
    } catch (e) {
      if (mounted) AppNotifier.error('${l10n.printError}: $e');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _offerGift() async {
    if (widget.onGiftOffered == null) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.giftOffered),
        content: Text(l10n.giftOfferedConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await widget.onGiftOffered!();
    if (!mounted) return;
    if (success) {
      setState(() {
        _points = 0;
        _giftsReceived++;
      });
      AppNotifier.success(l10n.giftOfferedDone);
    } else {
      AppNotifier.error(l10n.redeemGiftFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final threshold = LoyaltyConfig.giftThreshold;
    final giftDue = _points >= threshold;
    final filled = _points.clamp(0, threshold);
    final phone = widget.client['phone']?.toString() ?? '';
    final name = widget.client['name']?.toString();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.loyalty, color: AppTheme.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.loyaltyCard)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              phone,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (name != null && name.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${l10n.clientGiftsReceived}: $_giftsReceived',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.06),
                    AppTheme.accent.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.loyaltyCardSubtitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LoyaltyStampRow(
                    filled: filled,
                    stampSize: 52,
                    showNumbers: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.loyaltyProgress(filled, threshold),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: giftDue ? AppTheme.accent : AppTheme.primary,
                    ),
                  ),
                  if (giftDue) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard, color: AppTheme.accent, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.giftEligible,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.onGiftOffered != null) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _offerGift,
                          icon: const Icon(Icons.redeem, size: 22),
                          label: Text(l10n.giftOffered),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.loyaltyUntilGift(threshold - filled),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        OutlinedButton.icon(
          onPressed: _printing ? null : _printCard,
          icon: _printing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print_outlined, size: 20),
          label: Text(l10n.printLoyaltyCard),
        ),
        if (widget.onEdit != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onEdit!();
            },
            child: Text(l10n.edit),
          ),
      ],
    );
  }
}
