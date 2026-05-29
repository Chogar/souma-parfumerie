import 'package:postgres/postgres.dart';
import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/core/database/database_service.dart';
import 'package:uuid/uuid.dart';

class ClientsRepository {
  final _db = DatabaseService.instance;
  static const _uuid = Uuid();

  static int get giftThreshold => LoyaltyConfig.giftThreshold;

  /// Suggestions caisse : numéros commençant par [prefix] (saisie progressive).
  Future<List<Map<String, dynamic>>> searchByPhonePrefix(
    String prefix, {
    int limit = 8,
  }) async {
    final q = prefix.trim();
    if (q.isEmpty) return [];

    return _db.query(
      '''
      SELECT id, phone, name, loyalty_points
      FROM clients
      WHERE phone ILIKE @q
      ORDER BY phone ASC
      LIMIT @limit
      ''',
      parameters: {'q': '$q%', 'limit': limit},
    );
  }

  Future<List<Map<String, dynamic>>> list({String? search}) async {
    var sql = 'SELECT * FROM clients WHERE 1=1';
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      sql += ' AND (phone ILIKE @q OR name ILIKE @q)';
      params['q'] = '%$search%';
    }
    sql += ' ORDER BY loyalty_points DESC, updated_at DESC LIMIT 200';
    return _db.query(sql, parameters: params);
  }

  /// +1 validation après vente ; retourne le nouveau total de tampons.
  Future<int> addLoyaltyValidation(String clientId) async {
    final row = await _db.queryOne(
      '''
      UPDATE clients SET
        loyalty_points = loyalty_points + 1,
        is_synced = FALSE,
        updated_at = NOW()
      WHERE id = @client_id::uuid
      RETURNING loyalty_points
      ''',
      parameters: {'client_id': clientId},
    );
    final pts = row?['loyalty_points'];
    if (pts is int) return pts;
    return int.tryParse(pts?.toString() ?? '') ?? 0;
  }

  Future<String?> findClientIdByPhone(String phone) async {
    final row = await _db.queryOne(
      'SELECT id, loyalty_points FROM clients WHERE phone = @phone',
      parameters: {'phone': phone.trim()},
    );
    return row == null ? null : row['id'] as String;
  }

  Future<int> getLoyaltyPoints(String clientId) async {
    final row = await _db.queryOne(
      'SELECT loyalty_points FROM clients WHERE id = @client_id::uuid',
      parameters: {'client_id': clientId},
    );
    final v = row?['loyalty_points'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Cadeau offert : remet à zéro la carte du client [clientId] uniquement.
  Future<bool> redeemGift(String clientId) async {
    final cid = clientId.trim();
    if (cid.isEmpty) return false;

    return _db.runTx((tx) async {
      final locked = await tx.execute(
        Sql.named('''
          SELECT id, loyalty_points FROM clients
          WHERE id = @client_id::uuid
          FOR UPDATE
        '''),
        parameters: {'client_id': cid},
      );
      if (locked.isEmpty) return false;

      final current = locked.first.toColumnMap();
      final pts = (current['loyalty_points'] as num).toInt();
      if (pts < giftThreshold) return false;

      final updated = await tx.execute(
        Sql.named('''
          UPDATE clients SET
            loyalty_points = 0,
            gifts_received = gifts_received + 1,
            is_synced = FALSE,
            updated_at = NOW()
          WHERE id = @client_id::uuid
        '''),
        parameters: {'client_id': cid},
      );
      return updated.affectedRows == 1;
    });
  }

  Future<void> upsert({
    String? id,
    required String phone,
    String? name,
  }) async {
    if (id != null) {
      await _db.execute(
        '''
        UPDATE clients SET
          phone = @phone, name = @name, is_synced = FALSE
        WHERE id = @client_id::uuid
        ''',
        parameters: {
          'client_id': id,
          'phone': phone,
          'name': name,
        },
      );
    } else {
      await _db.execute(
        '''
        INSERT INTO clients (id, phone, name, loyalty_points, is_synced)
        VALUES (@id, @phone, @name, 0, FALSE)
        ON CONFLICT (phone) DO UPDATE SET
          name = COALESCE(EXCLUDED.name, clients.name),
          is_synced = FALSE
        ''',
        parameters: {
          'id': _uuid.v4(),
          'phone': phone,
          'name': name,
        },
      );
    }
  }

  Future<void> delete(String id) async {
    await _db.execute(
      'DELETE FROM clients WHERE id = @client_id::uuid',
      parameters: {'client_id': id},
    );
  }
}
