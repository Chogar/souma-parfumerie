import 'package:souma_parfumerie/core/database/database_service.dart';

class AlertsRepository {
  final _db = DatabaseService.instance;

  /// Produits dont le stock est au seuil d'alerte ou en dessous.
  Future<List<Map<String, dynamic>>> lowStock({int limit = 100}) async {
    return _db.query(
      '''
      SELECT p.id, p.barcode, p.name_fr, p.name_ar, p.min_stock_level,
             COALESCE(s.quantity, 0) AS quantity,
             p.expires_at
      FROM products p
      LEFT JOIN stock_levels s ON s.product_id = p.id
      WHERE p.is_active = TRUE
        AND COALESCE(s.quantity, 0) <= p.min_stock_level
      ORDER BY quantity ASC, p.name_fr ASC
      LIMIT @limit
      ''',
      parameters: {'limit': limit},
    );
  }

  /// Produits expirant dans [withinDays] jours (ou déjà expirés).
  Future<List<Map<String, dynamic>>> expiringSoon({int withinDays = 30}) async {
    return _db.query(
      '''
      SELECT p.id, p.barcode, p.name_fr, p.name_ar,
             COALESCE(s.quantity, 0) AS quantity,
             p.expires_at,
             (p.expires_at - CURRENT_DATE) AS days_left
      FROM products p
      LEFT JOIN stock_levels s ON s.product_id = p.id
      WHERE p.is_active = TRUE
        AND p.expires_at IS NOT NULL
        AND p.expires_at <= CURRENT_DATE + @days::int
        AND COALESCE(s.quantity, 0) > 0
      ORDER BY p.expires_at ASC
      LIMIT 100
      ''',
      parameters: {'days': withinDays},
    );
  }
}
