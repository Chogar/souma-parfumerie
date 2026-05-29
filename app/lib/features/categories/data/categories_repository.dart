import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:uuid/uuid.dart';

class CategoriesRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  Future<List<Map<String, dynamic>>> list() async {
    return _db.query(
      'SELECT * FROM categories WHERE is_active = TRUE ORDER BY sort_order, name_fr',
    );
  }

  Future<void> save({
    String? id,
    required String nameFr,
    required String nameAr,
    int sortOrder = 0,
  }) async {
    if (id != null) {
      await _db.execute(
        '''
        UPDATE categories
        SET name_fr = @fr, name_ar = @ar, sort_order = @ord, is_synced = FALSE
        WHERE id = @id
        ''',
        parameters: {
          'id': id,
          'fr': nameFr,
          'ar': nameAr,
          'ord': sortOrder,
        },
      );
    } else {
      await _db.execute(
        '''
        INSERT INTO categories (id, name_fr, name_ar, sort_order, is_synced)
        VALUES (@id, @fr, @ar, @ord, FALSE)
        ''',
        parameters: {
          'id': _uuid.v4(),
          'fr': nameFr,
          'ar': nameAr,
          'ord': sortOrder,
        },
      );
    }
  }
}
