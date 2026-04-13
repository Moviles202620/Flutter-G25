import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../services/api_service.dart';
import '../../../services/biometric_service.dart';

class StaffLoginPage extends StatefulWidget {
  const StaffLoginPage({super.key});

  @override
  State<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _biometricReady = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _initBiometric() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    if (!available || !enabled) return;

    final savedEmail = await BiometricService.getSavedEmail();
    if (savedEmail == null || !mounted) return;

    setState(() => _biometricReady = true);
    _handleBiometricLogin();
  }

  Future<void> _handlePasswordLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(context.t('err_fill_fields'));
      return;
    }

    setState(() => _loading = true);

    final appState = context.read<AppState>();
    final ok = await appState.login(email: email, password: password);

    if (mounted) {
      setState(() => _loading = false);
    }

    if (!ok) {
      _showError(context.t('err_invalid_credentials'));
      return;
    }

    _syncPreferencesFromBackend(appState);
    await BiometricService.saveEmail(email);
    final refreshToken = appState.refreshToken;
    if (refreshToken != null) {
      await BiometricService.saveRefreshToken(refreshToken);
    }

    final available = await BiometricService.isAvailable();
    final alreadyEnabled = await BiometricService.isEnabled();
    if (available && !alreadyEnabled && mounted) {
      await _offerBiometricEnrollment();
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.shell);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final settings = context.read<SettingsState>();
    final appState = context.read<AppState>();
    final noSessionMsg = context.t('err_no_biometric_session');
    final restoreFailMsg = context.t('err_restore_session');

    final savedEmail = await BiometricService.getSavedEmail();
    if (savedEmail == null) {
      _showError(noSessionMsg);
      return;
    }

    final authenticated = await BiometricService.authenticate(
      localizedReason: settings.getString('biometric_reason'),
    );

    if (!authenticated || !mounted) return;

    final savedRefreshToken = await BiometricService.getSavedRefreshToken();
    if (savedRefreshToken == null) {
      _showError(noSessionMsg);
      return;
    }

    final ok = await appState.loginWithBiometric(
      refreshToken: savedRefreshToken,
    );
    if (!ok) {
      _showError(restoreFailMsg);
      return;
    }

    _syncPreferencesFromBackend(appState);
    Navigator.pushReplacementNamed(context, Routes.shell);
  }

  Future<void> _offerBiometricEnrollment() async {
    final settings = context.read<SettingsState>();
    final biometrics = await BiometricService.getAvailableBiometrics();
    if (!mounted) return;

    final sensorNames = biometrics
        .map((biometric) {
          switch (biometric) {
            case BiometricType.fingerprint:
              return settings.getString('fingerprint_word');
            case BiometricType.face:
              return settings.getString('face_word');
            default:
              return settings.getString('biometrics_word');
          }
        })
        .join(settings.getString('and_word'));

    final bodyText =
        '${settings.getString('biometric_enabled_prefix')} $sensorNames ${settings.getString('biometric_enabled_suffix')}';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.fingerprint,
              color: AppColors.primaryYellow,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              settings.getString('biometric_enroll_title'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(bodyText, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              settings.getString('biometric_enroll_skip'),
              style: const TextStyle(color: AppColors.greyText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkText,
              foregroundColor: AppColors.primaryYellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              settings.getString('biometric_enroll_confirm'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BiometricService.setEnabled(true);
      if (mounted) {
        setState(() => _biometricReady = true);
      }
    }
  }

  void _syncPreferencesFromBackend(AppState appState) {
    final token = appState.authToken;
    if (token == null) return;

    ApiService.getUserProfile(token)
        .then((profile) {
          if (!mounted) return;
          final settings = context.read<SettingsState>();
          settings.setDarkMode(profile.isDarkMode);
          settings.setLanguage(profile.language);
        })
        .catchError((_) {});
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryText = isDark ? AppColors.darkModeText : AppColors.darkText;
    final secondaryText = isDark ? AppColors.darkGreyText : AppColors.greyText;
    final inputFill = isDark ? const Color(0xFF202020) : Colors.white;
    final logoColor = isDark ? AppColors.primaryYellow : AppColors.darkText;
    final primaryButtonBg = isDark ? AppColors.primaryYellow : AppColors.darkText;
    final primaryButtonFg = isDark ? Colors.black : AppColors.primaryYellow;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Goatly',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: logoColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                          color: isDark
                              ? const Color(0x22000000)
                              : const Color(0x14000000),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('login_title'),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.t('staff_access'),
                          style: TextStyle(fontSize: 16, color: secondaryText),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          context.t('email_label'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: TextStyle(color: primaryText),
                          decoration: _inputDecoration(
                            border: border,
                            fillColor: inputFill,
                            hintColor: secondaryText,
                            hintText: 'nombre@uniandes.edu.co',
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          context.t('password_label'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: primaryText),
                          decoration: _inputDecoration(
                            border: border,
                            fillColor: inputFill,
                            hintColor: secondaryText,
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: secondaryText,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryButtonBg,
                              foregroundColor: primaryButtonFg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: _loading ? null : _handlePasswordLogin,
                            child: _loading
                                ? CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: primaryButtonFg,
                                  )
                                : Text(
                                    context.t('login_btn'),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        if (_biometricReady) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryText,
                                side: BorderSide(color: border, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              icon: const Icon(Icons.fingerprint, size: 26),
                              label: Text(
                                context.t('use_biometrics'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: _handleBiometricLogin,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Divider(color: border),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            context.t('forgot_password'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primaryText.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.t('login_help_prefix'),
                        style: TextStyle(color: secondaryText),
                      ),
                      Text(
                        context.t('contact_support'),
                        style: const TextStyle(
                          color: AppColors.primaryYellow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.t('privacy'),
                        style: TextStyle(color: secondaryText),
                      ),
                      const SizedBox(width: 22),
                      Text(
                        context.t('terms'),
                        style: TextStyle(color: secondaryText),
                      ),
                      const SizedBox(width: 22),
                      Text(
                        context.t('help'),
                        style: TextStyle(color: secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required Color border,
    required Color fillColor,
    required Color hintColor,
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.primaryYellow,
          width: 1.5,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }
}
