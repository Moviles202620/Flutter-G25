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
      },
      'en': {
        'settings': 'Settings',
        'dark_mode': 'Dark Mode',
        'language': 'Language',
        'change_password': 'Change Password',
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
      }
    };

    return translations[_language]?[key] ?? key;
  }
}
