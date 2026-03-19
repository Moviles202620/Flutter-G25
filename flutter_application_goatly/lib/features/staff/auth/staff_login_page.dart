import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
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
  bool _biometricReady = false; // available AND enabled by user
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  /// Checks if the device has enrolled biometrics AND the user has opted in.
  Future<void> _initBiometric() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    if (available && enabled) {
      final savedEmail = await BiometricService.getSavedEmail();
      if (savedEmail != null) {
        if (mounted) {
          setState(() => _biometricReady = true);
          // Auto-trigger the prompt on launch for a seamless experience
          _handleBiometricLogin();
        }
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Password login ────────────────────────────────────────────────────────

  Future<void> _handlePasswordLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Completa todos los campos');
      return;
    }

    setState(() => _loading = true);

    final appState = context.read<AppState>();
    final ok = appState.login(email: email, password: password);

    setState(() => _loading = false);

    if (!ok) {
      _showError('Credenciales inválidas (debe ser @uniandes.edu.co, mín. 4 caracteres)');
      return;
    }

    // Store auth token for API calls (backend returns token on login)
    appState.setAuthToken('staff_token_${email.hashCode}');

    // Try to load user preferences from backend
    _syncPreferencesFromBackend(appState);

    // Save email for future biometric sessions
    await BiometricService.saveEmail(email);

    // Offer biometric enrollment if not already enabled
    final available = await BiometricService.isAvailable();
    final alreadyEnabled = await BiometricService.isEnabled();
    if (available && !alreadyEnabled && mounted) {
      await _offerBiometricEnrollment(email);
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.shell);
    }
  }

  // ── Biometric login ───────────────────────────────────────────────────────

  Future<void> _handleBiometricLogin() async {
    // Read context-dependent values before any async gap
    final s = context.read<SettingsState>();
    final appState = context.read<AppState>();

    final savedEmail = await BiometricService.getSavedEmail();
    if (savedEmail == null) {
      _showError('No hay sesión guardada para biometría. Inicia sesión con contraseña primero.');
      return;
    }

    final authenticated = await BiometricService.authenticate(
      localizedReason: s.getString('biometric_reason'),
    );

    if (!authenticated) return; // user cancelled or sensor failed — stay on login

    if (mounted) {
      final ok = appState.loginWithBiometric(savedEmail);
      if (!ok) {
        _showError('No se pudo restaurar la sesión. Inicia sesión con contraseña.');
        return;
      }
      appState.setAuthToken('staff_token_${savedEmail.hashCode}');
      _syncPreferencesFromBackend(appState);
      Navigator.pushReplacementNamed(context, Routes.shell);
    }
  }

  // ── Biometric enrollment dialog ───────────────────────────────────────────

  Future<void> _offerBiometricEnrollment(String email) async {
    // Capture context-dependent values before the async gap
    final s = context.read<SettingsState>();

    final biometrics = await BiometricService.getAvailableBiometrics();
    if (!mounted) return;

    // Build a descriptive list of available sensors
    final sensorNames = biometrics.map((b) {
      switch (b) {
        case BiometricType.fingerprint:
          return s.language == 'es' ? 'huella dactilar' : 'fingerprint';
        case BiometricType.face:
          return s.language == 'es' ? 'reconocimiento facial' : 'face recognition';
        default:
          return s.language == 'es' ? 'biometría' : 'biometrics';
      }
    }).join(s.language == 'es' ? ' y ' : ' and ');

    final bodyText = s.language == 'es'
        ? 'Podrás iniciar sesión con $sensorNames en próximos accesos.'
        : 'You can sign in with $sensorNames on future visits.';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.fingerprint, color: AppColors.primaryYellow, size: 28),
            const SizedBox(width: 10),
            Text(s.getString('biometric_enroll_title'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(bodyText, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.getString('biometric_enroll_skip'),
                style: const TextStyle(color: AppColors.greyText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkText,
              foregroundColor: AppColors.primaryYellow,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.getString('biometric_enroll_confirm'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BiometricService.setEnabled(true);
      setState(() => _biometricReady = true);
    }
  }

  // ── Sync preferences from backend ────────────────────────────────────────

  void _syncPreferencesFromBackend(AppState appState) {
    final token = appState.authToken;
    if (token == null) return;
    ApiService.getUserProfile(token).then((profile) {
      if (!mounted) return;
      final settings = context.read<SettingsState>();
      settings.setDarkMode(profile.isDarkMode);
      settings.setLanguage(profile.language);
    }).catchError((_) {}); // best-effort
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // ── Logo ──────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Goatly',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
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

                // ── Login card ────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        offset: Offset(0, 10),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Acceso exclusivo para Staff',
                        style: TextStyle(
                            fontSize: 16, color: AppColors.greyText),
                      ),
                      const SizedBox(height: 22),

                      // Email
                      const Text('Correo institucional',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: 'nombre@uniandes.edu.co',
                          hintStyle:
                              const TextStyle(color: Color(0xFF9AA4B2)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primaryYellow, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Password
                      const Text('Contraseña',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle:
                              const TextStyle(color: Color(0xFF9AA4B2)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primaryYellow, width: 1.5),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.greyText,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Primary login button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkText,
                            foregroundColor: AppColors.primaryYellow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: _loading ? null : _handlePasswordLogin,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primaryYellow,
                                  ),
                                )
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),

                      // ── Biometric button (shown when opt-in is active) ──
                      if (_biometricReady) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.darkText,
                              side: const BorderSide(
                                  color: AppColors.border, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            icon: const Icon(Icons.fingerprint, size: 26),
                            label: const Text(
                              'Usar huella / rostro',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            onPressed: _handleBiometricLogin,
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('¿Problemas para ingresar? ',
                        style: TextStyle(color: AppColors.greyText)),
                    Text('Contacta soporte',
                        style: TextStyle(
                            color: AppColors.primaryYellow,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Privacidad',
                        style: TextStyle(color: Color(0xFF9AA4B2))),
                    SizedBox(width: 22),
                    Text('Términos',
                        style: TextStyle(color: Color(0xFF9AA4B2))),
                    SizedBox(width: 22),
                    Text('Ayuda',
                        style: TextStyle(color: Color(0xFF9AA4B2))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
