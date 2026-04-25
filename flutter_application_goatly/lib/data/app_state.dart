import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/offer_model.dart';
import '../models/application_model.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/secure_storage_service.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';

class AppState extends ChangeNotifier {
  UserModel? _user;

  final List<OfferModel> _offers = [];
  final List<ApplicationModel> _applications = [];
  final List<AppNotification> _notifications = [];

  // ── Connectivity & offline state ──────────────────────────────────────────

  bool _isOnline = true;
  int _pendingOpsCount = 0;
  StreamSubscription<bool>? _connectivitySub;

  bool get isOnline => _isOnline;
  int get pendingOpsCount => _pendingOpsCount;

  // ── Getters ───────────────────────────────────────────────────────────────

  UserModel? get user => _user;
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

  // ── Connectivity monitoring (multi-threading: stream subscription) ─────────

  /// Subscribe to ConnectivityService stream.
  /// When back online: flush the pending-operations queue (fire-and-forget).
  void initConnectivity() {
    _isOnline = ConnectivityService.isOnline;
    _connectivitySub = ConnectivityService.onConnectivityChanged.listen((online) async {
      final wasOffline = !_isOnline;
      _isOnline = online;
      notifyListeners();

      if (online && wasOffline) {
        // Network restored — drain the write queue then refresh offers.
        await SyncService.flushPendingOperations();
        _pendingOpsCount = await SyncService.pendingCount();
        _refreshOffersInBackground();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ── Cache-first startup load ───────────────────────────────────────────────

  /// Called once at startup after login to serve cached data immediately,
  /// then triggers a background network refresh.
  Future<void> loadCachedData() async {
    final cached = await CacheService.loadOffers();
    if (cached != null && cached.isNotEmpty) {
      _offers
        ..clear()
        ..addAll(cached);
      notifyListeners();
    }
    _pendingOpsCount = await SyncService.pendingCount();
    notifyListeners();

    // Fire-and-forget background refresh (multi-threading strategy).
    _refreshOffersInBackground();
  }

  /// Background network fetch — does NOT block the UI thread.
  void _refreshOffersInBackground() {
    Future(() async {
      try {
        final fresh = await ApiService.getOffers();
        await CacheService.saveOffers(fresh);
        _offers
          ..clear()
          ..addAll(fresh);
        notifyListeners();
      } catch (_) {
        // Silently ignore; UI already shows cached data.
      }
    });
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────

  bool login({required String email, required String password}) {
    final e = email.trim().toLowerCase();
    if (!e.endsWith('@uniandes.edu.co')) return false;
    if (password.trim().length < 4) return false;

    _user = UserModel(
      name: 'Funcionario Uniandes',
      email: e,
      department: 'Administrativo',
      university: 'Universidad de los Andes',
    );

    // Persist session token in secure storage for biometric offline unlock.
    SecureStorageService.saveSession(e);

    if (_offers.isEmpty && _applications.isEmpty) _seedMockData();

    notifyListeners();
    return true;
  }

  /// Biometric offline unlock: validates via cached token in secure storage,
  /// no network call required.
  bool loginWithBiometric(String email) {
    final e = email.trim().toLowerCase();
    if (!e.endsWith('@uniandes.edu.co')) return false;

    _user = UserModel(
      name: 'Funcionario Uniandes',
      email: e,
      department: 'Administrativo',
      university: 'Universidad de los Andes',
    );

    if (_offers.isEmpty && _applications.isEmpty) _seedMockData();

    notifyListeners();
    return true;
  }

  void logout() {
    _user = null;
    SecureStorageService.clearTokens();
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

  // ── OFFERS ────────────────────────────────────────────────────────────────

  /// Cache-first offer fetch.
  /// 1. Return cached data immediately (UI renders at once).
  /// 2. Trigger background network refresh asynchronously.
  Future<List<OfferModel>> fetchOffersWithCache() async {
    final cached = await CacheService.loadOffers();
    if (cached != null && cached.isNotEmpty) {
      _offers
        ..clear()
        ..addAll(cached);
      notifyListeners();
    }
    _refreshOffersInBackground();
    return _offers;
  }

  /// Adds an offer in-memory. If online, posts to API; if offline, queues the
  /// write as a pending operation so it syncs on reconnect.
  Future<void> addOfferWithConnectivity(OfferModel offer) async {
    _offers.insert(0, offer);
    notifyListeners();

    if (_isOnline) {
      try {
        final saved = await ApiService.createOffer(offer);
        // Replace temp offer with server-assigned id version.
        final idx = _offers.indexWhere((o) => o.id == offer.id);
        if (idx != -1) _offers[idx] = saved;
        await CacheService.saveOffers(List.from(_offers));
        notifyListeners();
      } catch (_) {
        _queueOfferCreate(offer);
      }
    } else {
      _queueOfferCreate(offer);
    }
  }

  void _queueOfferCreate(OfferModel offer) {
    CacheService.enqueuePendingOp({
      'id': 'op_${DateTime.now().millisecondsSinceEpoch}',
      'method': 'POST',
      'endpoint': '/offers',
      'body': offer.toJson(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    _pendingOpsCount++;
    notifyListeners();
  }

  void addOffer(OfferModel offer) {
    _offers.insert(0, offer);
    notifyListeners();
  }

  // ── APPLICATIONS ──────────────────────────────────────────────────────────

  /// Optimistic status update: applies locally first, queues network call.
  /// If offline the change is still visible; it will sync on reconnect.
  Future<void> setApplicationStatus(
      String appId, ApplicationStatus newStatus) async {
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx == -1) return;

    _applications[idx].status = newStatus;

    final app = _applications[idx];

    if (newStatus == ApplicationStatus.accepted) {
      _addNotification(AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Aplicación aceptada',
        body: '${app.applicantName} fue aceptado/a para "${app.offerTitle}".',
        type: NotificationType.appAccepted,
        createdAt: DateTime.now(),
        relatedId: appId,
      ));
      _addNotification(AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch + 1}',
        title: 'Alerta estudiante',
        body: '${app.applicantName} recibió su notificación de aceptación en "${app.offerTitle}".',
        type: NotificationType.jobMatch,
        createdAt: DateTime.now(),
        relatedId: appId,
      ));
      NotificationService.onApplicationAccepted(app.applicantName, app.offerTitle);
    } else if (newStatus == ApplicationStatus.rejected) {
      _addNotification(AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Aplicación rechazada',
        body: '${app.applicantName} fue rechazado/a de "${app.offerTitle}".',
        type: NotificationType.appRejected,
        createdAt: DateTime.now(),
        relatedId: appId,
      ));
      NotificationService.onApplicationRejected(app.applicantName, app.offerTitle);
    }

    notifyListeners();

    // Enqueue network sync (optimistic — already applied locally).
    if (_isOnline) {
      try {
        await ApiService.updateApplicationStatus(appId, newStatus);
      } catch (_) {
        _queueStatusUpdate(appId, newStatus);
      }
    } else {
      _queueStatusUpdate(appId, newStatus);
    }
  }

  void _queueStatusUpdate(String appId, ApplicationStatus status) {
    CacheService.enqueuePendingOp({
      'id': 'op_${DateTime.now().millisecondsSinceEpoch}',
      'method': 'PATCH',
      'endpoint': '/applications/$appId/status',
      'body': {'status': status.name},
      'createdAt': DateTime.now().toIso8601String(),
    });
    _pendingOpsCount++;
    notifyListeners();
  }

  /// Cache-first applicant load for a specific offer.
  Future<List<ApplicationModel>> fetchApplicantsWithCache(String offerId) async {
    final cached = await CacheService.loadApplicants(offerId);
    final local = getApplicationsByOffer(offerId);

    if (cached != null && cached.isNotEmpty && local.isEmpty) {
      for (final a in cached) {
        if (!_applications.any((x) => x.id == a.id)) {
          _applications.add(a);
        }
      }
      notifyListeners();
    }

    // Background network refresh.
    Future(() async {
      try {
        final fresh = await ApiService.getApplicationsByOffer(offerId);
        await CacheService.saveApplicants(offerId, fresh);
        for (final a in fresh) {
          final idx = _applications.indexWhere((x) => x.id == a.id);
          if (idx == -1) {
            _applications.add(a);
          }
        }
        notifyListeners();
      } catch (_) {}
    });

    return getApplicationsByOffer(offerId);
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
    if (minGpa != null) list = list.where((a) => a.gpa >= minGpa).toList();
    if (semester != null) list = list.where((a) => a.semester == semester).toList();
    if (availability != null && availability.isNotEmpty) {
      list = list.where((a) => a.availability == availability).toList();
    }
    list.sort((a, b) => switch (sortBy) {
          'semester' => a.semester.compareTo(b.semester),
          'date' => b.createdAt.compareTo(a.createdAt),
          _ => b.gpa.compareTo(a.gpa),
        });
    return list;
  }

  // ── RATING ────────────────────────────────────────────────────────────────

  Future<void> completeAndRate({
    required String appId,
    required double rating,
    required String feedback,
    required double punctuality,
    required double quality,
    required double attitude,
  }) async {
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx == -1) return;

    final app = _applications[idx];
    app.isCompleted = true;
    app.rating = rating;
    app.ratingFeedback = feedback;
    app.ratingPunctuality = punctuality;
    app.ratingQuality = quality;
    app.ratingAttitude = attitude;
    app.ratedAt = DateTime.now();

    _addNotification(AppNotification(
      id: 'n${DateTime.now().millisecondsSinceEpoch}',
      title: 'Calificación enviada',
      body: 'Calificaste a ${app.applicantName} con ${rating.toStringAsFixed(1)} estrellas en "${app.offerTitle}".',
      type: NotificationType.ratingSubmitted,
      createdAt: DateTime.now(),
      relatedId: appId,
    ));

    NotificationService.onRatingSubmitted(app.applicantName, rating);

    notifyListeners();
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────

  void _addNotification(AppNotification n) => _notifications.insert(0, n);

  void onOfferPublished(OfferModel offer) {
    _addNotification(AppNotification(
      id: 'n${DateTime.now().millisecondsSinceEpoch}',
      title: 'Oferta publicada',
      body: '"${offer.title}" ya está visible para los estudiantes.',
      type: NotificationType.offerPublished,
      createdAt: DateTime.now(),
      relatedId: offer.id,
    ));
    _addNotification(AppNotification(
      id: 'n${DateTime.now().millisecondsSinceEpoch + 1}',
      title: 'Alerta estudiante',
      body: 'Ana (Psicología, 19) recibió una alerta sobre "${offer.title}".',
      type: NotificationType.jobMatch,
      createdAt: DateTime.now(),
      relatedId: offer.id,
    ));
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notifications[idx].isRead = true;
    notifyListeners();
  }

  void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  // ── SEED ──────────────────────────────────────────────────────────────────

  void _seedMockData() {
    final now = DateTime.now();

    _offers.addAll([
      OfferModel(
        id: 'of1',
        title: 'Monitoría de Cálculo',
        description: 'Se busca monitor para acompañar a estudiantes de primer año en Cálculo Integral y Multivariable.',
        requirements: 'Haber cursado Cálculo I con nota >= 4.0\nDisponibilidad presencial martes y jueves\nExperiencia en tutorías (deseable)',
        category: 'Académico',
        valueCop: 60000,
        dateTime: now.add(const Duration(days: 2)),
        deadline: now.add(const Duration(days: 10)),
        durationHours: 2,
        isOnSite: true,
        location: 'Edificio ML, Salón ML-204',
      ),
      OfferModel(
        id: 'of2',
        title: 'Asistente de Biblioteca',
        description: 'Apoyo en catalogación, atención al usuario y organización de material bibliográfico.',
        requirements: 'Estudiante de cualquier carrera\nDisponibilidad lunes a viernes tarde\nHabilidades de servicio al cliente',
        category: 'Administrativo',
        valueCop: 50000,
        dateTime: now.add(const Duration(days: 4)),
        deadline: now.add(const Duration(days: 14)),
        durationHours: 3,
        isOnSite: false,
        location: '',
      ),
    ]);

    _applications.addAll([
      ApplicationModel(
        id: 'ap1',
        applicantName: 'Juan Pérez',
        applicantInitials: 'JP',
        offerId: 'of1',
        offerTitle: 'Monitoría de Cálculo',
        createdAt: now.subtract(const Duration(hours: 3)),
        status: ApplicationStatus.pending,
        gpa: 4.5,
        semester: 5,
        career: 'Ing. de Sistemas',
        availability: 'part_time',
        motivationLetter: 'Tengo excelente desempeño en Cálculo y me apasiona enseñar.',
      ),
      ApplicationModel(
        id: 'ap2',
        applicantName: 'María García',
        applicantInitials: 'MG',
        offerId: 'of2',
        offerTitle: 'Asistente de Biblioteca',
        createdAt: now.subtract(const Duration(days: 1)),
        status: ApplicationStatus.accepted,
        gpa: 4.1,
        semester: 4,
        career: 'Literatura',
        availability: 'flexible',
        motivationLetter: 'Soy organizada y me encanta el ambiente de la biblioteca.',
        isCompleted: true,
        rating: 4.3,
        ratingFeedback: 'Excelente actitud y puntualidad.',
        ratingPunctuality: 5.0,
        ratingQuality: 4.0,
        ratingAttitude: 4.5,
        ratedAt: now.subtract(const Duration(hours: 2)),
      ),
      ApplicationModel(
        id: 'ap3',
        applicantName: 'Carlos Ruiz',
        applicantInitials: 'CR',
        offerId: 'of1',
        offerTitle: 'Monitoría de Cálculo',
        createdAt: now.subtract(const Duration(days: 2)),
        status: ApplicationStatus.pending,
        gpa: 3.8,
        semester: 6,
        career: 'Matemáticas',
        availability: 'full_time',
        motivationLetter: 'Cursé Cálculo I, II y III con notas superiores a 4.5.',
      ),
      ApplicationModel(
        id: 'ap4',
        applicantName: 'Laura Molina',
        applicantInitials: 'LM',
        offerId: 'of1',
        offerTitle: 'Monitoría de Cálculo',
        createdAt: now.subtract(const Duration(hours: 10)),
        status: ApplicationStatus.pending,
        gpa: 4.8,
        semester: 7,
        career: 'Física',
        availability: 'part_time',
        motivationLetter: 'Soy monitora certificada por el Centro de Español.',
      ),
    ]);

    _notifications.addAll([
      AppNotification(
        id: 'sn1',
        title: 'Nueva postulación',
        body: 'Laura Molina aplicó a "Monitoría de Cálculo".',
        type: NotificationType.newApplication,
        createdAt: now.subtract(const Duration(hours: 10)),
        relatedId: 'ap4',
      ),
      AppNotification(
        id: 'sn2',
        title: 'Nueva postulación',
        body: 'Juan Pérez aplicó a "Monitoría de Cálculo".',
        type: NotificationType.newApplication,
        createdAt: now.subtract(const Duration(hours: 3)),
        relatedId: 'ap1',
      ),
      AppNotification(
        id: 'sn3',
        title: 'Alerta estudiante',
        body: 'Ana (Psicología, 19) recibió una alerta sobre "Monitoría de Cálculo".',
        type: NotificationType.jobMatch,
        createdAt: now.subtract(const Duration(days: 2)),
        relatedId: 'of1',
        isRead: true,
      ),
      AppNotification(
        id: 'sn4',
        title: 'Calificación enviada',
        body: 'Calificaste a María García con 4.3 estrellas en "Asistente de Biblioteca".',
        type: NotificationType.ratingSubmitted,
        createdAt: now.subtract(const Duration(hours: 2)),
        relatedId: 'ap2',
        isRead: true,
      ),
    ]);
  }
}
