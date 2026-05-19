import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:uuid/uuid.dart';

class CatalogRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  Future<List<ProductModel>> listProducts({String? search}) async {
    var sql = '''
      SELECT p.*, COALESCE(s.quantity, 0) AS quantity
      FROM products p
      LEFT JOIN stock_levels s ON s.product_id = p.id
      WHERE p.is_active = TRUE
    ''';
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      sql +=
          " AND (p.name_fr ILIKE @q OR p.name_ar ILIKE @q OR p.barcode ILIKE @q)";
      params['q'] = '%$search%';
    }
    sql += ' ORDER BY p.name_fr ASC LIMIT 200';
    final rows = await _db.query(sql, parameters: params);
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<void> updatePrice(String productId, double salePrice) async {
    await _db.execute(
      '''
      UPDATE products
      SET sale_price = @price, is_synced = FALSE, updated_at = NOW()
      WHERE id = @id
      ''',
      parameters: {'id': productId, 'price': salePrice},
    );
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
  }) async {
    final productId = _uuid.v4();
    await _db.execute(
      '''
      INSERT INTO products (
        id, category_id, barcode, name_fr, name_ar, brand, volume_ml,
        purchase_price, sale_price, is_synced
      ) VALUES (
        @id, @cat, @barcode, @name_fr, @name_ar, @brand, @vol,
        @purchase, @sale, FALSE
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
}
