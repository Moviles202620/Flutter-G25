import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/offer_model.dart';
import '../models/application_model.dart';

class AppState extends ChangeNotifier {
  UserModel? _user;

  final List<OfferModel> _offers = [];
  final List<ApplicationModel> _applications = [];

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  List<OfferModel> get offers => List.unmodifiable(_offers);
  List<ApplicationModel> get applications => List.unmodifiable(_applications);

  List<ApplicationModel> get pendingApplications =>
      _applications.where((a) => a.status == ApplicationStatus.pending).toList();

  List<ApplicationModel> get acceptedApplications =>
      _applications.where((a) => a.status == ApplicationStatus.accepted).toList();

  // ---- AUTH ----
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

    if (_offers.isEmpty && _applications.isEmpty) {
      _seedMockData();
    }

    notifyListeners();
    return true;
  }

  /// Logs in using a previously verified biometric — no password required.
  bool loginWithBiometric(String email) {
    final e = email.trim().toLowerCase();
    if (!e.endsWith('@uniandes.edu.co')) return false;

    _user = UserModel(
      name: 'Funcionario Uniandes',
      email: e,
      department: 'Administrativo',
      university: 'Universidad de los Andes',
    );

    if (_offers.isEmpty && _applications.isEmpty) {
      _seedMockData();
    }

    notifyListeners();
    return true;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  void updateUserProfile({
    required String name,
    required String department,
  }) {
    if (_user == null) return;
    _user = UserModel(
      name: name,
      email: _user!.email,
      department: department,
      university: 'Universidad de los Andes',
    );
    notifyListeners();
  }

  // ---- APPLICATIONS ----
  void setApplicationStatus(String appId, ApplicationStatus newStatus) {
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx == -1) return;
    _applications[idx].status = newStatus;
    notifyListeners();
  }

  /// Returns all applications for a given offer (local fallback for Feature 2).
  List<ApplicationModel> getApplicationsByOffer(String offerId) =>
      _applications.where((a) => a.offerId == offerId).toList();

  /// Filters and re-ranks applications locally (fallback for Feature 3).
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

    list.sort((a, b) => switch (sortBy) {
          'semester' => a.semester.compareTo(b.semester),
          'date' => b.createdAt.compareTo(a.createdAt),
          _ => b.gpa.compareTo(a.gpa), // default: highest GPA first
        });

    return list;
  }

  // ---- OFFERS ----
  void addOffer(OfferModel offer) {
    _offers.insert(0, offer);
    notifyListeners();
  }

  // ---- Mock seed ----
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
        status: ApplicationStatus.pending,
        gpa: 4.1,
        semester: 4,
        career: 'Literatura',
        availability: 'flexible',
        motivationLetter:
            'Soy organizada y me encanta el ambiente de la biblioteca. Tengo experiencia voluntaria en el colegio catalogando material.',
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
            'Cursé Cálculo I, II y III con notas superiores a 4.5. Quiero compartir mis conocimientos y ganar experiencia pedagógica.',
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
            'Soy monitora certificada por el Centro de Español. Me interesa expandir mi labor a matemáticas.',
      ),
    ]);
  }
}
