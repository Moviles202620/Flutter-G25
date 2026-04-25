import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/offer_model.dart';
import '../models/application_model.dart';

/// Central HTTP client for the Goatly FastAPI backend.
///
/// Android emulator: baseUrl = 'http://10.0.2.2:8000'
/// Physical device : baseUrl = 'http://YOUR_PC_LAN_IP:8000'
class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Feature 1 ─ Job Posting Creation ─────────────────────────────────────

  /// POST /offers  →  returns the created offer with a server-assigned id.
  static Future<OfferModel> createOffer(OfferModel offer) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/offers'),
          headers: _headers,
          body: jsonEncode(offer.toJson()),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 201) {
      throw ApiException(
          'Error al publicar oferta (${res.statusCode}): ${res.body}');
    }
    return OfferModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// GET /offers  →  all offers published by staff.
  static Future<List<OfferModel>> getOffers() async {
    final res = await http
        .get(Uri.parse('$baseUrl/offers'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException('Error al obtener ofertas (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Feature 2 ─ Applicant List View ──────────────────────────────────────

  /// GET /offers/{offerId}/applications
  static Future<List<ApplicationModel>> getApplicationsByOffer(
      String offerId) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/offers/$offerId/applications'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al obtener aplicaciones (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Feature 3 ─ Applicant Filter ─────────────────────────────────────────

  /// GET /offers/{offerId}/applications?gpa_min=&semester=&availability=
  static Future<List<ApplicationModel>> filterApplications({
    required String offerId,
    double? minGpa,
    int? semester,
    String? availability,
    String? sortBy,
  }) async {
    final query = <String, String>{};
    if (minGpa != null) query['gpa_min'] = minGpa.toStringAsFixed(2);
    if (semester != null) query['semester'] = semester.toString();
    if (availability != null && availability.isNotEmpty) {
      query['availability'] = availability;
    }
    if (sortBy != null) query['sort_by'] = sortBy;

    final uri = Uri.parse('$baseUrl/offers/$offerId/applications')
        .replace(queryParameters: query.isEmpty ? null : query);

    final res = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al filtrar aplicaciones (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Application status ────────────────────────────────────────────────────

  /// PATCH /applications/{appId}/status
  static Future<void> updateApplicationStatus(
      String appId, ApplicationStatus status) async {
    final res = await http
        .patch(
          Uri.parse('$baseUrl/applications/$appId/status'),
          headers: _headers,
          body: jsonEncode({'status': status.name}),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al actualizar estado (${res.statusCode})');
    }
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  /// GET /analytics/time-to-first-application
  ///
  /// BQ7 (Santiago Reyes): Returns the average number of days between offer
  /// publication and receipt of the first application, along with counts.
  static Future<Map<String, dynamic>> getTimeToFirstApplication() async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/analytics/time-to-first-application'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al obtener analítica (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
