import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/database/sale_scope_sql.dart';

class DashboardRepository {
  final _db = DatabaseService.instance;

  Future<Map<String, dynamic>> todayStats({
    bool includeFinancial = true,
    String? onlyUserId,
  }) async {
    final params = <String, dynamic>{};
    final scope = SaleScopeSql.clause(onlyUserId: onlyUserId, params: params);
    final row = await _db.queryOne(
      '''
      SELECT
        COUNT(*) AS transactions,
        COALESCE(SUM(sl.quantity), 0) AS items_sold
      FROM sales s
      LEFT JOIN sale_lines sl ON sl.sale_id = s.id
      WHERE s.status = 'completed' AND s.sold_at::date = CURRENT_DATE
      $scope
      ''',
      parameters: params.isEmpty ? null : params,
    );
    final result = Map<String, dynamic>.from(row ?? {});
    if (includeFinancial) {
      final fin = await _db.queryOne(
        '''
        SELECT
          COALESCE(SUM(total), 0) AS revenue,
          COALESCE(AVG(total), 0) AS avg_basket
        FROM sales s
        WHERE status = 'completed' AND sold_at::date = CURRENT_DATE
        $scope
        ''',
        parameters: params.isEmpty ? null : params,
      );
      result.addAll(fin ?? {});
    }
    return result;
  }

  Future<int> lowStockCount() async {
    final row = await _db.queryOne(
      '''
      SELECT COUNT(*) AS c
      FROM products p
      JOIN stock_levels s ON s.product_id = p.id
      WHERE p.is_active = TRUE AND s.quantity <= p.min_stock_level
      ''',
    );
    return (row?['c'] as int?) ?? int.tryParse('${row?['c']}') ?? 0;
  }

  Future<List<Map<String, dynamic>>> recentSales({
    int limit = 8,
    String? onlyUserId,
    bool todayOnly = false,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    final dayClause = todayOnly ? ' AND s.sold_at::date = CURRENT_DATE' : '';
    return _db.query(
      '''
      SELECT s.invoice_number, s.total, s.sold_at, s.payment_method, u.full_name
      FROM sales s
      JOIN users u ON u.id = s.user_id
      WHERE s.status = 'completed'
      $dayClause
      ${SaleScopeSql.clause(onlyUserId: onlyUserId, params: params)}
      ORDER BY s.sold_at DESC
      LIMIT @limit
      ''',
      parameters: params,
    );
  }
}
