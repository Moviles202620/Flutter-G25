import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/settings_state.dart';

/// Extensión para acceder fácilmente a las traducciones desde cualquier contexto
extension Localization on BuildContext {
  String t(String key) {
    return read<SettingsState>().getString(key);
  }

  SettingsState get settings {
    return read<SettingsState>();
  }
}
