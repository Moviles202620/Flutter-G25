import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/application_model.dart';
import 'package:provider/provider.dart';
import '../../../data/app_state.dart';
import '../../../services/api_service.dart';

class ApplicationDetailPage extends StatelessWidget {
  final ApplicationModel app;

  const ApplicationDetailPage({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final availLabel = switch (app.availability) {
      'full_time' => 'Tiempo completo',
      'part_time' => 'Medio tiempo',
      _ => 'Flexible',
    };

    final availColor = switch (app.availability) {
      'full_time' => AppColors.success,
      'part_time' => const Color(0xFF3B82F6),
      _ => AppColors.greyText,
    };

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
              // ── Profile header ────────────────────────────────────────
              _ProfileHeaderCard(
                initials: app.applicantInitials,
                name: app.applicantName,
                career: app.career.isNotEmpty
                    ? app.career
                    : 'Estudiante Uniandes',
                availability: availLabel,
                availColor: availColor,
              ),
              const SizedBox(height: 14),

              // ── Academic data ─────────────────────────────────────────
              _SectionCard(
                icon: Icons.school_outlined,
                title: 'Perfil académico',
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricBox(
                        value: app.gpa.toStringAsFixed(2),
                        label: 'GPA',
                        color: _gpaColor(app.gpa),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricBox(
                        value: '${app.semester}°',
                        label: 'Semestre',
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Motivation letter ─────────────────────────────────────
              _SectionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Carta de motivación',
                child: Text(
                  app.motivationLetter.isNotEmpty
                      ? app.motivationLetter
                      : 'El postulante no incluyó una carta de motivación.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Offer details ─────────────────────────────────────────
              _SectionCard(
                icon: Icons.info_outline,
                title: 'Detalles de la oferta',
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.work_outline,
                      title: app.offerTitle,
                      subtitle: 'Posición',
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(
                      icon: Icons.calendar_month_outlined,
                      title: _formatDate(app.createdAt),
                      subtitle: 'Postulado el',
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(
                      icon: Icons.flag_outlined,
                      title: switch (app.status) {
                        ApplicationStatus.pending => 'Pendiente de revisión',
                        ApplicationStatus.accepted => 'Aceptada',
                        ApplicationStatus.rejected => 'Rechazada',
                      },
                      subtitle: 'Estado',
                      valueColor: switch (app.status) {
                        ApplicationStatus.accepted => AppColors.success,
                        ApplicationStatus.rejected => AppColors.danger,
                        _ => AppColors.darkText,
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Action bar ────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border:
                    Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Rechazar',
                      icon: Icons.close,
                      background: const Color(0xFFFFEEF0),
                      foreground: AppColors.danger,
                      onTap: () => _updateStatus(
                          context, ApplicationStatus.rejected),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Aceptar',
                      icon: Icons.check,
                      background: AppColors.success,
                      foreground: Colors.white,
                      onTap: () => _updateStatus(
                          context, ApplicationStatus.accepted),
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

  Future<void> _updateStatus(
      BuildContext context, ApplicationStatus newStatus) async {
    // Capture before async gap
    final appState = context.read<AppState>();

    // Optimistically update locally
    appState.setApplicationStatus(app.id, newStatus);

    // Best-effort sync to backend
    try {
      await ApiService.updateApplicationStatus(app.id, newStatus);
    } catch (_) {
      // Silently ignore — local state already updated
    }

    if (context.mounted) Navigator.pop(context);
  }

  String _formatDate(DateTime d) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} de ${months[d.month - 1]}, ${d.year}';
  }

  Color _gpaColor(double gpa) {
    if (gpa >= 4.5) return AppColors.success;
    if (gpa >= 3.5) return const Color(0xFFF59E0B);
    return AppColors.danger;
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final String initials;
  final String name;
  final String career;
  final String availability;
  final Color availColor;

  const _ProfileHeaderCard({
    required this.initials,
    required this.name,
    required this.career,
    required this.availability,
    required this.availColor,
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
          Text(name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(career,
              style: const TextStyle(
                  color: AppColors.greyText, fontSize: 15)),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: availColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: availColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              availability.toUpperCase(),
              style: TextStyle(
                color: availColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metric box ────────────────────────────────────────────────────────────────

class _MetricBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.greyText,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(16),
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.valueColor,
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
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: valueColor ?? AppColors.darkText)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      const TextStyle(color: AppColors.greyText)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

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
        label: Text(label,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900)),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
