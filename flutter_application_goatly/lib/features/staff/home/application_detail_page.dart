import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/application_model.dart';
import 'package:provider/provider.dart';
import '../../../data/app_state.dart';


class ApplicationDetailPage extends StatelessWidget {
  final ApplicationModel app;

  const ApplicationDetailPage({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle de aplicación',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
            children: [
              _ProfileHeaderCard(
                initials: app.applicantInitials,
                name: app.applicantName.replaceAll('Delgado', 'Pérez'), // placeholder
                subtitle: 'Estudiante Uniandes • Ingeniería de Sistemas',
              ),
              const SizedBox(height: 14),

              _SectionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Mensaje / Motivación',
                child: const Text(
                  'Estoy muy interesado en esta monitoría ya que tengo un excelente desempeño académico en el área (Cálculo Integral y Multivariable) y me apasiona enseñar a otros compañeros para que alcancen sus metas. Tengo experiencia previa ayudando a grupos pequeños de estudio.',
                  style: TextStyle(fontSize: 16, height: 1.35, color: AppColors.darkText),
                ),
              ),
              const SizedBox(height: 14),

              _SectionCard(
                icon: Icons.info_outline,
                title: 'Detalles de la oferta',
                child: Column(
                  children: const [
                    _DetailRow(
                      icon: Icons.school_outlined,
                      title: 'Monitoría de Cálculo',
                      subtitle: 'Título de la posición',
                    ),
                    SizedBox(height: 14),
                    _DetailRow(
                      icon: Icons.category_outlined,
                      title: 'Académico',
                      subtitle: 'Categoría',
                    ),
                    SizedBox(height: 14),
                    _DetailRow(
                      icon: Icons.calendar_month_outlined,
                      title: '24 de Oct, 2023',
                      subtitle: 'Enviado el',
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom action bar (Rechazar / Aceptar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Rechazar',
                      icon: Icons.close,
                      background: const Color(0xFFFFEEF0),
                      foreground: AppColors.danger,
                      onTap: () {
                        context.read<AppState>().setApplicationStatus(app.id, ApplicationStatus.rejected);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Aceptar',
                      icon: Icons.check,
                      background: AppColors.success,
                      foreground: Colors.white,
                      onTap: () {
                        context.read<AppState>().setApplicationStatus(app.id, ApplicationStatus.accepted);
                        Navigator.pop(context);
                      },

                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String initials;
  final String name;
  final String subtitle;

  const _ProfileHeaderCard({
    required this.initials,
    required this.name,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              color: AppColors.primaryYellow,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.greyText, fontSize: 15)),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '⚡  DISPONIBLE AHORA',
              style: TextStyle(
                color: Color(0xFF9A5B00),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6B7280)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.greyText)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
