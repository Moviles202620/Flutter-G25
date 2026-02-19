import 'package:flutter/material.dart';
import '../features/staff/auth/staff_login_page.dart';
import '../features/staff/navigation/staff_shell.dart';
import '../features/staff/create/staff_create_offer_form_page.dart';
import '../features/staff/settings/settings_page.dart';

class Routes {
  static const login = '/login';
  static const shell = '/staff';
  static const createOfferForm = '/staff/create/form';
  static const settings = '/settings';

  static final Map<String, WidgetBuilder> map = {
    login: (_) => const StaffLoginPage(),
    shell: (_) => const StaffShell(),
    createOfferForm: (_) => const StaffCreateOfferFormPage(),
    settings: (_) => const SettingsPage(),
  };
}
