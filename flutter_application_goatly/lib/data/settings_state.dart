import 'package:flutter/foundation.dart';

class SettingsState extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'es'; // 'es' o 'en'
  String _currentPassword = 'default1234'; // Contraseña inicial de prueba

  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (lang == 'es' || lang == 'en') {
      _language = lang;
      notifyListeners();
    }
  }

  /// Valida la contraseña actual y cambia a una nueva
  /// Retorna true si es exitoso, false si la contraseña actual es incorrecta
  bool changePassword(String currentPassword, String newPassword) {
    if (currentPassword.trim() == _currentPassword.trim()) {
      _currentPassword = newPassword.trim();
      notifyListeners();
      return true;
    }
    return false;
  }

  String getString(String key) {
    final translations = {
      'es': {
        'settings': 'Configuración',
        'dark_mode': 'Modo oscuro',
        'language': 'Idioma',
        'change_password': 'Cambiar contraseña',
        'biometric_auth': 'Autenticación biométrica',
        'biometric_subtitle_on': 'Huella o rostro activos',
        'biometric_subtitle_off': 'Toca para activar',
        'biometric_not_available': 'Sin biometría registrada en este dispositivo',
        'biometric_reason': 'Confirma tu identidad para acceder a Goatly',
        'biometric_enroll_title': '¿Activar biometría?',
        'biometric_enroll_body': 'Podrás iniciar sesión con tu huella dactilar o reconocimiento facial en próximos accesos.',
        'biometric_enroll_confirm': 'Activar',
        'biometric_enroll_skip': 'Ahora no',
        'biometric_disabled': 'Autenticación biométrica desactivada',
        'app_version': 'Versión de la app',
        'privacy': 'Privacidad',
        'privacy_content': 'Esta es una app de gestión de ofertas laborales de la Universidad de los Andes.',
        'spanish': 'Español',
        'english': 'Inglés',
        'current_password': 'Contraseña actual',
        'new_password': 'Nueva contraseña',
        'confirm_password': 'Confirmar contraseña',
        'update': 'Actualizar',
        'cancel': 'Cancelar',
        'password_changed': 'Contraseña actualizada correctamente',
        'passwords_dont_match': 'Las contraseñas no coinciden',
        'invalid_current_password': 'La contraseña actual es incorrecta',
        'logout': 'Cerrar sesión',
        'home': 'Inicio',
        'create': 'Crear',
        'profile': 'Perfil',
        'recent_applications': 'Aplicaciones recientes',
        'view_all': 'Ver todas',
        'empty_state_title': 'No hay aplicaciones pendientes',
        'empty_state_subtitle': 'Las nuevas aplicaciones aparecerán aquí',
        'my_offers': 'Mis ofertas',
        'no_offers_yet': 'Aún no has publicado ofertas',
        'publish_first_offer': 'Publica tu primera oferta para que\nlos estudiantes puedan postularse.',
        'create_offer': 'Crear oferta',
        'edit_profile': 'Editar perfil',
        'accepted_applications': 'Aplicaciones aceptadas (Pendientes)',
        'today': 'HOY',
        'no_accepted': 'Aún no tienes aplicaciones aceptadas.\nAcepta una desde Home.',
        // ── David's Features ──
        'analytics': 'Analíticas',
        'acceptance_rate': 'Tasa de aceptación',
        'acceptance_rate_dashboard': 'Dashboard de aceptación',
        'total_apps': 'Total aplicaciones',
        'accepted_label': 'Aceptadas',
        'rejected_label': 'Rechazadas',
        'pending_label': 'Pendientes',
        'no_acceptance_data': 'No hay datos de aceptación disponibles',
        'edit_offer': 'Editar oferta',
        'delete_offer': 'Eliminar oferta',
        'delete_offer_confirm': '¿Eliminar esta oferta?',
        'delete_offer_body': 'Esta acción no se puede deshacer.',
        'delete': 'Eliminar',
        'offer_updated': 'Oferta actualizada correctamente',
        'offer_deleted': 'Oferta eliminada correctamente',
        'save': 'Guardar',
        'profile_sync': 'Perfil sincronizado',
        'profile_updated': 'Perfil actualizado correctamente',
        'sync_preferences': 'Sincronizar preferencias',
        'insights': 'Insights',
        'smart_insights': 'Insights inteligentes',
        'total_offers': 'Total ofertas',
        'total_applications': 'Total aplicaciones',
        'overall_acceptance_rate': 'Tasa de aceptación global',
        'most_popular_offer': 'Oferta más popular',
        'least_popular_offer': 'Oferta menos popular',
        'avg_apps_per_offer': 'Promedio apps/oferta',
        'applications_label': 'aplicaciones',
        'loading': 'Cargando...',
        'error_loading': 'Error al cargar datos',
        'retry': 'Reintentar',
        'title': 'Título',
        'description': 'Descripción',
        'requirements': 'Requisitos',
        'category': 'Categoría',
        'value_cop': 'Valor (COP)',
        'duration_hours': 'Duración (horas)',
        'location': 'Ubicación',
        'on_site': 'Presencial',
        'remote': 'Remoto',
        'date': 'Fecha',
        'deadline_label': 'Fecha límite',
        'name': 'Nombre',
        'department': 'Departamento',
      },
      'en': {
        'settings': 'Settings',
        'dark_mode': 'Dark Mode',
        'language': 'Language',
        'change_password': 'Change Password',
        'biometric_auth': 'Biometric Authentication',
        'biometric_subtitle_on': 'Fingerprint or face active',
        'biometric_subtitle_off': 'Tap to enable',
        'biometric_not_available': 'No biometrics enrolled on this device',
        'biometric_reason': 'Confirm your identity to access Goatly',
        'biometric_enroll_title': 'Enable biometrics?',
        'biometric_enroll_body': 'You will be able to sign in with your fingerprint or face recognition on future visits.',
        'biometric_enroll_confirm': 'Enable',
        'biometric_enroll_skip': 'Not now',
        'biometric_disabled': 'Biometric authentication disabled',
        'app_version': 'App Version',
        'privacy': 'Privacy',
        'privacy_content': 'This is a job offer management app for Universidad de los Andes.',
        'spanish': 'Spanish',
        'english': 'English',
        'current_password': 'Current Password',
        'new_password': 'New Password',
        'confirm_password': 'Confirm Password',
        'update': 'Update',
        'cancel': 'Cancel',
        'password_changed': 'Password updated successfully',
        'passwords_dont_match': 'Passwords do not match',
        'invalid_current_password': 'Current password is incorrect',
        'logout': 'Log Out',
        'home': 'Home',
        'create': 'Create',
        'profile': 'Profile',
        'recent_applications': 'Recent Applications',
        'view_all': 'View All',
        'empty_state_title': 'No pending applications',
        'empty_state_subtitle': 'New applications will appear here',
        'my_offers': 'My Offers',
        'no_offers_yet': 'You haven\'t published offers yet',
        'publish_first_offer': 'Publish your first offer so that\nstudents can apply.',
        'create_offer': 'Create Offer',
        'edit_profile': 'Edit Profile',
        'accepted_applications': 'Accepted Applications (Pending)',
        'today': 'TODAY',
        'no_accepted': 'You have no accepted applications yet.\nAccept one from Home.',
        // ── David's Features ──
        'analytics': 'Analytics',
        'acceptance_rate': 'Acceptance Rate',
        'acceptance_rate_dashboard': 'Acceptance Dashboard',
        'total_apps': 'Total Applications',
        'accepted_label': 'Accepted',
        'rejected_label': 'Rejected',
        'pending_label': 'Pending',
        'no_acceptance_data': 'No acceptance data available',
        'edit_offer': 'Edit Offer',
        'delete_offer': 'Delete Offer',
        'delete_offer_confirm': 'Delete this offer?',
        'delete_offer_body': 'This action cannot be undone.',
        'delete': 'Delete',
        'offer_updated': 'Offer updated successfully',
        'offer_deleted': 'Offer deleted successfully',
        'save': 'Save',
        'profile_sync': 'Profile synced',
        'profile_updated': 'Profile updated successfully',
        'sync_preferences': 'Sync preferences',
        'insights': 'Insights',
        'smart_insights': 'Smart Insights',
        'total_offers': 'Total Offers',
        'total_applications': 'Total Applications',
        'overall_acceptance_rate': 'Overall Acceptance Rate',
        'most_popular_offer': 'Most Popular Offer',
        'least_popular_offer': 'Least Popular Offer',
        'avg_apps_per_offer': 'Avg Apps/Offer',
        'applications_label': 'applications',
        'loading': 'Loading...',
        'error_loading': 'Error loading data',
        'retry': 'Retry',
        'title': 'Title',
        'description': 'Description',
        'requirements': 'Requirements',
        'category': 'Category',
        'value_cop': 'Value (COP)',
        'duration_hours': 'Duration (hours)',
        'location': 'Location',
        'on_site': 'On-site',
        'remote': 'Remote',
        'date': 'Date',
        'deadline_label': 'Deadline',
        'name': 'Name',
        'department': 'Department',
      }
    };

    return translations[_language]?[key] ?? key;
  }
}
