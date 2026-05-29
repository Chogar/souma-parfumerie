import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/database/sale_scope_sql.dart';
import 'package:souma_parfumerie/core/models/cart_line.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:souma_parfumerie/features/pos/models/sale_receipt.dart';
import 'package:souma_parfumerie/features/settings/data/store_settings_repository.dart';

class SalesRepository {
  final _db = DatabaseService.instance;
  final _storeRepo = StoreSettingsRepository();

  Future<bool> _returnColumnsReady() async {
    try {
      final row = await _db.queryOne(
        '''
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'return_status'
        LIMIT 1
        ''',
      );
      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listSales({
    DateTime? from,
    DateTime? to,
    int limit = 100,
    String? onlyUserId,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    final returnFilter = await _returnColumnsReady()
        ? " AND (s.return_status IS NULL OR s.return_status IN ('rejected', 'pending'))"
        : '';
    var sql = '''
      SELECT s.*, u.full_name AS cashier_name,
             c.phone AS client_phone, c.name AS client_name,
             c.loyalty_points AS client_loyalty_points
      FROM sales s
      JOIN users u ON u.id = s.user_id
      LEFT JOIN clients c ON c.id = s.client_id
      WHERE s.status = 'completed'
      $returnFilter
      ${SaleScopeSql.clause(onlyUserId: onlyUserId, params: params)}
    ''';
    if (from != null) {
      sql += ' AND s.sold_at >= @from';
      params['from'] = from;
    }
    if (to != null) {
      sql += ' AND s.sold_at <= @to';
      params['to'] = to;
    }
    sql += ' ORDER BY s.sold_at DESC LIMIT @limit';
    return _db.query(sql, parameters: params);
  }

  Future<Map<String, dynamic>?> getSaleById(
    String saleId, {
    String? onlyUserId,
  }) async {
    final params = <String, dynamic>{'id': saleId};
    return _db.queryOne(
      '''
      SELECT s.*, u.full_name AS cashier_name,
             c.phone AS client_phone, c.name AS client_name,
             c.loyalty_points AS client_loyalty_points
      FROM sales s
      JOIN users u ON u.id = s.user_id
      LEFT JOIN clients c ON c.id = s.client_id
      WHERE s.id = @id
      ${SaleScopeSql.clause(onlyUserId: onlyUserId, params: params)}
      ''',
      parameters: params,
    );
  }

  Future<List<Map<String, dynamic>>> saleLines(String saleId) async {
    return _db.query(
      '''
      SELECT sl.*, p.name_fr, p.name_ar, p.barcode,
             p.sale_price, p.purchase_price, p.id AS product_id
      FROM sale_lines sl
      JOIN products p ON p.id = sl.product_id
      WHERE sl.sale_id = @id
      ORDER BY sl.id
      ''',
      parameters: {'id': saleId},
    );
  }

  Future<SaleReceipt?> buildReceipt(
    String saleId, {
    String? onlyUserId,
  }) async {
    final sale = await getSaleById(saleId, onlyUserId: onlyUserId);
    if (sale == null) return null;

    final lines = await saleLines(saleId);
    final cartLines = <CartLine>[];
    for (final l in lines) {
      final product = ProductModel(
        id: l['product_id'] as String,
        barcode: l['barcode'] as String? ?? '',
        nameFr: l['name_fr'] as String? ?? '',
        nameAr: l['name_ar'] as String? ?? '',
        salePrice: _num(l['unit_price'] ?? l['sale_price']),
        purchasePrice: _num(l['purchase_price']),
      );
      cartLines.add(
        CartLine(
          product: product,
          quantity: (l['quantity'] as num?)?.toInt() ?? 1,
        ),
      );
    }

    final soldAt = _parseTime(sale['sold_at']) ?? DateTime.now();
    final store = await _storeRepo.load();
    final clientPhone = sale['client_phone'] as String?;
    int? loyaltyStamps;
    var giftEligible = false;
    if (clientPhone != null && clientPhone.isNotEmpty) {
      loyaltyStamps = _int(sale['client_loyalty_points']);
      giftEligible = loyaltyStamps >= LoyaltyConfig.giftThreshold;
    }

    return SaleReceipt(
      invoiceNumber: sale['invoice_number'] as String,
      lines: cartLines,
      subtotal: _num(sale['subtotal']),
      discountAmount: _num(sale['discount_amount']),
      total: _num(sale['total']),
      paymentMethod: sale['payment_method'] as String? ?? 'cash',
      amountPaid: _num(sale['amount_paid']),
      changeGiven: _num(sale['change_given']),
      soldAt: soldAt,
      cashierName: sale['cashier_name'] as String?,
      clientPhone: clientPhone,
      store: store,
      loyaltyStamps: loyaltyStamps,
      loyaltyGiftEligible: giftEligible,
    );
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  DateTime? _parseTime(dynamic v) {
    if (v is DateTime) return v;
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
