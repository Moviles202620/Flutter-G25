import 'package:flutter/material.dart';
import 'app/app.dart';
import 'services/connectivity_service.dart';
import 'services/hive_cache_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await HiveCacheService.init();

  // Start stream-based connectivity monitoring before the app renders.
  // AppState subscribes to this stream via initConnectivity().
  ConnectivityService.initialize();

  runApp(const GoatlyApp());
}
