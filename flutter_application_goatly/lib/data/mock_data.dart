import '../models/application_model.dart';

class MockData {
  // Para probar empty state, deja esto como []
  static List<ApplicationModel> applications = [
    ApplicationModel(
      id: '1',
      applicantName: 'Juan Delgado',
      offerId:'offer1',
      offerTitle: 'Monitoría de Cálculo',
      applicantInitials: 'JD',
      createdAt: DateTime.now().subtract(const Duration(days: 2)) ,
      status: ApplicationStatus.pending,
    ),
    ApplicationModel(
      id: '2',
      applicantName: 'Maria Lopez',
      offerId:'offer2',
      offerTitle: 'Desarrollo de Aplicación Móvil',
      applicantInitials: 'ML',
      createdAt: DateTime.now().subtract(const Duration(days: 1)) ,
      status: ApplicationStatus.accepted,
    ),
    ApplicationModel(
      id: '3',
      applicantName: 'Ricardo Castro',
      offerId:'offer3',
      offerTitle: 'Diseño de Interfaz de Usuario',
      applicantInitials: 'RC',
      createdAt: DateTime.now().subtract(const Duration(days: 3)) ,
      status: ApplicationStatus.pending,
    ),
    ApplicationModel(
      id: '4',
      applicantName: 'Sofia Vega',
      offerId:'offer4',
      offerTitle: 'Análisis de Datos',
      applicantInitials: 'SV',
      createdAt: DateTime.now().subtract(const Duration(days: 4)) ,
      status: ApplicationStatus.pending,
    ),
    ApplicationModel(
      id: '5',
      applicantName: 'Andrés Morales',
      offerId:'offer5',
      offerTitle: 'Desarrollo de Backend',
      applicantInitials: 'AM',
      createdAt: DateTime.now().subtract(const Duration(days: 5)) ,
      status: ApplicationStatus.rejected,
    ),
  ];
}
