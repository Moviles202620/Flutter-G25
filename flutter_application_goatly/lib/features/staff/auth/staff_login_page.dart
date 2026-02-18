import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import 'package:provider/provider.dart';
import '../../../data/app_state.dart';


class StaffLoginPage extends StatelessWidget {
  const StaffLoginPage({super.key});

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

                // Card
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
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Acceso exclusivo para Staff',
                        style: TextStyle(fontSize: 16, color: AppColors.greyText),
                      ),
                      const SizedBox(height: 22),

                      const Text(
                        'Correo institucional',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'nombre@uniandes.edu.co',
                          hintStyle: const TextStyle(color: Color(0xFF9AA4B2)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Contraseña',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(color: Color(0xFF9AA4B2)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Botón ingresar (negro con texto amarillo)
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
                          onPressed: () {
                            // ignore: use_build_context_synchronously
                            final ok = context.read<AppState>().login(
                              email: 'nombre@uniandes.edu.co', // si quieres, luego lo conectamos al TextField
                              password: '1234',
                            );

                            if (!ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Credenciales inválidas (debe ser @uniandes.edu.co)')),
                              );
                              return;
                            }

                            Navigator.pushReplacementNamed(context, Routes.shell);
                          },
                          child: const Text(
                            'Ingresar',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText.withOpacity(0.85),
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
                    Text('¿Problemas para ingresar? ', style: TextStyle(color: AppColors.greyText)),
                    Text('Contacta soporte', style: TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Privacidad', style: TextStyle(color: Color(0xFF9AA4B2))),
                    SizedBox(width: 22),
                    Text('Términos', style: TextStyle(color: Color(0xFF9AA4B2))),
                    SizedBox(width: 22),
                    Text('Ayuda', style: TextStyle(color: Color(0xFF9AA4B2))),
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
