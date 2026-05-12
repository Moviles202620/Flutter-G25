import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Tier-2 local storage using Hive (key-value, fast disk I/O).
///
/// Stores analytics payloads as JSON strings — synchronous reads after
/// init() since boxes are fully loaded into memory by Hive at startup.
class HiveCacheService {
  static const _analyticsBox = 'analytics_box';
  static const _tsBox = 'analytics_ts_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_analyticsBox);
    await Hive.openBox(_tsBox);
  }

  static Future<void> saveAnalytics(
      String key, Map<String, dynamic> data) async {
    final box = Hive.box(_analyticsBox);
    final tsBox = Hive.box(_tsBox);
    await box.put(key, jsonEncode(data));
    await tsBox.put(key, DateTime.now().toIso8601String());
  }

  // Synchronous — box is already in memory after init().
  static Map<String, dynamic>? loadAnalytics(String key) {
    final box = Hive.box(_analyticsBox);
    final raw = box.get(key);
    if (raw == null) return null;
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  static String? getTimestamp(String key) {
    return Hive.box(_tsBox).get(key) as String?;
  }

  static Future<void> clear() async {
    await Hive.box(_analyticsBox).clear();
    await Hive.box(_tsBox).clear();
  }
}
