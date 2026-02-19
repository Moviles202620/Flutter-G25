import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../data/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        surfaceTintColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.watch<SettingsState>().getString('settings'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Dark Mode
          _SettingTile(
            icon: Icons.dark_mode_rounded,
            title: context.watch<SettingsState>().getString('dark_mode'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            trailing: Switch(
              value: context.watch<SettingsState>().isDarkMode,
              onChanged: (value) {
                context.read<SettingsState>().setDarkMode(value);
              },
              activeColor: AppColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 12),

          // Language
          _TapableSetting(
            icon: Icons.language_rounded,
            title: context.watch<SettingsState>().getString('language'),
            subtitle: context.watch<SettingsState>().language == 'es'
                ? context.read<SettingsState>().getString('spanish')
                : context.read<SettingsState>().getString('english'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            onTap: () => _showLanguageDialog(context),
          ),
          const SizedBox(height: 12),

          // Change Password
          _TapableSetting(
            icon: Icons.lock_rounded,
            title: context.watch<SettingsState>().getString('change_password'),
            subtitle: '••••••••',
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            onTap: () => _showChangePasswordDialog(context),
          ),
          const SizedBox(height: 12),

          // App Version
          _TapableSetting(
            icon: Icons.info_rounded,
            title: context.watch<SettingsState>().getString('app_version'),
            subtitle: '1.0.0',
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            onTap: null,
          ),
          const SizedBox(height: 12),

          // Privacy
          _TapableSetting(
            icon: Icons.privacy_tip_rounded,
            title: context.watch<SettingsState>().getString('privacy'),
            subtitle: 'Ver detalles',
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            onTap: () => _showPrivacyDialog(context),
          ),
          const SizedBox(height: 32),

          // Logout Button
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(
                    context.read<SettingsState>().getString('logout'),
                  ),
                  content: const Text('¿Deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        context.read<SettingsState>().getString('cancel'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      },
                      child: Text(
                        context.read<SettingsState>().getString('logout'),
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  context.watch<SettingsState>().getString('logout'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final settings = context.read<SettingsState>();
        return AlertDialog(
          title: Text(settings.getString('language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(settings.getString('spanish')),
                leading: Radio(
                  value: 'es',
                  groupValue: settings.language,
                  onChanged: (value) {
                    if (value != null) {
                      settings.setLanguage(value);
                      Navigator.pop(ctx);
                    }
                  },
                  activeColor: AppColors.primaryYellow,
                ),
              ),
              ListTile(
                title: Text(settings.getString('english')),
                leading: Radio(
                  value: 'en',
                  groupValue: settings.language,
                  onChanged: (value) {
                    if (value != null) {
                      settings.setLanguage(value);
                      Navigator.pop(ctx);
                    }
                  },
                  activeColor: AppColors.primaryYellow,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final settings = context.read<SettingsState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(settings.getString('change_password')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: settings.getString('current_password'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: settings.getString('new_password'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: settings.getString('confirm_password'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(settings.getString('cancel')),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(settings.getString('passwords_dont_match')),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }

              if (newPasswordCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('La contraseña no puede estar vacía'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }

              // Intenta cambiar la contraseña
              final success = settings.changePassword(
                currentPasswordCtrl.text,
                newPasswordCtrl.text,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(settings.getString('password_changed')),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pop(ctx);
                currentPasswordCtrl.dispose();
                newPasswordCtrl.dispose();
                confirmPasswordCtrl.dispose();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(settings.getString('invalid_current_password')),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: Text(settings.getString('update')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final settings = context.read<SettingsState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(settings.getString('privacy')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.getString('privacy_content'),
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Datos personales y privacidad:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Tus datos están protegidos según las políticas de la Universidad '
                'de los Andes.\n'
                '• No compartimos tu información con terceros.\n'
                '• Puedes solicitar la eliminación de tu cuenta en cualquier momento.\n'
                '• Utilizamos encriptación para proteger tus credenciales.',
                style: TextStyle(height: 1.6, fontSize: 14, color: AppColors.greyText),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(settings.getString('cancel')),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final Color surfaceColor;
  final Color borderColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.surfaceColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryYellow),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _TapableSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color surfaceColor;
  final Color borderColor;

  const _TapableSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.surfaceColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryYellow),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.greyText),
          ],
        ),
      ),
    );
  }
}
