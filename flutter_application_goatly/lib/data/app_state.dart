import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/application_model.dart';
import '../models/auth_session_model.dart';
import '../models/historical_rating_summary.dart';
import '../models/notification_model.dart';
import '../models/offer_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

class AppState extends ChangeNotifier {
  UserModel? _user;
  String? _authToken;
  String? _refreshToken;
  Uint8List? _profileImageBytes;

  final List<OfferModel> _offers = [];
  final List<ApplicationModel> _applications = [];
  final List<AppNotification> _notifications = [];

  // ── Connectivity & cache ───────────────────────────────────────────────────
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool get isOnline => _isOnline;

  static const _kOffersKey = 'cached_offers';
  static const _kApplicationsKey = 'cached_applications';

  void startConnectivityMonitoring() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && !_isOnline) {
        _isOnline = true;
        notifyListeners();
        loadStaffWorkspace();
        unawaited(SyncService.flushPendingOperations());
      } else if (!online && _isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    });
  }

  void stopConnectivityMonitoring() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Bridge called by app.dart on provider creation to start connectivity monitoring.
  void initConnectivity() => startConnectivityMonitoring();

  Future<void> _persistToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kOffersKey,
      jsonEncode(_offers.map((o) => o.toJson()).toList()),
    );
    await prefs.setString(
      _kApplicationsKey,
      jsonEncode(_applications.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final offersJson = prefs.getString(_kOffersKey);
    final appsJson = prefs.getString(_kApplicationsKey);
    if (offersJson != null) {
      final list = jsonDecode(offersJson) as List<dynamic>;
      _offers
        ..clear()
        ..addAll(list.map((e) => OfferModel.fromJson(e as Map<String, dynamic>)));
    }
    if (appsJson != null) {
      final list = jsonDecode(appsJson) as List<dynamic>;
      _applications
        ..clear()
        ..addAll(list.map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>)));
    }
    if (offersJson != null || appsJson != null) notifyListeners();
  }

  UserModel? get user => _user;
  String? get authToken => _authToken;
  String? get refreshToken => _refreshToken;
  Uint8List? get profileImageBytes => _profileImageBytes;
  bool get isLoggedIn => _user != null;

  List<OfferModel> get offers => List.unmodifiable(_offers);
  List<ApplicationModel> get applications => List.unmodifiable(_applications);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  List<ApplicationModel> get pendingApplications =>
      _applications.where((a) => a.status == ApplicationStatus.pending).toList();

  List<ApplicationModel> get acceptedApplications =>
      _applications.where((a) => a.status == ApplicationStatus.accepted).toList();

  List<ApplicationModel> get completedApplications =>
      _applications.where((a) => a.isCompleted).toList();

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  // ── Offer state helpers ────────────────────────────────────────────────────

  bool isOfferUpcoming(OfferModel offer) => offer.offerState == OfferState.upcoming;
  bool isOfferActive(OfferModel offer) => offer.offerState == OfferState.active;
  bool isOfferClosed(OfferModel offer) => offer.offerState == OfferState.closed;

  /// Active offer (if any) — for Home cockpit hero card.
  OfferModel? get activeOffer {
    try {
      return _offers.firstWhere(isOfferActive);
    } catch (_) {
      return null;
    }
  }

  /// Upcoming offers sorted by date.
  List<OfferModel> get upcomingOffers =>
      _offers.where(isOfferUpcoming).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  /// Closed offers that still have unrated accepted applicants.
  List<OfferModel> get offersWithUnratedStudents {
    return _offers.where((offer) {
      if (!isOfferClosed(offer)) return false;
      return _applications
          .where((a) => a.offerId == offer.id && a.status == ApplicationStatus.accepted && !a.isCompleted)
          .isNotEmpty;
    }).toList();
  }

  Future<bool> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail.endsWith('@uniandes.edu.co')) return false;
    if (password.trim().length < 4) return false;

    try {
      final session = await ApiService.login(normalizedEmail, password);
      if (session.user.role != 'staff') return false;
      await _applySession(session);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loginWithBiometric({required String refreshToken}) async {
    try {
      final accessToken = await ApiService.refreshAccessToken(refreshToken);
      final profile = await ApiService.getUserProfile(accessToken);
      if (profile.role != 'staff') return false;

      final session = AuthSessionModel(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: 'bearer',
        user: profile,
      );
      await _applySession(session);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _applySession(AuthSessionModel session) async {
    _user = UserModel(
      name: session.user.name,
      email: session.user.email,
      department: session.user.department,
      university: 'Universidad de los Andes',
    );
    _authToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _profileImageBytes = null;
    _offers.clear();
    _applications.clear();
    _notifications.clear();
    notifyListeners();
    unawaited(loadStaffWorkspace());
  }

  void logout() {
    _user = null;
    _authToken = null;
    _refreshToken = null;
    _profileImageBytes = null;
    _offers.clear();
    _applications.clear();
    _notifications.clear();
    notifyListeners();
  }

  void updateUserProfile({required String name, required String department}) {
    if (_user == null) return;
    _user = UserModel(
      name: name,
      email: _user!.email,
      department: department,
      university: 'Universidad de los Andes',
    );
    notifyListeners();
  }

  void setProfileImageBytes(Uint8List? bytes) {
    _profileImageBytes = bytes;
    notifyListeners();
  }

  void setAuthToken(String token) {
    _authToken = token;
    notifyListeners();
  }

  OfferModel? getOfferById(String offerId) {
    try {
      return _offers.firstWhere((offer) => offer.id == offerId);
    } catch (_) {
      return null;
    }
  }

  ApplicationModel? getApplicationById(String applicationId) {
    try {
      return _applications.firstWhere(
        (application) => application.id == applicationId,
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? getApplicationCompletionTime(ApplicationModel application) {
    final offer = getOfferById(application.offerId);
    if (offer == null) return null;
    final duration = offer.durationHours > 0 ? offer.durationHours : 0;
    return offer.dateTime.add(Duration(hours: duration));
  }

  bool canRateApplication(ApplicationModel application, {DateTime? now}) {
    if (application.status != ApplicationStatus.accepted || application.isCompleted) {
      return false;
    }
    final offer = getOfferById(application.offerId);
    if (offer == null) return false;
    // Can rate when offer is closed (by time or manually)
    return isOfferClosed(offer);
  }

  HistoricalRatingSummary getHistoricalRatingSummary(String applicantName) {
    final normalizedApplicantName = applicantName.trim().toLowerCase();
    final ratedApplications =
        _applications
            .where(
              (application) =>
                  application.applicantName.trim().toLowerCase() ==
                      normalizedApplicantName &&
                  application.isCompleted &&
                  application.rating != null,
            )
            .toList()
          ..sort((a, b) {
            final firstTimestamp = a.ratedAt ?? a.createdAt;
            final secondTimestamp = b.ratedAt ?? b.createdAt;
            return secondTimestamp.compareTo(firstTimestamp);
          });

    if (ratedApplications.isEmpty) {
      return const HistoricalRatingSummary.empty();
    }

    double totalScore = 0;
    double totalWeighted = 0;

    for (final app in ratedApplications) {
      final overall = app.rating ?? 0;
      totalScore += overall;

      final punctuality = app.ratingPunctuality ?? overall;
      final quality = app.ratingQuality ?? overall;
      final attitude = app.ratingAttitude ?? overall;
      totalWeighted += quality * 0.4 + punctuality * 0.3 + attitude * 0.3;
    }

    final count = ratedApplications.length;
    final lastRatedApplication = ratedApplications.first;

    return HistoricalRatingSummary(
      averageRating: totalScore / count,
      weightedRating: totalWeighted / count,
      ratedJobsCount: count,
      lastRating: lastRatedApplication.rating,
      lastRatedAt: lastRatedApplication.ratedAt,
    );
  }

  Future<void> loadOffersFromBackend() async {
    await loadStaffWorkspace();
  }

  Future<void> loadStaffWorkspace() async {
    final token = _authToken;
    if (token == null) return;

    // Cache-first: render immediately from disk, then refresh from network.
    await _loadFromCache();

    try {
      final myOffers = await ApiService.getMyOffers(token);
      // Parallel fetch: all offer applications concurrently (multi-threading via Future.wait).
      final applicationsByOffer = await Future.wait(
        myOffers.map((offer) => ApiService.getStaffApplicationsByOffer(offer.id, token)),
      );

      _offers
        ..clear()
        ..addAll(myOffers);

      _applications
        ..clear()
        ..addAll(applicationsByOffer.expand((applications) => applications));

      notifyListeners();
      unawaited(_persistToCache()); // fire-and-forget background cache write
    } on ApiException {
      // Network unavailable — cached data already shown, keep it.
    }
  }

  Future<bool> closeOffer(String offerId) async {
    final token = _authToken;
    if (token == null) return false;
    try {
      final updated = await ApiService.closeOffer(offerId, token);
      final idx = _offers.indexWhere((o) => o.id == offerId);
      if (idx != -1) {
        _offers[idx] = updated;
        notifyListeners();
      }
      return true;
    } on ApiException {
      return false;
    }
  }

  void addOffer(OfferModel offer) {
    _offers.insert(0, offer);
    notifyListeners();
  }

  void updateOffer(OfferModel updated) {
    final idx = _offers.indexWhere((o) => o.id == updated.id);
    if (idx != -1) {
      _offers[idx] = updated;
      notifyListeners();
    }
  }

  void removeOffer(String offerId) {
    _offers.removeWhere((o) => o.id == offerId);
    _applications.removeWhere((a) => a.offerId == offerId);
    notifyListeners();
  }

  Future<void> setApplicationStatus(
    String appId,
    ApplicationStatus newStatus,
  ) async {
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx == -1) return;

    _applications[idx].status = newStatus;
    final app = _applications[idx];

    if (newStatus == ApplicationStatus.accepted) {
      _addNotification(
        AppNotification(
          id: 'n${DateTime.now().millisecondsSinceEpoch}',
          title: 'Aplicacion aceptada',
          body: '${app.applicantName} fue aceptado/a para "${app.offerTitle}".',
          type: NotificationType.appAccepted,
          createdAt: DateTime.now(),
          relatedId: appId,
        ),
      );
      _addNotification(
        AppNotification(
          id: 'n${DateTime.now().millisecondsSinceEpoch + 1}',
          title: 'Alerta estudiante',
          body:
              '${app.applicantName} recibio su notificacion de aceptacion en "${app.offerTitle}".',
          type: NotificationType.jobMatch,
          createdAt: DateTime.now(),
          relatedId: appId,
        ),
      );
      NotificationService.onApplicationAccepted(
        app.applicantName,
        app.offerTitle,
      );
    } else if (newStatus == ApplicationStatus.rejected) {
      _addNotification(
        AppNotification(
          id: 'n${DateTime.now().millisecondsSinceEpoch}',
          title: 'Aplicacion rechazada',
          body: '${app.applicantName} fue rechazado/a de "${app.offerTitle}".',
          type: NotificationType.appRejected,
          createdAt: DateTime.now(),
          relatedId: appId,
        ),
      );
      NotificationService.onApplicationRejected(
        app.applicantName,
        app.offerTitle,
      );
    }

    notifyListeners();
  }

  List<ApplicationModel> getApplicationsByOffer(String offerId) =>
      _applications.where((a) => a.offerId == offerId).toList();

  List<ApplicationModel> filterApplicationsLocal({
    required String offerId,
    double? minGpa,
    int? semester,
    String? availability,
    String sortBy = 'gpa',
  }) {
    var list = getApplicationsByOffer(offerId);
    if (minGpa != null) {
      list = list.where((a) => a.gpa >= minGpa).toList();
    }
    if (semester != null) {
      list = list.where((a) => a.semester == semester).toList();
    }
    if (availability != null && availability.isNotEmpty) {
      list = list.where((a) => a.availability == availability).toList();
    }
    list.sort(
      (a, b) => switch (sortBy) {
        'semester' => a.semester.compareTo(b.semester),
        'date' => b.createdAt.compareTo(a.createdAt),
        _ => b.gpa.compareTo(a.gpa),
      },
    );
    return list;
  }

  Future<bool> completeAndRate({
    required String appId,
    required double rating,
    required String feedback,
    required double punctuality,
    required double quality,
    required double attitude,
  }) async {
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx == -1) return false;
    final app = _applications[idx];
    if (!canRateApplication(app)) return false;

    // Persist to backend first
    final token = _authToken;
    if (token != null) {
      try {
        await ApiService.rateApplication(
          appId: appId,
          token: token,
          rating: rating,
          feedback: feedback,
          punctuality: punctuality,
          quality: quality,
          attitude: attitude,
        );
      } on ApiException {
        return false; // Backend sync failed — do not mutate local state
      }
    }

    // Local update (only reached when backend confirmed the rating)
    app.isCompleted = true;
    app.completedAt = DateTime.now();
    app.rating = rating;
    app.ratingFeedback = feedback;
    app.ratingPunctuality = punctuality;
    app.ratingQuality = quality;
    app.ratingAttitude = attitude;
    app.ratedAt = DateTime.now();

    _addNotification(AppNotification(
      id: 'n${DateTime.now().millisecondsSinceEpoch}',
      title: 'Calificacion enviada',
      body: 'Calificaste a ${app.applicantName} con ${rating.toStringAsFixed(1)} estrellas en "${app.offerTitle}".',
      type: NotificationType.ratingSubmitted,
      createdAt: DateTime.now(),
      relatedId: appId,
    ));

    NotificationService.onRatingSubmitted(app.applicantName, rating);
    notifyListeners();
    return true;
  }

  void _addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
  }

  void onOfferPublished(OfferModel offer) {
    _addNotification(
      AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Oferta publicada',
        body: '"${offer.title}" ya esta visible para los estudiantes.',
        type: NotificationType.offerPublished,
        createdAt: DateTime.now(),
        relatedId: offer.id,
      ),
    );
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notifications[idx].isRead = true;
    notifyListeners();
  }

  void markAllNotificationsRead() {
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }
}
