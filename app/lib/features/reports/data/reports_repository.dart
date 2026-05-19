import 'package:souma_parfumerie/core/database/database_service.dart';

class ReportsRepository {
  final _db = DatabaseService.instance;

  Future<Map<String, dynamic>> dailySummary() async {
    final row = await _db.queryOne(
      '''
      SELECT
        COALESCE(SUM(total), 0) AS revenue,
        COUNT(*) AS transactions,
        COALESCE(AVG(total), 0) AS avg_basket,
        COALESCE(SUM(discount_amount), 0) AS total_discounts
      FROM sales
      WHERE status = 'completed'
        AND sold_at::date = CURRENT_DATE
      ''',
    );
    return row ?? {};
  }

  Future<List<Map<String, dynamic>>> topProducts({int limit = 10}) async {
    return _db.query(
      '''
      SELECT p.name_fr, p.name_ar, p.barcode,
             SUM(sl.quantity) AS qty_sold,
             SUM(sl.line_total) AS revenue
      FROM sale_lines sl
      JOIN sales s ON s.id = sl.sale_id
      JOIN products p ON p.id = sl.product_id
      WHERE s.status = 'completed'
        AND s.sold_at >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY p.id, p.name_fr, p.name_ar, p.barcode
      ORDER BY qty_sold DESC
      LIMIT @limit
      ''',
      parameters: {'limit': limit},
    );
  }

  Future<List<Map<String, dynamic>>> monthlyRevenue({int months = 12}) async {
    return _db.query(
      '''
      SELECT
        DATE_TRUNC('month', sold_at) AS month,
        SUM(total) AS revenue,
        COUNT(*) AS transactions
      FROM sales
      WHERE status = 'completed'
        AND sold_at >= DATE_TRUNC('month', CURRENT_DATE) - (@months || ' months')::interval
      GROUP BY 1
      ORDER BY 1 ASC
      ''',
      parameters: {'months': months},
    );
  }

  Future<List<Map<String, dynamic>>> paymentBreakdownToday() async {
    return _db.query(
      '''
      SELECT payment_method, COUNT(*) AS count, SUM(total) AS amount
      FROM sales
      WHERE status = 'completed' AND sold_at::date = CURRENT_DATE
      GROUP BY payment_method
      ''',
    );
  }
}
