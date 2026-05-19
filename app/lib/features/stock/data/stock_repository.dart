import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:uuid/uuid.dart';

class StockRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  Future<List<ProductModel>> lowStockProducts() async {
    final rows = await _db.query(
      '''
      SELECT p.*, s.quantity
      FROM products p
      JOIN stock_levels s ON s.product_id = p.id
      WHERE p.is_active = TRUE AND s.quantity <= p.min_stock_level
      ORDER BY s.quantity ASC
      ''',
    );
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> recentMovements({int limit = 50}) async {
    return _db.query(
      '''
      SELECT m.*, p.name_fr, p.name_ar, p.barcode
      FROM stock_movements m
      JOIN products p ON p.id = m.product_id
      ORDER BY m.created_at DESC
      LIMIT @limit
      ''',
      parameters: {'limit': limit},
    );
  }

  Future<void> adjustStock({
    required String productId,
    required int delta,
    required String userId,
    String? note,
  }) async {
    final movementId = _uuid.v4();
    await _db.execute(
      '''
      INSERT INTO stock_movements (
        id, product_id, movement_type, quantity_delta, note, user_id, is_synced
      ) VALUES (@id, @pid, 'adjustment', @delta, @note, @uid, FALSE)
      ''',
      parameters: {
        'id': movementId,
        'pid': productId,
        'delta': delta,
        'note': note,
        'uid': userId,
      },
    );
    await _db.execute(
      '''
      INSERT INTO stock_levels (id, product_id, quantity, is_synced)
      VALUES (@id, @pid, @qty, FALSE)
      ON CONFLICT (product_id)
      DO UPDATE SET quantity = stock_levels.quantity + @delta, updated_at = NOW(), is_synced = FALSE
      ''',
      parameters: {
        'id': _uuid.v4(),
        'pid': productId,
        'qty': delta,
        'delta': delta,
      },
    );
  }
}
