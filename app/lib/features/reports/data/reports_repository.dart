import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:souma_parfumerie/core/database/sale_scope_sql.dart';
import 'package:souma_parfumerie/features/expenses/data/expenses_repository.dart';

class ReportsRepository {
  ReportsRepository({this.scopeUserId});

  /// Si renseigné, statistiques limitées aux ventes de ce caissier.
  final String? scopeUserId;

  final _db = DatabaseService.instance;
  final _expenses = ExpensesRepository();

  String _saleScope(Map<String, dynamic> params, {String alias = 's'}) =>
      SaleScopeSql.clause(
        onlyUserId: scopeUserId,
        params: params,
        tableAlias: alias,
      );

  Map<String, dynamic> _range(DateTime from, DateTime to) => {
        'from': DateTime(from.year, from.month, from.day),
        'to_end': DateTime(to.year, to.month, to.day).add(const Duration(days: 1)),
        'to_day': DateTime(to.year, to.month, to.day),
      };

  Future<Map<String, dynamic>> periodSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final p = _range(from, to);
    final params = {'from': p['from'], 'to_end': p['to_end']};
    final scope = _saleScope(params);
    final row = await _db.queryOne(
      '''
      SELECT
        COALESCE(SUM(total), 0) AS revenue,
        COUNT(*) AS transactions,
        COALESCE(AVG(total), 0) AS avg_basket,
        COALESCE(SUM(discount_amount), 0) AS total_discounts
      FROM sales s
      WHERE status = 'completed'
        AND sold_at >= @from
        AND sold_at < @to_end
        $scope
      ''',
      parameters: params,
    );
    return row ?? {};
  }

  Future<Map<String, dynamic>> dailySummary() async {
    final now = DateTime.now();
    return periodSummary(
      from: DateTime(now.year, now.month, now.day),
      to: now,
    );
  }

  Future<double> estimatedProfit({
    required DateTime from,
    required DateTime to,
  }) async {
    final p = _range(from, to);
    final params = {'from': p['from'], 'to_end': p['to_end']};
    final scope = _saleScope(params);
    final row = await _db.queryOne(
      '''
      SELECT COALESCE(SUM((sl.unit_price - p.purchase_price) * sl.quantity), 0) AS profit
      FROM sale_lines sl
      JOIN sales s ON s.id = sl.sale_id
      JOIN products p ON p.id = sl.product_id
      WHERE s.status = 'completed'
        AND s.sold_at >= @from
        AND s.sold_at < @to_end
        $scope
      ''',
      parameters: params,
    );
    final v = row?['profit'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<List<Map<String, dynamic>>> paymentBreakdown({
    required DateTime from,
    required DateTime to,
  }) async {
    final p = _range(from, to);
    final params = {'from': p['from'], 'to_end': p['to_end']};
    final scope = _saleScope(params);
    return _db.query(
      '''
      SELECT payment_method,
             COUNT(*) AS transactions,
             COALESCE(SUM(total), 0) AS total
      FROM sales s
      WHERE status = 'completed'
        AND sold_at >= @from
        AND sold_at < @to_end
        $scope
      GROUP BY payment_method
      ORDER BY total DESC
      ''',
      parameters: params,
    );
  }

  Future<List<Map<String, dynamic>>> salesByCashier({
    required DateTime from,
    required DateTime to,
  }) async {
    final p = _range(from, to);
    final params = {'from': p['from'], 'to_end': p['to_end']};
    final scope = _saleScope(params);
    return _db.query(
      '''
      SELECT u.full_name AS cashier_name,
             COUNT(*) AS transactions,
             COALESCE(SUM(s.total), 0) AS revenue
      FROM sales s
      JOIN users u ON u.id = s.user_id
      WHERE s.status = 'completed'
        AND s.sold_at >= @from
        AND s.sold_at < @to_end
        $scope
      GROUP BY u.id, u.full_name
      ORDER BY revenue DESC
      ''',
      parameters: params,
    );
  }

  Future<List<Map<String, dynamic>>> topProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final p = _range(from, to);
    final params = {
      'from': p['from'],
      'to_end': p['to_end'],
      'limit': limit,
    };
    final scope = _saleScope(params);
    return _db.query(
      '''
      SELECT p.name_fr, p.name_ar, p.barcode,
             c.name_fr AS category_fr, c.name_ar AS category_ar,
             SUM(sl.quantity) AS qty_sold,
             SUM(sl.line_total) AS revenue,
             COUNT(DISTINCT s.id) AS sale_count
      FROM sale_lines sl
      JOIN sales s ON s.id = sl.sale_id
      JOIN products p ON p.id = sl.product_id
      JOIN categories c ON c.id = p.category_id
      WHERE s.status = 'completed'
        AND s.sold_at >= @from
        AND s.sold_at < @to_end
        $scope
      GROUP BY p.id, p.name_fr, p.name_ar, p.barcode, c.name_fr, c.name_ar
      ORDER BY qty_sold DESC
      LIMIT @limit
      ''',
      parameters: params,
    );
  }

  Future<List<Map<String, dynamic>>> revenueByDay({
    required DateTime from,
    required DateTime to,
  }) async {
    final p = _range(from, to);
    final params = {'from': p['from'], 'to_end': p['to_end']};
    final scope = _saleScope(params);
    return _db.query(
      '''
      SELECT sold_at::date AS day,
             SUM(total) AS revenue,
             COUNT(*) AS transactions
      FROM sales s
      WHERE status = 'completed'
        AND sold_at >= @from
        AND sold_at < @to_end
        $scope
      GROUP BY 1
      ORDER BY 1 ASC
      ''',
      parameters: params,
    );
  }

  Future<List<Map<String, dynamic>>> salesByCategory({
    required DateTime from,
    required DateTime to,
  }) async {
    final p = _range(from, to);
    final params = {'from': p['from'], 'to_end': p['to_end']};
    final scope = _saleScope(params);
    return _db.query(
      '''
      SELECT c.name_fr, c.name_ar,
             SUM(sl.line_total) AS revenue,
             SUM(sl.quantity) AS qty
      FROM sale_lines sl
      JOIN sales s ON s.id = sl.sale_id
      JOIN products p ON p.id = sl.product_id
      JOIN categories c ON c.id = p.category_id
      WHERE s.status = 'completed'
        AND s.sold_at >= @from
        AND s.sold_at < @to_end
        $scope
      GROUP BY c.id, c.name_fr, c.name_ar
      ORDER BY revenue DESC
      ''',
      parameters: params,
    );
  }

  Future<List<Map<String, dynamic>>> monthlyRevenue({int months = 12}) async {
    final params = <String, dynamic>{'months': months};
    final scope = _saleScope(params);
    return _db.query(
      '''
      SELECT DATE_TRUNC('month', sold_at) AS month,
             SUM(total) AS revenue,
             COUNT(*) AS transactions
      FROM sales s
      WHERE status = 'completed'
        AND sold_at >= DATE_TRUNC('month', CURRENT_DATE)
            - (@months || ' months')::interval
        $scope
      GROUP BY 1
      ORDER BY 1 ASC
      ''',
      parameters: params,
    );
  }

  Future<Map<String, dynamic>> previousPeriodComparison({
    required DateTime from,
    required DateTime to,
  }) async {
    final days = to.difference(from).inDays + 1;
    final prevTo = from.subtract(const Duration(days: 1));
    final prevFrom = prevTo.subtract(Duration(days: days - 1));
    final current = await periodSummary(from: from, to: to);
    final previous = await periodSummary(from: prevFrom, to: prevTo);
    return {'current': current, 'previous': previous, 'days': days};
  }

  Future<List<Map<String, dynamic>>> lowStockWithSupplier({int limit = 20}) async {
    return _db.query(
      '''
      SELECT p.id, p.barcode, p.name_fr, p.name_ar, p.min_stock_level,
             COALESCE(sl.quantity, 0) AS quantity,
             sup.name AS supplier_name,
             (
               SELECT MAX(sa.sold_at)
               FROM sale_lines sll
               JOIN sales sa ON sa.id = sll.sale_id
               WHERE sll.product_id = p.id AND sa.status = 'completed'
             ) AS last_sale_at
      FROM products p
      LEFT JOIN stock_levels sl ON sl.product_id = p.id
      LEFT JOIN suppliers sup ON sup.id = p.supplier_id
      WHERE p.is_active = TRUE
        AND COALESCE(sl.quantity, 0) <= p.min_stock_level
      ORDER BY quantity ASC, p.name_fr ASC
      LIMIT @limit
      ''',
      parameters: {'limit': limit},
    );
  }

  Future<List<Map<String, dynamic>>> stockMovements({
    required DateTime from,
    required DateTime to,
    int limit = 80,
  }) async {
    final p = _range(from, to);
    return _db.query(
      '''
      SELECT sm.movement_type, sm.quantity_delta, sm.created_at,
             sm.reference_type, p.name_fr, p.name_ar,
             u.full_name AS user_name
      FROM stock_movements sm
      JOIN products p ON p.id = sm.product_id
      LEFT JOIN users u ON u.id = sm.user_id
      WHERE sm.created_at >= @from
        AND sm.created_at < @to_end
      ORDER BY sm.created_at DESC
      LIMIT @limit
      ''',
      parameters: {
        'from': p['from'],
        'to_end': p['to_end'],
        'limit': limit,
      },
    );
  }

  Future<Map<String, dynamic>> expensesPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    return _expenses.periodTotals(from: from, to: to);
  }

  /// Détail mois par mois pour une année civile (12 lignes max).
  Future<List<Map<String, dynamic>>> monthlyBreakdownForYear(int year) async {
    final from = DateTime(year, 1, 1);
    final to = DateTime(year, 12, 31);
    final p = _range(from, to);
    final params = {'from': p['from'], 'to_end': p['to_end']};
    final scope = _saleScope(params);
    return _db.query(
      '''
      SELECT DATE_TRUNC('month', sold_at) AS month,
             COALESCE(SUM(total), 0) AS revenue,
             COUNT(*) AS transactions,
             COALESCE(AVG(total), 0) AS avg_basket,
             COALESCE(SUM(discount_amount), 0) AS total_discounts
      FROM sales s
      WHERE status = 'completed'
        AND sold_at >= @from
        AND sold_at < @to_end
        $scope
      GROUP BY 1
      ORDER BY 1 ASC
      ''',
      parameters: params,
    );
  }

  /// Synthèse annuelle (année complète).
  Future<Map<String, dynamic>> yearSummary(int year) async {
    final from = DateTime(year, 1, 1);
    final to = DateTime(year, 12, 31);
    return periodSummary(from: from, to: to);
  }

  /// Comparaison année N vs N-1.
  Future<Map<String, dynamic>> yearOverYearComparison(int year) async {
    final current = await yearSummary(year);
    final previous = await yearSummary(year - 1);
    return {'current': current, 'previous': previous, 'year': year};
  }

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

  /// Statistiques retours sur la période sélectionnée.
  Future<Map<String, dynamic>> returnPeriodSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!await _returnColumnsReady()) {
      return {
        'requested': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'approved_amount': 0,
      };
    }
    final p = _range(from, to);
    final params = {'from': p['from'], 'to_end': p['to_end']};
    final scope = _saleScope(params);
    final row = await _db.queryOne(
      '''
      SELECT
        COUNT(*) FILTER (WHERE return_status IS NOT NULL
          AND return_requested_at >= @from
          AND return_requested_at < @to_end)::int AS requested,
        COUNT(*) FILTER (WHERE return_status = 'pending'
          AND return_requested_at >= @from
          AND return_requested_at < @to_end)::int AS pending,
        COUNT(*) FILTER (WHERE return_status = 'approved'
          AND return_approved_at >= @from
          AND return_approved_at < @to_end)::int AS approved,
        COUNT(*) FILTER (WHERE return_status = 'rejected'
          AND return_approved_at >= @from
          AND return_approved_at < @to_end)::int AS rejected,
        COALESCE(SUM(total) FILTER (WHERE return_status = 'approved'
          AND return_approved_at >= @from
          AND return_approved_at < @to_end), 0) AS approved_amount
      FROM sales s
      WHERE return_status IS NOT NULL
      $scope
      ''',
      parameters: params,
    );
    return row ??
        {
          'requested': 0,
          'pending': 0,
          'approved': 0,
          'rejected': 0,
          'approved_amount': 0,
        };
  }
}
