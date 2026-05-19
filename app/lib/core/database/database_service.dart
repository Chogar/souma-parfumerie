import 'package:postgres/postgres.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Connection? _connection;

  Future<Connection> get connection async {
    if (_connection != null) {
      return _connection!;
    }
    _connection = await Connection.open(
      Endpoint(
        host: AppConfig.dbHost,
        port: AppConfig.dbPort,
        database: AppConfig.dbName,
        username: AppConfig.dbUser,
        password: AppConfig.dbPassword,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    return _connection!;
  }

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named(sql),
      parameters: parameters ?? {},
    );
    return result.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>?> queryOne(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final rows = await query(sql, parameters: parameters);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> execute(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final conn = await connection;
    await conn.execute(Sql.named(sql), parameters: parameters ?? {});
  }
}
