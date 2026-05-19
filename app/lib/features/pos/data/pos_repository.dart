import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/models/cart_line.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:uuid/uuid.dart';

class PosRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  Future<ProductModel?> findByBarcode(String barcode) async {
    final row = await _db.queryOne(
      '''
      SELECT p.*, COALESCE(s.quantity, 0) AS quantity
      FROM products p
      LEFT JOIN stock_levels s ON s.product_id = p.id
      WHERE p.barcode = @barcode AND p.is_active = TRUE
      ''',
      parameters: {'barcode': barcode.trim()},
    );
    return row == null ? null : ProductModel.fromMap(row);
  }

  Future<String> completeSale({
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
    final invoiceNumber =
        'INV-${DateTime.now().millisecondsSinceEpoch}';

    String? clientId;
    if (clientPhone != null && clientPhone.isNotEmpty) {
      final existing = await _db.queryOne(
        'SELECT id FROM clients WHERE phone = @phone',
        parameters: {'phone': clientPhone},
      );
      if (existing != null) {
        clientId = existing['id'] as String;
      } else {
        clientId = _uuid.v4();
        await _db.execute(
          '''
          INSERT INTO clients (id, phone, is_synced)
          VALUES (@id, @phone, FALSE)
          ''',
          parameters: {'id': clientId, 'phone': clientPhone},
        );
      }
    }

    await _db.execute(
      '''
      INSERT INTO sales (
        id, invoice_number, user_id, client_id,
        subtotal, discount_amount, discount_percent, total,
        payment_method, amount_paid, change_given, status, is_synced
      ) VALUES (
        @id, @invoice, @user_id, @client_id,
        @subtotal, @discount_amount, @discount_percent, @total,
        @payment_method, @amount_paid, @change_given, 'completed', FALSE
      )
      ''',
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
      await _db.execute(
        '''
        INSERT INTO sale_lines (id, sale_id, product_id, quantity, unit_price, line_total, is_synced)
        VALUES (@id, @sale_id, @product_id, @qty, @price, @total, FALSE)
        ''',
        parameters: {
          'id': lineId,
          'sale_id': saleId,
          'product_id': line.product.id,
          'qty': line.quantity,
          'price': line.product.salePrice,
          'total': line.lineTotal,
        },
      );

      final movementId = _uuid.v4();
      await _db.execute(
        '''
        INSERT INTO stock_movements (
          id, product_id, movement_type, quantity_delta,
          reference_type, reference_id, user_id, is_synced
        ) VALUES (
          @id, @product_id, 'sale', @delta,
          'sale', @sale_id, @user_id, FALSE
        )
        ''',
        parameters: {
          'id': movementId,
          'product_id': line.product.id,
          'delta': -line.quantity,
          'sale_id': saleId,
          'user_id': userId,
        },
      );

      await _db.execute(
        '''
        INSERT INTO stock_levels (id, product_id, quantity, is_synced)
        VALUES (@id, @product_id, 0, FALSE)
        ON CONFLICT (product_id)
        DO UPDATE SET
          quantity = stock_levels.quantity - @deduct,
          updated_at = NOW(),
          is_synced = FALSE
        ''',
        parameters: {
          'id': _uuid.v4(),
          'product_id': line.product.id,
          'deduct': line.quantity,
        },
      );
    }

    return invoiceNumber;
  }
}
