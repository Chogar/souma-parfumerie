import 'package:flutter/material.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';

/// En-tête boutique pour écrans (facture, etc.).
class StoreInfoHeader extends StatelessWidget {
  const StoreInfoHeader({
    super.key,
    required this.store,
    required this.locale,
  });

  final StoreSettings store;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isAr = locale.startsWith('ar');
    final name = store.displayName(locale);
    final slogan = store.displaySlogan(locale);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          if (slogan != null) ...[
            const SizedBox(height: 4),
            Text(
              slogan,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
          if (store.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            _line(Icons.location_on_outlined, store.address),
          ],
          if (store.phone.isNotEmpty)
            _line(Icons.phone_outlined, store.phone),
          if (store.email.isNotEmpty)
            _line(Icons.email_outlined, store.email),
          if (store.openingHours.isNotEmpty)
            _line(
              Icons.schedule,
              '${isAr ? 'ساعات العمل' : 'Horaires'} : ${store.openingHours}',
            ),
          if (store.legalInfo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              store.legalInfo,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
