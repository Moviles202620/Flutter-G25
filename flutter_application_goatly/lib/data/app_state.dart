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
      department: 'Departamento de Admisiones',
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

  // ---- APPLICATIONS ----
  void setApplicationStatus(String appId, ApplicationStatus newStatus) {
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx == -1) return;

    _applications[idx].status = newStatus;
    notifyListeners();
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
        category: 'Académico',
        valueCop: 60000,
        dateTime: now.add(const Duration(days: 2)),
        durationHours: 2,
        isOnSite: true,
      ),
      OfferModel(
        id: 'of2',
        title: 'Asistente de Biblioteca',
        category: 'Administrativo',
        valueCop: 50000,
        dateTime: now.add(const Duration(days: 4)),
        durationHours: 3,
        isOnSite: false,
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
      ),
      ApplicationModel(
        id: 'ap2',
        applicantName: 'María García',
        applicantInitials: 'MG',
        offerId: 'of2',
        offerTitle: 'Asistente de Biblioteca',
        createdAt: now.subtract(const Duration(days: 1)),
        status: ApplicationStatus.pending,
      ),
      ApplicationModel(
        id: 'ap3',
        applicantName: 'Carlos Ruiz',
        applicantInitials: 'CR',
        offerId: 'of1',
        offerTitle: 'Monitoría de Cálculo',
        createdAt: now.subtract(const Duration(days: 2)),
        status: ApplicationStatus.pending,
      ),
    ]);

  }
}
