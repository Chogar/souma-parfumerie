import 'package:postgres/postgres.dart';
import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:uuid/uuid.dart';

class CatalogRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  Future<List<ProductModel>> listProducts({String? search}) async {
    var sql = '''
      SELECT p.*, COALESCE(s.quantity, 0) AS quantity,
             c.name_fr AS category_name_fr, c.name_ar AS category_name_ar
      FROM products p
      LEFT JOIN stock_levels s ON s.product_id = p.id
      JOIN categories c ON c.id = p.category_id
      WHERE p.is_active = TRUE
    ''';
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      sql +=
          " AND (p.name_fr ILIKE @q OR p.name_ar ILIKE @q OR p.barcode ILIKE @q)";
      params['q'] = '%$search%';
    }
    sql += ' ORDER BY p.name_fr ASC LIMIT 500';
    final rows = await _db.query(sql, parameters: params);
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<void> createProduct({
    required String categoryId,
    required String barcode,
    required String nameFr,
    required String nameAr,
    required double salePrice,
    required double purchasePrice,
    String? brand,
    int? volumeMl,
    int initialStock = 0,
    int minStockLevel = 5,
    DateTime? expiresAt,
  }) async {
    final productId = _uuid.v4();
    await _db.execute(
      '''
      INSERT INTO products (
        id, category_id, barcode, name_fr, name_ar, brand, volume_ml,
        purchase_price, sale_price, min_stock_level, expires_at, is_synced
      ) VALUES (
        @id, @cat, @barcode, @name_fr, @name_ar, @brand, @vol,
        @purchase, @sale, @min_stock, @expires, FALSE
      )
      ''',
      parameters: {
        'id': productId,
        'cat': categoryId,
        'barcode': barcode,
        'name_fr': nameFr,
        'name_ar': nameAr,
        'brand': brand,
        'vol': volumeMl,
        'purchase': purchasePrice,
        'sale': salePrice,
        'min_stock': minStockLevel,
        'expires': expiresAt,
      },
    );
    await _db.execute(
      '''
      INSERT INTO stock_levels (id, product_id, quantity, is_synced)
      VALUES (@id, @pid, @qty, FALSE)
      ''',
      parameters: {
        'id': _uuid.v4(),
        'pid': productId,
        'qty': initialStock,
      },
    );
  }

  Future<void> updateProduct({
    required String id,
    required String categoryId,
    required String barcode,
    required String nameFr,
    required String nameAr,
    required double salePrice,
    required double purchasePrice,
    String? brand,
    int? volumeMl,
    int minStockLevel = 5,
    DateTime? expiresAt,
    int? stockQuantity,
  }) async {
    await _db.execute(
      '''
      UPDATE products SET
        category_id = @cat, barcode = @barcode, name_fr = @name_fr,
        name_ar = @name_ar, brand = @brand, volume_ml = @vol,
        purchase_price = @purchase, sale_price = @sale,
        min_stock_level = @min_stock, expires_at = @expires,
        is_synced = FALSE, updated_at = NOW()
      WHERE id = @id
      ''',
      parameters: {
        'id': id,
        'cat': categoryId,
        'barcode': barcode,
        'name_fr': nameFr,
        'name_ar': nameAr,
        'brand': brand,
        'vol': volumeMl,
        'purchase': purchasePrice,
        'sale': salePrice,
        'min_stock': minStockLevel,
        'expires': expiresAt,
      },
    );
    if (stockQuantity != null) {
      await _db.execute(
        '''
        INSERT INTO stock_levels (id, product_id, quantity, is_synced)
        VALUES (@id, @pid, @qty, FALSE)
        ON CONFLICT (product_id) DO UPDATE SET
          quantity = EXCLUDED.quantity, is_synced = FALSE, updated_at = NOW()
        ''',
        parameters: {
          'id': _uuid.v4(),
          'pid': id,
          'qty': stockQuantity,
        },
      );
    }
  }

  static String resolveBarcode(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isNotEmpty) return t;
    return 'SP-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Met le stock à 0 pour un produit expiré (mouvement type loss).
  Future<void> clearExpiredStock({
    required String productId,
    required String userId,
  }) async {
    final row = await _db.queryOne(
      '''
      SELECT COALESCE(s.quantity, 0) AS quantity
      FROM products p
      LEFT JOIN stock_levels s ON s.product_id = p.id
      WHERE p.id = @id
      ''',
      parameters: {'id': productId},
    );
    final qty = row?['quantity'];
    final current = qty is int ? qty : int.tryParse(qty?.toString() ?? '') ?? 0;
    if (current <= 0) return;

    await _db.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          INSERT INTO stock_movements (
            id, product_id, movement_type, quantity_delta,
            reference_type, note, user_id, is_synced
          ) VALUES (
            @id, @pid, 'loss', @delta,
            'expired', @note, @user, FALSE
          )
        '''),
        parameters: {
          'id': _uuid.v4(),
          'pid': productId,
          'delta': -current,
          'note': 'Produit expiré retiré du stock',
          'user': userId,
        },
      );
      await tx.execute(
        Sql.named('''
          UPDATE stock_levels SET quantity = 0, is_synced = FALSE, updated_at = NOW()
          WHERE product_id = @pid
        '''),
        parameters: {'pid': productId},
      );
    });
  }

  Future<void> deactivateProduct(String id) async {
    await _db.execute(
      '''
      UPDATE products SET is_active = FALSE, is_synced = FALSE, updated_at = NOW()
      WHERE id = @id
      ''',
      parameters: {'id': id},
    );
  }
}
