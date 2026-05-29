import 'package:postgres/postgres.dart';
import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/models/cart_line.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:souma_parfumerie/core/utils/barcode_utils.dart';
import 'package:uuid/uuid.dart';

class PosRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  Future<List<ProductModel>> listProductsForPos({String? query}) async {
    var sql = '''
      SELECT p.*, COALESCE(s.quantity, 0) AS quantity
      FROM products p
      LEFT JOIN stock_levels s ON s.product_id = p.id
      WHERE p.is_active = TRUE
        AND (p.expires_at IS NULL OR p.expires_at >= CURRENT_DATE)
    ''';
    final params = <String, dynamic>{};
    final q = query != null ? BarcodeUtils.normalize(query) : '';
    if (q.isNotEmpty) {
      params['exact'] = q;
      sql += '''
        AND (
          TRIM(COALESCE(p.barcode, '')) = @exact
          OR p.barcode ILIKE @q OR p.name_fr ILIKE @q OR p.name_ar ILIKE @q
          OR COALESCE(p.brand, '') ILIKE @q
        )
      ''';
      params['q'] = '%$q%';
    }
    sql += '''
      ORDER BY
        CASE WHEN COALESCE(s.quantity, 0) > 0 THEN 0 ELSE 1 END,
        p.name_fr ASC
      LIMIT 200
    ''';
    final rows = await _db.query(sql, parameters: params.isEmpty ? null : params);
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<ProductModel?> findByBarcode(String barcode) async {
    final normalized = BarcodeUtils.normalize(barcode);
    if (normalized.isEmpty) return null;

    for (final code in BarcodeUtils.variants(normalized)) {
      final row = await _db.queryOne(
        '''
        SELECT p.*, COALESCE(s.quantity, 0) AS quantity
        FROM products p
        LEFT JOIN stock_levels s ON s.product_id = p.id
        WHERE TRIM(COALESCE(p.barcode, '')) = @barcode
          AND p.is_active = TRUE
          AND (p.expires_at IS NULL OR p.expires_at >= CURRENT_DATE)
        ''',
        parameters: {'barcode': code},
      );
      if (row != null) return ProductModel.fromMap(row);
    }
    return null;
  }

  /// Produit trouvé par code-barres mais périmé (message caisse).
  Future<ProductModel?> findByBarcodeAllowExpired(String barcode) async {
    final normalized = BarcodeUtils.normalize(barcode);
    if (normalized.isEmpty) return null;

    for (final code in BarcodeUtils.variants(normalized)) {
      final row = await _db.queryOne(
        '''
        SELECT p.*, COALESCE(s.quantity, 0) AS quantity
        FROM products p
        LEFT JOIN stock_levels s ON s.product_id = p.id
        WHERE TRIM(COALESCE(p.barcode, '')) = @barcode
          AND p.is_active = TRUE
        ''',
        parameters: {'barcode': code},
      );
      if (row != null) return ProductModel.fromMap(row);
    }
    return null;
  }

  Future<({String invoiceNumber, String? clientId})> completeSale({
    required String userId,
    required List<CartLine> lines,
    required double subtotal,
    required double discountAmount,
    required double discountPercent,
    required double total,
    required String paymentMethod,
    required double amountPaid,
    required double changeGiven,
    String? clientPhone,
  }) async {
    final saleId = _uuid.v4();
    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

    return _db.runTx((tx) async {
      String? clientId;
      if (clientPhone != null && clientPhone.isNotEmpty) {
        final existing = await tx.execute(
          Sql.named('SELECT id FROM clients WHERE phone = @phone'),
          parameters: {'phone': clientPhone},
        );
        if (existing.isNotEmpty) {
          clientId = existing.first.first as String;
        } else {
          clientId = _uuid.v4();
          await tx.execute(
            Sql.named(
              'INSERT INTO clients (id, phone, loyalty_points, is_synced) VALUES (@id, @phone, 0, FALSE)',
            ),
            parameters: {'id': clientId, 'phone': clientPhone},
          );
        }
      }

      await tx.execute(
        Sql.named('''
          INSERT INTO sales (
            id, invoice_number, user_id, client_id,
            subtotal, discount_amount, discount_percent, total,
            payment_method, amount_paid, change_given, status, is_synced
          ) VALUES (
            @id, @invoice, @user_id, @client_id,
            @subtotal, @discount_amount, @discount_percent, @total,
            @payment_method, @amount_paid, @change_given, 'completed', FALSE
          )
        '''),
        parameters: {
          'id': saleId,
          'invoice': invoiceNumber,
          'user_id': userId,
          'client_id': clientId,
          'subtotal': subtotal,
          'discount_amount': discountAmount,
          'discount_percent': discountPercent,
          'total': total,
          'payment_method': paymentMethod,
          'amount_paid': amountPaid,
          'change_given': changeGiven,
        },
      );

      for (final line in lines) {
        final lineId = _uuid.v4();
        await tx.execute(
          Sql.named('''
            INSERT INTO sale_lines (id, sale_id, product_id, quantity, unit_price, line_total, is_synced)
            VALUES (@id, @sale_id, @product_id, @qty, @price, @total, FALSE)
          '''),
          parameters: {
            'id': lineId,
            'sale_id': saleId,
            'product_id': line.product.id,
            'qty': line.quantity,
            'price': line.product.salePrice,
            'total': line.lineTotal,
          },
        );

        await tx.execute(
          Sql.named('''
            INSERT INTO stock_movements (
              id, product_id, movement_type, quantity_delta,
              reference_type, reference_id, user_id, is_synced
            ) VALUES (
              @id, @product_id, 'sale', @delta,
              'sale', @sale_id, @user_id, FALSE
            )
          '''),
          parameters: {
            'id': _uuid.v4(),
            'product_id': line.product.id,
            'delta': -line.quantity,
            'sale_id': saleId,
            'user_id': userId,
          },
        );

        final updated = await tx.execute(
          Sql.named('''
            UPDATE stock_levels SET
              quantity = GREATEST(0, quantity - @deduct),
              updated_at = NOW(),
              is_synced = FALSE
            WHERE product_id = @product_id
          '''),
          parameters: {
            'product_id': line.product.id,
            'deduct': line.quantity,
          },
        );
        if (updated.affectedRows == 0) {
          await tx.execute(
            Sql.named('''
              INSERT INTO stock_levels (id, product_id, quantity, is_synced)
              VALUES (@id, @product_id, GREATEST(0, @qty), FALSE)
            '''),
            parameters: {
              'id': _uuid.v4(),
              'product_id': line.product.id,
              'qty': -line.quantity,
            },
          );
        }
      }

      return (invoiceNumber: invoiceNumber, clientId: clientId);
    });
  }
}
