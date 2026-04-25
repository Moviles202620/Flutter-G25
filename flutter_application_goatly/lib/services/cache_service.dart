import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offer_model.dart';
import '../models/application_model.dart';

/// Tier-1 local storage using SharedPreferences (key-value JSON).
///
/// Stores: offers list, per-offer applicant lists, analytics payloads,
/// timestamps, and the pending-operations queue for offline writes.
class CacheService {
  static const _keyOffers = 'cached_offers';
  static const _keyOffersTs = 'cached_offers_timestamp';
  static const _keyPendingOps = 'pending_operations';
  static const _analyticsPrefix = 'cached_analytics_';

  // ── Offers ────────────────────────────────────────────────────────────────

  static Future<void> saveOffers(List<OfferModel> offers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOffers, jsonEncode(offers.map((o) => o.toJson()).toList()));
    await prefs.setString(_keyOffersTs, DateTime.now().toIso8601String());
  }

  static Future<List<OfferModel>?> loadOffers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyOffers);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => OfferModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<String?> getOffersTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOffersTs);
  }

  // ── Applicants per offer ──────────────────────────────────────────────────

  static Future<void> saveApplicants(String offerId, List<ApplicationModel> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cached_applicants_$offerId',
      jsonEncode(apps.map((a) => a.toJson()).toList()),
    );
  }

  static Future<List<ApplicationModel>?> loadApplicants(String offerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cached_applicants_$offerId');
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Analytics (BQ payloads) ───────────────────────────────────────────────

  static Future<void> saveAnalytics(String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_analyticsPrefix$endpoint', jsonEncode(data));
    await prefs.setString(
      '$_analyticsPrefix${endpoint}_ts',
      DateTime.now().toIso8601String(),
    );
  }

  static Future<Map<String, dynamic>?> loadAnalytics(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_analyticsPrefix$endpoint');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<String?> getAnalyticsTimestamp(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_analyticsPrefix${endpoint}_ts');
  }

  // ── Pending operations queue (offline write queue) ────────────────────────

  /// Returns the current FIFO queue of unsynced write operations.
  static Future<List<Map<String, dynamic>>> loadPendingOps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingOps);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Appends one operation to the tail of the queue.
  static Future<void> enqueuePendingOp(Map<String, dynamic> op) async {
    final ops = await loadPendingOps();
    ops.add(op);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingOps, jsonEncode(ops));
  }

  /// Removes the operation with the given id (called after successful sync).
  static Future<void> removePendingOp(String id) async {
    final ops = await loadPendingOps();
    ops.removeWhere((op) => op['id'] == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingOps, jsonEncode(ops));
  }

  static Future<void> clearPendingOps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingOps);
  }

  static Future<int> pendingOpsCount() async {
    return (await loadPendingOps()).length;
  }
}
