import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:uuid/uuid.dart';

class ExpensesRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  static const categories = [
    'cash_send',
    'purchase',
    'exit',
    'supply',
    'other',
  ];

  Future<bool> tableExists() async {
    try {
      final row = await _db.queryOne(
        '''
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'expenses'
        ''',
      );
      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> list({
    DateTime? from,
    DateTime? to,
    String? category,
    int limit = 200,
  }) async {
    if (!await tableExists()) return [];

    var sql = '''
      SELECT e.*, u.full_name AS user_name, s.name AS supplier_name
      FROM expenses e
      JOIN users u ON u.id = e.user_id
      LEFT JOIN suppliers s ON s.id = e.supplier_id
      WHERE 1=1
    ''';
    final params = <String, dynamic>{'limit': limit};

    if (from != null) {
      sql += ' AND e.expense_date >= @from';
      params['from'] = DateTime(from.year, from.month, from.day);
    }
    if (to != null) {
      sql += ' AND e.expense_date <= @to';
      params['to'] = DateTime(to.year, to.month, to.day);
    }
    if (category != null && category.isNotEmpty) {
      sql += ' AND e.category = @cat';
      params['cat'] = category;
    }
    sql += ' ORDER BY e.expense_date DESC, e.created_at DESC LIMIT @limit';

    return _db.query(sql, parameters: params);
  }

  Future<Map<String, dynamic>> periodTotals({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!await tableExists()) {
      return {'total': 0, 'count': 0};
    }
    final row = await _db.queryOne(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total, COUNT(*) AS count
      FROM expenses
      WHERE expense_date >= @from AND expense_date <= @to
      ''',
      parameters: {
        'from': DateTime(from.year, from.month, from.day),
        'to': DateTime(to.year, to.month, to.day),
      },
    );
    return row ?? {'total': 0, 'count': 0};
  }

  Future<void> create({
    required String userId,
    required DateTime expenseDate,
    required double amount,
    required String category,
    String? description,
    String? beneficiary,
    String? supplierId,
    String paymentMethod = 'cash',
  }) async {
    await _db.execute(
      '''
      INSERT INTO expenses (
        id, expense_date, amount, category, description,
        beneficiary, supplier_id, user_id, payment_method, is_synced
      ) VALUES (
        @id, @date, @amount, @cat, @desc,
        @ben, @sup, @user, @pay, FALSE
      )
      ''',
      parameters: {
        'id': _uuid.v4(),
        'date': DateTime(expenseDate.year, expenseDate.month, expenseDate.day),
        'amount': amount,
        'cat': category,
        'desc': description,
        'ben': beneficiary,
        'sup': supplierId,
        'user': userId,
        'pay': paymentMethod,
      },
    );
  }

  Future<void> update({
    required String id,
    required DateTime expenseDate,
    required double amount,
    required String category,
    String? description,
    String? beneficiary,
    String? supplierId,
  }) async {
    await _db.execute(
      '''
      UPDATE expenses SET
        expense_date = @date,
        amount = @amount,
        category = @cat,
        description = @desc,
        beneficiary = @ben,
        supplier_id = @sup,
        is_synced = FALSE,
        updated_at = NOW()
      WHERE id = @id
      ''',
      parameters: {
        'id': id,
        'date': DateTime(expenseDate.year, expenseDate.month, expenseDate.day),
        'amount': amount,
        'cat': category,
        'desc': description,
        'ben': beneficiary,
        'sup': supplierId,
      },
    );
  }

  Future<void> delete(String id) async {
    await _db.execute(
      'DELETE FROM expenses WHERE id = @id',
      parameters: {'id': id},
    );
  }
}
