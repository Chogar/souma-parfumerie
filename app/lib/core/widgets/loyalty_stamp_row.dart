import 'package:flutter/material.dart';
import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/core/widgets/app_logo.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Grille 2×5 des tampons fidélité (logo dans les cercles validés).
class LoyaltyStampRow extends StatelessWidget {
  const LoyaltyStampRow({
    super.key,
    required this.filled,
    this.total = LoyaltyConfig.giftThreshold,
    this.stampSize = 28,
    this.showNumbers = false,
  });

  final int filled;
  final int total;
  final double stampSize;
  final bool showNumbers;

  static const _perRow = 5;

  @override
  Widget build(BuildContext context) {
    final rows = <List<int>>[];
    for (var start = 0; start < total; start += _perRow) {
      final end = (start + _perRow).clamp(0, total);
      rows.add(List.generate(end - start, (i) => start + i));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: stampSize * 0.2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final i in rows[r])
                _Stamp(
                  checked: i < filled,
                  index: i + 1,
                  size: stampSize,
                  showNumber: showNumbers,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class LoyaltySummaryPanel extends StatelessWidget {
  const LoyaltySummaryPanel({
    super.key,
    required this.stamps,
    this.giftEligible = false,
    this.onGiftOffered,
    this.giftOfferedLoading = false,
  });

  final int stamps;
  final bool giftEligible;
  final VoidCallback? onGiftOffered;
  final bool giftOfferedLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final threshold = LoyaltyConfig.giftThreshold;
    final filled = stamps.clamp(0, threshold);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.loyalty, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.loyaltyProgramTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              Text(
                l10n.loyaltyProgress(filled, threshold),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: giftEligible ? AppTheme.accent : AppTheme.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LoyaltyStampRow(filled: filled, showNumbers: true, stampSize: 40),
          if (giftEligible) ...[
            const SizedBox(height: 8),
            Text(
              l10n.giftEligible,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
                fontSize: 12,
              ),
            ),
            if (onGiftOffered != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: giftOfferedLoading ? null : onGiftOffered,
                  icon: giftOfferedLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.redeem, size: 20),
                  label: Text(l10n.giftOffered),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ] else if (filled < threshold) ...[
            const SizedBox(height: 6),
            Text(
              l10n.loyaltyUntilGift(threshold - filled),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.checked,
    required this.index,
    required this.size,
    required this.showNumber,
  });

  final bool checked;
  final int index;
  final double size;
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? null : Colors.white,
            border: Border.all(
              color: checked ? AppTheme.accent : Colors.grey.shade400,
              width: checked ? 2 : 1,
            ),
          ),
          child: checked
              ? ClipOval(
                  child: Image.asset(
                    AppLogo.assetPath,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  ),
                )
              : null,
        ),
        if (showNumber) ...[
          const SizedBox(height: 2),
          Text(
            '$index',
            style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}
