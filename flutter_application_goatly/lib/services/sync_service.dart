import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'cache_service.dart';

/// Processes the offline write queue (pending_operations in SharedPreferences).
///
/// Multi-threading strategy: the flush loop is a sequential async loop —
/// each HTTP request is awaited before the next starts. This avoids race
/// conditions while keeping the main thread free (all I/O on the event loop).
///
/// Called by AppState when ConnectivityService reports a transition to online.
class SyncService {
  // Mirrors ApiService.baseUrl so endpoint changes only need one edit.
  static String get _baseUrl => ApiService.baseUrl;

  static Map<String, String> _buildHeaders({String? token}) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// Drains the pending-operations queue FIFO.
  /// Successful operations are removed; failed ones remain for the next sync.
  static Future<void> flushPendingOperations() async {
    final ops = await CacheService.loadPendingOps();
    if (ops.isEmpty) return;

    for (final op in List<Map<String, dynamic>>.from(ops)) {
      try {
        final id = op['id'] as String;
        final method = (op['method'] as String).toUpperCase();
        final endpoint = op['endpoint'] as String;
        final body = op['body'] as Map<String, dynamic>?;
        final token = op['token'] as String?;
        final headers = _buildHeaders(token: token);

        final uri = Uri.parse('$_baseUrl$endpoint');
        http.Response? res;

        switch (method) {
          case 'POST':
            res = await http
                .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
                .timeout(const Duration(seconds: 10));
          case 'PATCH':
            res = await http
                .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
                .timeout(const Duration(seconds: 10));
          case 'PUT':
            res = await http
                .put(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
                .timeout(const Duration(seconds: 10));
          case 'DELETE':
            res = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));
        }

        if (res != null && res.statusCode >= 200 && res.statusCode < 300) {
          await CacheService.removePendingOp(id);
        }
      } catch (_) {
        // Leave in queue; will retry on next reconnect.
      }
    }
  }

  /// Returns the number of pending write operations still queued.
  static Future<int> pendingCount() => CacheService.pendingOpsCount();
}
