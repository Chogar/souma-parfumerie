import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/database/database_service.dart';

class SyncService extends ChangeNotifier {
  SyncService();

  final _db = DatabaseService.instance;
  bool _syncing = false;
  DateTime? _lastSync;
  String? _status;

  bool get isSyncing => _syncing;
  DateTime? get lastSync => _lastSync;
  String? get status => _status;

  bool get isEnabled => AppConfig.cloudSyncEnabled;

  Future<String> apiBaseUrl() async {
    if (!isEnabled) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ?? AppConfig.defaultApiBaseUrl;
  }

  Future<bool> hasConnectivity() async {
    if (!isEnabled) return false;
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<bool> sync({String? token}) async {
    if (!isEnabled) {
      _status = 'disabled';
      notifyListeners();
      return false;
    }
    if (_syncing) return false;
    if (!await hasConnectivity()) {
      _status = 'offline';
      notifyListeners();
      return false;
    }

    _syncing = true;
    _status = 'syncing';
    notifyListeners();

    try {
      final baseUrl = await apiBaseUrl();
      final prefs = await SharedPreferences.getInstance();
      final jwt = token ?? prefs.getString('api_token');
      if (jwt == null) {
        _status = 'no_token';
        return false;
      }

      await _push(baseUrl, jwt);
      await _pull(baseUrl, jwt);

      _lastSync = DateTime.now();
      await prefs.setString('last_sync_at', _lastSync!.toIso8601String());
      _status = 'success';
      return true;
    } catch (e) {
      _status = 'error: $e';
      debugPrint('Sync error: $e');
      return false;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> _push(String baseUrl, String token) async {
    final tables = ['sales', 'sale_lines', 'stock_movements', 'clients', 'audit_logs'];
    final data = <String, dynamic>{};

    for (final table in tables) {
      final rows = await _db.query(
        'SELECT * FROM $table WHERE is_synced = FALSE LIMIT 500',
      );
      if (rows.isNotEmpty) {
        data[table] = rows;
      }
    }

    if (data.isEmpty) return;

    final response = await http.post(
      Uri.parse('$baseUrl/api/sync/push'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'data': data}),
    );

    if (response.statusCode != 200) {
      throw Exception('Push failed: ${response.body}');
    }

    for (final table in data.keys) {
      final ids = (data[table] as List).map((r) => r['id']).toList();
      for (final id in ids) {
        await _db.execute(
          'UPDATE $table SET is_synced = TRUE WHERE id = @id',
          parameters: {'id': id},
        );
      }
    }
  }

  Future<void> _pull(String baseUrl, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final since = prefs.getString('last_pull_at');

    final uri = Uri.parse('$baseUrl/api/sync/pull').replace(
      queryParameters: since != null ? {'since': since} : null,
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Pull failed: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final pulled = body['data'] as Map<String, dynamic>? ?? {};

    for (final entry in pulled.entries) {
      final table = entry.key;
      final rows = entry.value as List<dynamic>;
      for (final row in rows) {
        await _upsertCloudRow(table, Map<String, dynamic>.from(row as Map));
      }
    }

    await prefs.setString('last_pull_at', DateTime.now().toIso8601String());
  }

  Future<void> _upsertCloudRow(String table, Map<String, dynamic> row) async {
    row['is_synced'] = true;
    final columns = row.keys.toList();
    final params = <String, dynamic>{};
    for (final c in columns) {
      params[c] = row[c];
    }
    final colList = columns.join(', ');
    final placeholders = columns.map((c) => '@$c').join(', ');

    await _db.execute(
      '''
      INSERT INTO $table ($colList) VALUES ($placeholders)
      ON CONFLICT (id) DO UPDATE SET
        ${columns.where((c) => c != 'id').map((c) => '$c = EXCLUDED.$c').join(', ')}
      ''',
      parameters: params,
    );
  }
}
