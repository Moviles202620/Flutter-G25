import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Stream-based network monitoring.
///
/// Multi-threading strategy: listens on `Connectivity().onConnectivityChanged`
/// (runs on a background isolate provided by the plugin) and broadcasts a
/// boolean on `onConnectivityChanged`. AppState subscribes to this stream so
/// the UI reacts in real-time without polling.
///
/// When `isOnline` transitions false → true, AppState calls
/// SyncService.flushPendingOperations() to drain the offline write queue.
class ConnectivityService {
  static final _controller = StreamController<bool>.broadcast();
  static StreamSubscription<List<ConnectivityResult>>? _sub;
  static bool _isOnline = true;

  static bool get isOnline => _isOnline;

  /// Emits `true` when online, `false` when offline.
  static Stream<bool> get onConnectivityChanged => _controller.stream;

  static void initialize() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });

    // Seed initial state asynchronously (does not block the UI thread).
    _checkInitial();
  }

  static Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    _controller.add(_isOnline);
  }

  static void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
