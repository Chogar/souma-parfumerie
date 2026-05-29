import 'package:postgres/postgres.dart';
import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/database/sale_scope_sql.dart';
import 'package:souma_parfumerie/features/sales/models/sale_return_line_request.dart';
import 'package:uuid/uuid.dart';

class SaleReturnException implements Exception {
  SaleReturnException(this.code);
  final String code;

  @override
  String toString() => code;
}

/// Retours : le caissier demande, le manager valide ou refuse.
class SaleReturnsRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  static const codeNotFound = 'SALE_NOT_FOUND';
  static const codeNotReturnable = 'SALE_NOT_RETURNABLE';
  static const codeAlreadyPending = 'RETURN_ALREADY_PENDING';
  static const codeNotPending = 'RETURN_NOT_PENDING';
  static const codeMigrationRequired = 'RETURN_MIGRATION_REQUIRED';
  static const codeForbidden = 'RETURN_FORBIDDEN';
  static const codeInvalidItems = 'RETURN_INVALID_ITEMS';

  Future<bool> _columnsReady() async {
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

  Future<void> _ensureColumns() async {
    if (!await _columnsReady()) {
      throw SaleReturnException(codeMigrationRequired);
    }
  }

  Future<bool> _returnLinesTableReady() async {
    try {
      final row = await _db.queryOne(
        '''
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'sale_return_line_items'
        LIMIT 1
        ''',
      );
      return row != null;
    } catch (_) {
      return false;
    }
  }

  /// Détail complet d'une demande en attente (validation manager).
  Future<Map<String, dynamic>?> getPendingReturnDetail(String saleId) async {
    await _ensureColumns();
    final sale = await _db.queryOne(
      '''
      SELECT s.*, u.full_name AS cashier_name,
             ru.full_name AS return_requester_name,
             c.phone AS client_phone, c.name AS client_name,
             c.loyalty_points AS client_loyalty_points
      FROM sales s
      JOIN users u ON u.id = s.user_id
      LEFT JOIN users ru ON ru.id = s.return_requested_by
      LEFT JOIN clients c ON c.id = s.client_id
      WHERE s.id = @id AND s.return_status = 'pending'
      ''',
      parameters: {'id': saleId},
    );
    if (sale == null) return null;

    final returnLines = await pendingReturnLineItems(saleId);
    final allLines = await _db.query(
      '''
      SELECT sl.id, sl.product_id, sl.quantity, sl.unit_price, sl.line_total,
             p.name_fr, p.name_ar, p.barcode
      FROM sale_lines sl
      JOIN products p ON p.id = sl.product_id
      WHERE sl.sale_id = @id
      ORDER BY sl.id
      ''',
      parameters: {'id': saleId},
    );

    return {
      'sale': sale,
      'return_lines': returnLines,
      'all_lines': allLines,
    };
  }

  Future<List<Map<String, dynamic>>> pendingReturnLineItems(
    String saleId,
  ) async {
    if (!await _returnLinesTableReady()) return [];
    return _db.query(
      '''
      SELECT sri.*, p.name_fr, p.name_ar
      FROM sale_return_line_items sri
      JOIN products p ON p.id = sri.product_id
      WHERE sri.sale_id = @sale_id
      ORDER BY sri.sale_line_id
      ''',
      parameters: {'sale_id': saleId},
    );
  }

  Future<List<Map<String, dynamic>>> listPendingReturns() async {
    await _ensureColumns();
    return _db.query(
      '''
      SELECT s.*, u.full_name AS cashier_name,
             ru.full_name AS return_requester_name,
             c.phone AS client_phone
      FROM sales s
      JOIN users u ON u.id = s.user_id
      LEFT JOIN users ru ON ru.id = s.return_requested_by
      LEFT JOIN clients c ON c.id = s.client_id
      WHERE s.return_status = 'pending'
      ORDER BY s.return_requested_at ASC
      ''',
    );
  }

  Future<int> countPendingReturns() async {
    if (!await _columnsReady()) return 0;
    final row = await _db.queryOne(
      "SELECT COUNT(*)::int AS c FROM sales WHERE return_status = 'pending'",
    );
    return (row?['c'] as int?) ?? int.tryParse('${row?['c']}') ?? 0;
  }

  Future<void> requestReturn({
    required String saleId,
    required String requestedByUserId,
    required List<SaleReturnLineRequest> items,
    String? reason,
    String? onlyUserId,
  }) async {
    if (items.isEmpty) throw SaleReturnException(codeInvalidItems);
    await _ensureColumns();
    final selectParams = <String, dynamic>{'id': saleId};
    final sale = await _db.queryOne(
      '''
      SELECT id, user_id, status, return_status
      FROM sales s
      WHERE s.id = @id
      ${SaleScopeSql.clause(onlyUserId: onlyUserId, params: selectParams)}
      ''',
      parameters: selectParams,
    );
    if (sale == null) throw SaleReturnException(codeNotFound);
    if (sale['status'] != 'completed') {
      throw SaleReturnException(codeNotReturnable);
    }
    final rs = sale['return_status']?.toString();
    if (rs == 'pending') throw SaleReturnException(codeAlreadyPending);
    if (rs == 'approved' || sale['status'] == 'returned') {
      throw SaleReturnException(codeNotReturnable);
    }

    final reasonVal =
        reason?.trim().isEmpty == true ? null : reason?.trim();

    final lineRows = await _db.query(
      '''
      SELECT id, product_id, quantity FROM sale_lines WHERE sale_id = @id
      ''',
      parameters: {'id': saleId},
    );
    final lineById = {
      for (final l in lineRows) l['id'] as String: l,
    };
    for (final item in items) {
      final line = lineById[item.saleLineId];
      if (line == null) throw SaleReturnException(codeInvalidItems);
      final sold = (line['quantity'] as num).toInt();
      if (item.quantityToReturn < 1 ||
          item.quantityToReturn > sold ||
          item.productId != line['product_id']) {
        throw SaleReturnException(codeInvalidItems);
      }
      if (item.quantitySold != sold) {
        throw SaleReturnException(codeInvalidItems);
      }
    }

    final hasReturnLinesTable = await _returnLinesTableReady();

    await _db.runTx((tx) async {
      if (hasReturnLinesTable) {
        await tx.execute(
          Sql.named(
            'DELETE FROM sale_return_line_items WHERE sale_id = @id',
          ),
          parameters: {'id': saleId},
        );
        for (final item in items) {
          await tx.execute(
            Sql.named('''
              INSERT INTO sale_return_line_items (
                id, sale_id, sale_line_id, product_id,
                quantity_sold, quantity_to_return
              ) VALUES (
                @id, @sale_id, @sale_line_id, @product_id,
                @quantity_sold, @quantity_to_return
              )
            '''),
            parameters: {
              'id': _uuid.v4(),
              'sale_id': saleId,
              'sale_line_id': item.saleLineId,
              'product_id': item.productId,
              'quantity_sold': item.quantitySold,
              'quantity_to_return': item.quantityToReturn,
            },
          );
        }
      }

      await tx.execute(
        Sql.named('''
          UPDATE sales SET
            return_status = 'pending',
            return_reason = @reason,
            return_requested_by = @by,
            return_requested_at = NOW(),
            return_approved_by = NULL,
            return_approved_at = NULL,
            is_synced = FALSE,
            updated_at = NOW()
          WHERE id = @id
        '''),
        parameters: {
          'id': saleId,
          'by': requestedByUserId,
          'reason': reasonVal,
        },
      );
    });
  }

  /// Historique des retours (tous statuts sauf null).
  Future<List<Map<String, dynamic>>> listReturnHistory({
    String? onlyUserId,
    String? statusFilter,
    int limit = 200,
  }) async {
    if (!await _columnsReady()) return [];
    final params = <String, dynamic>{'limit': limit};
    var statusClause = '';
    if (statusFilter != null && statusFilter.isNotEmpty) {
      params['status'] = statusFilter;
      statusClause = " AND s.return_status = @status";
    }
    return _db.query(
      '''
      SELECT s.id, s.invoice_number, s.total, s.status AS sale_status,
             s.return_status, s.return_reason, s.return_requested_at,
             s.return_approved_at,
             u.full_name AS cashier_name,
             ru.full_name AS return_requester_name,
             av.full_name AS return_approver_name,
             c.phone AS client_phone
      FROM sales s
      JOIN users u ON u.id = s.user_id
      LEFT JOIN users ru ON ru.id = s.return_requested_by
      LEFT JOIN users av ON av.id = s.return_approved_by
      LEFT JOIN clients c ON c.id = s.client_id
      WHERE s.return_status IS NOT NULL
      $statusClause
      ${SaleScopeSql.clause(onlyUserId: onlyUserId, params: params)}
      ORDER BY COALESCE(s.return_requested_at, s.return_approved_at) DESC
      LIMIT @limit
      ''',
      parameters: params,
    );
  }

  /// Statistiques retours du jour (tableau de bord).
  Future<Map<String, dynamic>> returnDailySummary({String? onlyUserId}) async {
    if (!await _columnsReady()) {
      return {
        'returns_today': 0,
        'approved_today': 0,
        'rejected_today': 0,
      };
    }
    final params = <String, dynamic>{};
    final scope = SaleScopeSql.clause(onlyUserId: onlyUserId, params: params);
    final row = await _db.queryOne(
      '''
      SELECT
        COUNT(*) FILTER (
          WHERE s.return_status IS NOT NULL
            AND (
              s.return_requested_at::date = CURRENT_DATE
              OR s.return_approved_at::date = CURRENT_DATE
            )
        )::int AS returns_today,
        COUNT(*) FILTER (
          WHERE s.return_status = 'approved'
            AND s.return_approved_at::date = CURRENT_DATE
        )::int AS approved_today,
        COUNT(*) FILTER (
          WHERE s.return_status = 'rejected'
            AND s.return_approved_at::date = CURRENT_DATE
        )::int AS rejected_today
      FROM sales s
      WHERE s.return_status IS NOT NULL
      $scope
      ''',
      parameters: params.isEmpty ? null : params,
    );
    return row ??
        {
          'returns_today': 0,
          'approved_today': 0,
          'rejected_today': 0,
        };
  }

  Future<void> _requireManagerRole(String userId) async {
    final row = await _db.queryOne(
      '''
      SELECT r.code AS role_code
      FROM users u
      JOIN roles r ON r.id = u.role_id
      WHERE u.id = @id AND u.is_active = TRUE
      ''',
      parameters: {'id': userId},
    );
    if (row?['role_code'] != 'manager') {
      throw SaleReturnException(codeForbidden);
    }
  }

  Future<void> approveReturn({
    required String saleId,
    required String managerId,
  }) async {
    await _ensureColumns();
    await _requireManagerRole(managerId);
    final hasReturnLinesTable = await _returnLinesTableReady();
    await _db.runTx((tx) async {
      final saleRows = await tx.execute(
        Sql.named('''
          SELECT id, user_id, client_id, invoice_number, return_status, status
          FROM sales WHERE id = @id FOR UPDATE
        '''),
        parameters: {'id': saleId},
      );
      if (saleRows.isEmpty) throw SaleReturnException(codeNotFound);
      final sale = saleRows.first.toColumnMap();
      if (sale['return_status'] != 'pending') {
        throw SaleReturnException(codeNotPending);
      }

      final returnItems = await _loadReturnItemsForApproval(
        tx,
        saleId,
        hasReturnLinesTable,
      );

      var totalReturned = 0;
      for (final item in returnItems) {
        final qty = item['quantity_to_return'] as int;
        totalReturned += qty;
        final productId = item['product_id'] as String;
        await tx.execute(
          Sql.named('''
            INSERT INTO stock_movements (
              id, product_id, movement_type, quantity_delta,
              reference_type, reference_id, user_id, note, is_synced
            ) VALUES (
              @id, @product_id, 'return', @delta,
              'sale_return', @sale_id, @user_id, @note, FALSE
            )
          '''),
          parameters: {
            'id': _uuid.v4(),
            'product_id': productId,
            'delta': qty,
            'sale_id': saleId,
            'user_id': managerId,
            'note': 'Retour ${sale['invoice_number']}',
          },
        );

        final updated = await tx.execute(
          Sql.named('''
            UPDATE stock_levels SET
              quantity = quantity + @add,
              updated_at = NOW(),
              is_synced = FALSE
            WHERE product_id = @product_id
          '''),
          parameters: {'product_id': productId, 'add': qty},
        );
        if (updated.affectedRows == 0) {
          await tx.execute(
            Sql.named('''
              INSERT INTO stock_levels (id, product_id, quantity, is_synced)
              VALUES (@id, @product_id, @qty, FALSE)
            '''),
            parameters: {
              'id': _uuid.v4(),
              'product_id': productId,
              'qty': qty,
            },
          );
        }
      }

      // Total vendu sur toutes les lignes (pour retour complet vs partiel).
      final allLineRows = await tx.execute(
        Sql.named(
          'SELECT quantity FROM sale_lines WHERE sale_id = @id',
        ),
        parameters: {'id': saleId},
      );
      var saleTotalQty = 0;
      for (final row in allLineRows) {
        saleTotalQty += (row.toColumnMap()['quantity'] as num).toInt();
      }
      final fullReturn = totalReturned >= saleTotalQty;

      final clientId = sale['client_id'] as String?;
      if (clientId != null) {
        await tx.execute(
          Sql.named('''
            UPDATE clients SET
              loyalty_points = GREATEST(0, loyalty_points - 1),
              updated_at = NOW(),
              is_synced = FALSE
            WHERE id = @client_id::uuid AND loyalty_points > 0
          '''),
          parameters: {'client_id': clientId},
        );
      }

      final newStatus = fullReturn ? 'returned' : 'completed';

      await tx.execute(
        Sql.named('''
          UPDATE sales SET
            status = @status,
            return_status = 'approved',
            return_approved_by = @manager,
            return_approved_at = NOW(),
            is_synced = FALSE,
            updated_at = NOW()
          WHERE id = @id
        '''),
        parameters: {
          'id': saleId,
          'manager': managerId,
          'status': newStatus,
        },
      );
    });
  }

  Future<void> rejectReturn({
    required String saleId,
    required String managerId,
  }) async {
    await _ensureColumns();
    await _requireManagerRole(managerId);
    final row = await _db.queryOne(
      'SELECT return_status FROM sales WHERE id = @id',
      parameters: {'id': saleId},
    );
    if (row == null) throw SaleReturnException(codeNotFound);
    if (row['return_status'] != 'pending') {
      throw SaleReturnException(codeNotPending);
    }
    await _db.runTx((tx) async {
      if (await _returnLinesTableReady()) {
        await tx.execute(
          Sql.named(
            'DELETE FROM sale_return_line_items WHERE sale_id = @id',
          ),
          parameters: {'id': saleId},
        );
      }
      await tx.execute(
        Sql.named('''
          UPDATE sales SET
            return_status = 'rejected',
            return_approved_by = @manager,
            return_approved_at = NOW(),
            is_synced = FALSE,
            updated_at = NOW()
          WHERE id = @id
        '''),
        parameters: {'id': saleId, 'manager': managerId},
      );
    });
  }

  Future<List<Map<String, dynamic>>> _loadReturnItemsForApproval(
    Session tx,
    String saleId,
    bool hasReturnLinesTable,
  ) async {
    if (hasReturnLinesTable) {
      final rows = await tx.execute(
        Sql.named('''
          SELECT product_id, quantity_sold, quantity_to_return
          FROM sale_return_line_items
          WHERE sale_id = @id
        '''),
        parameters: {'id': saleId},
      );
      if (rows.isNotEmpty) {
        return rows
            .map((r) => r.toColumnMap())
            .map(
              (m) => {
                'product_id': m['product_id'],
                'quantity_sold': (m['quantity_sold'] as num).toInt(),
                'quantity_to_return': (m['quantity_to_return'] as num).toInt(),
              },
            )
            .toList();
      }
    }

    final lineRows = await tx.execute(
      Sql.named('''
        SELECT product_id, quantity AS quantity_sold, quantity AS quantity_to_return
        FROM sale_lines WHERE sale_id = @id
      '''),
      parameters: {'id': saleId},
    );
    return lineRows.map((r) {
      final m = r.toColumnMap();
      final q = (m['quantity_sold'] as num).toInt();
      return {
        'product_id': m['product_id'],
        'quantity_sold': q,
        'quantity_to_return': q,
      };
    }).toList();
  }
}
