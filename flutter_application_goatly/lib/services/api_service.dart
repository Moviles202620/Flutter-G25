import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_session_model.dart';
import '../models/offer_model.dart';
import '../models/application_model.dart';
import '../models/acceptance_rate_model.dart';
import '../models/insights_model.dart';
import '../models/user_profile_model.dart';
import '../models/gpa_analytics_model.dart';
import '../models/top_applicant_model.dart';
import '../models/application_search_model.dart';
import '../models/applications_per_semester_model.dart';

/// Central HTTP client for the Goatly FastAPI backend.
/// Requires `adb reverse tcp:8000 tcp:8000` when running on a physical device.
class ApiService {
  static String get baseUrl => 'http://localhost:8000';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<AuthSessionModel> login(String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw ApiException(
          'Error al iniciar sesion (${res.statusCode}): ${res.body}',
        );
      }

      return AuthSessionModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const NetworkException();
    }
  }

  static Future<String> refreshAccessToken(String refreshToken) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/refresh'),
          headers: _headers,
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
        'Error al refrescar sesion (${res.statusCode}): ${res.body}',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['access_token'] as String;
  }

  // ── Feature 1 ─ Job Posting Creation ─────────────────────────────────────

  /// POST /offers  →  returns the created offer with a server-assigned id.
  static Future<OfferModel> createOffer(OfferModel offer, String token) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/offers'),
          headers: _authHeaders(token),
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

  static Future<List<OfferModel>> getMyOffers(String token, {String? state}) async {
    final uri = Uri.parse('$baseUrl/offers/my').replace(
      queryParameters: state != null ? {'state': state} : null,
    );
    final res = await http
        .get(uri, headers: _authHeaders(token))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException('Error al obtener mis ofertas (${res.statusCode})');
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

  /// GET /offers/{offerId}/staff-applications
  /// Returns applicants filtered by offer lifecycle state (server-side):
  /// upcoming → all; active → accepted only; closed → accepted only.
  static Future<List<ApplicationModel>> getStaffApplicationsByOffer(
      String offerId, String token) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/offers/$offerId/staff-applications'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException('Error al obtener aplicantes (${res.statusCode})');
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

  /// POST /applications/{appId}/rate
  static Future<void> rateApplication({
    required String appId,
    required String token,
    required double rating,
    required String feedback,
    required double punctuality,
    required double quality,
    required double attitude,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/applications/$appId/rate'),
          headers: _authHeaders(token),
          body: jsonEncode({
            'rating': rating,
            'rating_feedback': feedback,
            'rating_punctuality': punctuality,
            'rating_quality': quality,
            'rating_attitude': attitude,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException('Error al calificar (${res.statusCode}): ${res.body}');
    }
  }

  // ── David's Features ────────────────────────────────────────────────────

  // ── Feature 1 (David) ─ Acceptance Rate Dashboard ──────────────────────

  /// GET /analytics/acceptance-rate
  static Future<List<AcceptanceRateModel>> getAcceptanceRates() async {
    final res = await http
        .get(Uri.parse('$baseUrl/analytics/acceptance-rate'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al obtener tasas de aceptación (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => AcceptanceRateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Feature 2 (David) ─ Offer Edit & Delete ────────────────────────────

  /// PUT /offers/{offerId}  →  updated OfferModel
  static Future<OfferModel> updateOffer(
      String offerId, Map<String, dynamic> fields) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/offers/$offerId'),
          headers: _headers,
          body: jsonEncode(fields),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al actualizar oferta (${res.statusCode}): ${res.body}');
    }
    return OfferModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// DELETE /offers/{offerId}
  static Future<void> deleteOffer(String offerId) async {
    final res = await http
        .delete(Uri.parse('$baseUrl/offers/$offerId'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al eliminar oferta (${res.statusCode})');
    }
  }

  /// POST /offers/{offerId}/close  →  returns updated OfferModel with state='closed'
  static Future<OfferModel> closeOffer(String offerId, String token) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/offers/$offerId/close'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException('Error al cerrar oferta (${res.statusCode}): ${res.body}');
    }
    return OfferModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Feature 3 (David) ─ User Profile & Theme Sync ─────────────────────

  /// Helper to build headers with auth token.
  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// GET /users/me
  static Future<UserProfileModel> getUserProfile(String token) async {
    final res = await http
        .get(Uri.parse('$baseUrl/users/me'), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al obtener perfil (${res.statusCode})');
    }
    return UserProfileModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// PUT /users/me
  static Future<UserProfileModel> updateUserProfile(
      String token, Map<String, dynamic> fields) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/users/me'),
          headers: _authHeaders(token),
          body: jsonEncode(fields),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al actualizar perfil (${res.statusCode}): ${res.body}');
    }
    return UserProfileModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Feature 4 (David) ─ Smart Offer Insights ──────────────────────────

  /// GET /analytics/insights
  static Future<InsightsModel> getInsights() async {
    final res = await http
        .get(Uri.parse('$baseUrl/analytics/insights'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al obtener insights (${res.statusCode})');
    }
    return InsightsModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Guillermo's Features ────────────────────────────────────────────────

  // ── Feature 1 (Guillermo) ─ GPA Analytics Dashboard (BQ2) ─────────────

  /// GET /analytics/gpa-by-offer
  /// Returns average GPA per offer with min/max breakdown.
  static Future<List<GpaAnalyticsModel>> getGpaByOffer() async {
    final res = await http
        .get(Uri.parse('$baseUrl/analytics/gpa-by-offer'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al obtener GPA por oferta (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => GpaAnalyticsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Feature 2 (Guillermo) ─ Application Search ─────────────────────────

  /// GET /applications/search?q=&semester=&career=
  /// Searches applications across all offers.
  static Future<List<ApplicationSearchModel>> searchApplications({
    String? q,
    int? semester,
    String? career,
  }) async {
    final query = <String, String>{};
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (semester != null) query['semester'] = semester.toString();
    if (career != null && career.isNotEmpty) query['career'] = career;

    final uri = Uri.parse('$baseUrl/applications/search')
        .replace(queryParameters: query.isEmpty ? null : query);

    final res = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al buscar aplicaciones (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ApplicationSearchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Feature 4 (Guillermo) ─ Top Applicants Leaderboard ────────────────

  /// GET /analytics/top-applicants?limit=10
  /// Returns the top applicants ranked by GPA across all offers.
  static Future<List<TopApplicantModel>> getTopApplicants({
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/analytics/top-applicants')
        .replace(queryParameters: {'limit': limit.toString()});

    final res = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al obtener top aplicantes (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => TopApplicantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Feature BQ10 (Guillermo) ─ Applications per Semester ─────────────

  /// GET /analytics/applications-per-semester
  /// BQ10: Total applications and unique students grouped by academic semester.
  static Future<List<ApplicationsPerSemesterModel>> getApplicationsPerSemester() async {
    final uri = Uri.parse('$baseUrl/analytics/applications-per-semester');
    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException('Error al obtener apps por semestre (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ApplicationsPerSemesterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── BQ9 (David Hernandez) ─ GPA High Rate per Offer ───────────────────

  /// GET /analytics/gpa-high-rate
  /// BQ9: Percentage of applicants with GPA >= 4.0 per offer.
  static Future<List<Map<String, dynamic>>> getGpaHighRate() async {
    final res = await http
        .get(Uri.parse('$baseUrl/analytics/gpa-high-rate'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al obtener GPA high rate (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // ── BQ13 (David Hernandez) ─ Status Distribution per Semester ────────────

  /// GET /analytics/status-distribution[?semester=YYYY-N]
  /// BQ13: Distribution of pending/accepted/rejected applications this semester.
  /// Returns a Map with keys: semester, total_applications, distribution, per_offer.
  static Future<Map<String, dynamic>> getStatusDistribution({String? semester}) async {
    final uri = semester != null
        ? Uri.parse('$baseUrl/analytics/status-distribution?semester=$semester')
        : Uri.parse('$baseUrl/analytics/status-distribution');

    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al obtener distribución de estados (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── BQ7 (Santiago Reyes) ─ Time to First Application ──────────────────

  /// GET /analytics/time-to-first-application
  /// BQ7: Average days between offer publication and first application received.
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

  // ── BQ11 (Santiago Reyes) ─ Offer Lifecycle ────────────────────────────

  /// GET /analytics/offer-lifecycle
  /// BQ11: Average, min, max days an offer stays open + total closed offers.
  static Future<Map<String, dynamic>> getOfferLifecycle() async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/analytics/offer-lifecycle'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw ApiException(
          'Error al obtener ciclo de vida de ofertas (${res.statusCode})');
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

class NetworkException implements Exception {
  const NetworkException();
}
