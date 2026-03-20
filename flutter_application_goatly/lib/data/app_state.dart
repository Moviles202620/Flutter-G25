import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/offer_model.dart';
import '../models/application_model.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  UserModel? _user;
  String? _authToken;

  final List<OfferModel> _offers = [];
  final List<ApplicationModel> _applications = [];
  final List<AppNotification> _notifications = [];

  UserModel? get user => _user;
  String? get authToken => _authToken;
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

    if (_offers.isEmpty && _applications.isEmpty) _seedMockData();

    notifyListeners();
    return true;
  }

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

  void setAuthToken(String token) {
    _authToken = token;
    notifyListeners();
  }

  // ── OFFERS ────────────────────────────────────────────────────────────────

  Future<void> loadOffersFromBackend() async {
    try {
      final offers = await ApiService.getOffers();
      _offers.clear();
      _offers.addAll(offers);
      notifyListeners();
    } on ApiException {
      // Mantener los datos existentes si el backend no responde
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
    notifyListeners();
  }

  // ── APPLICATIONS ──────────────────────────────────────────────────────────

  /// Updates status and adds an in-app notification + fires an OS banner.
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
      // Simulate student notification
      _addNotification(AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch + 1}',
        title: 'Alerta estudiante',
        body:
            '${app.applicantName} recibió su notificación de aceptación en "${app.offerTitle}".',
        type: NotificationType.jobMatch,
        createdAt: DateTime.now(),
        relatedId: appId,
      ));
      NotificationService.onApplicationAccepted(
          app.applicantName, app.offerTitle);
    } else if (newStatus == ApplicationStatus.rejected) {
      _addNotification(AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Aplicación rechazada',
        body: '${app.applicantName} fue rechazado/a de "${app.offerTitle}".',
        type: NotificationType.appRejected,
        createdAt: DateTime.now(),
        relatedId: appId,
      ));
      NotificationService.onApplicationRejected(
          app.applicantName, app.offerTitle);
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

  // ── RATING (Feature 8) ────────────────────────────────────────────────────

  /// Marks an accepted application as completed and saves the professor's rating.
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
      body:
          'Calificaste a ${app.applicantName} con ${rating.toStringAsFixed(1)} estrellas en "${app.offerTitle}".',
      type: NotificationType.ratingSubmitted,
      createdAt: DateTime.now(),
      relatedId: appId,
    ));

    NotificationService.onRatingSubmitted(app.applicantName, rating);

    notifyListeners();
  }

  // ── NOTIFICATIONS (Feature 7) ─────────────────────────────────────────────

  void _addNotification(AppNotification n) => _notifications.insert(0, n);

  /// Call this from the offer form after a successful publish.
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
        description:
            'Se busca monitor para acompañar a estudiantes de primer año en Cálculo Integral y Multivariable.',
        requirements:
            'Haber cursado Cálculo I con nota >= 4.0\nDisponibilidad presencial martes y jueves\nExperiencia en tutorías (deseable)',
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
        description:
            'Apoyo en catalogación, atención al usuario y organización de material bibliográfico.',
        requirements:
            'Estudiante de cualquier carrera\nDisponibilidad lunes a viernes tarde\nHabilidades de servicio al cliente',
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
        motivationLetter:
            'Tengo excelente desempeño en Cálculo y me apasiona enseñar. Ayudé a grupos de estudio el semestre pasado con muy buenos resultados.',
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
        motivationLetter:
            'Soy organizada y me encanta el ambiente de la biblioteca.',
        isCompleted: true,
        rating: 4.3,
        ratingFeedback:
            'Excelente actitud y puntualidad. Terminó todas las tareas antes del plazo.',
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
        motivationLetter:
            'Cursé Cálculo I, II y III con notas superiores a 4.5.',
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
        motivationLetter:
            'Soy monitora certificada por el Centro de Español.',
      ),
    ]);

    // Seed notifications
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
