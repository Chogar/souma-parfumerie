import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Connection? _connection;
  Future<void> _opChain = Future.value();

  /// Une seule requête à la fois sur la connexion partagée (évite les blocages).
  Future<T> _serialized<T>(Future<T> Function() action) {
    final run = _opChain.then((_) => action());
    _opChain = run.then((_) {}, onError: (_) {});
    return run;
  }

  static String? get _unixSocketPath {
    const candidates = [
      '/tmp/.s.PGSQL.5432',
      '/var/run/postgresql/.s.PGSQL.5432',
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  static Endpoint get _endpoint {
    final password =
        AppConfig.dbPassword.isEmpty ? null : AppConfig.dbPassword;

    if (Platform.isMacOS || Platform.isLinux) {
      final socket = _unixSocketPath;
      if (socket != null) {
        return Endpoint(
          host: socket,
          port: 0,
          database: AppConfig.dbName,
          username: AppConfig.dbUser,
          password: password,
          isUnixSocket: true,
        );
      }
    }

    return Endpoint(
      host: AppConfig.dbHost,
      port: AppConfig.dbPort,
      database: AppConfig.dbName,
      username: AppConfig.dbUser,
      password: password,
    );
  }

  Future<Connection> get connection async {
    if (_connection != null) {
      return _connection!;
    }
    _connection = await Connection.open(
      _endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    return _connection!;
  }

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }

  Future<bool> testConnection() async {
    try {
      final conn = await Connection.open(
        _endpoint,
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
          connectTimeout: Duration(seconds: 5),
        ),
      );
      await conn.execute('SELECT 1');
      await conn.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) =>
      _serialized(() async {
        final conn = await connection;
        final result = await conn.execute(
          Sql.named(sql),
          parameters: parameters ?? {},
        );
        return result.map((row) => row.toColumnMap()).toList();
      });

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
  }) =>
      _serialized(() async {
        final conn = await connection;
        await conn.execute(Sql.named(sql), parameters: parameters ?? {});
      });

  /// Exécute plusieurs requêtes dans une seule transaction (plus rapide, atomique).
  Future<R> runTx<R>(Future<R> Function(Session session) action) =>
      _serialized(() async {
        final conn = await connection;
        return conn.runTx(action);
      });
}
