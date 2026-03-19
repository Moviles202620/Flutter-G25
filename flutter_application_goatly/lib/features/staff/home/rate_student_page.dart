import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../models/application_model.dart';

class RateStudentPage extends StatefulWidget {
  final ApplicationModel app;
  const RateStudentPage({super.key, required this.app});

  @override
  State<RateStudentPage> createState() => _RateStudentPageState();
}

class _RateStudentPageState extends State<RateStudentPage> {
  double _overall = 0;
  double _punctuality = 0;
  double _quality = 0;
  double _attitude = 0;
  final _feedbackCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_overall == 0) {
      _showError('Selecciona una calificación general (1–5 estrellas)');
      return;
    }
    if (_feedbackCtrl.text.trim().isEmpty) {
      _showError('Escribe un comentario sobre el desempeño');
      return;
    }

    setState(() => _submitting = true);

    final appState = context.read<AppState>();

    await appState.completeAndRate(
      appId: widget.app.id,
      rating: _overall,
      feedback: _feedbackCtrl.text.trim(),
      punctuality: _punctuality == 0 ? _overall : _punctuality,
      quality: _quality == 0 ? _overall : _quality,
      attitude: _attitude == 0 ? _overall : _attitude,
    );

    setState(() => _submitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Calificación de ${widget.app.applicantName} enviada ✓'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Pop twice: back to detail page, then back to list
    Navigator.pop(context);
    Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Calificar estudiante',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
            children: [
              // ── Student header ──────────────────────────────────────
              _SectionCard(
                surface: surface,
                border: border,
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryYellow,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.app.applicantInitials,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.app.applicantName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(
                            widget.app.career.isNotEmpty
                                ? '${widget.app.career} • Sem ${widget.app.semester}'
                                : 'Estudiante Uniandes',
                            style: const TextStyle(
                                color: AppColors.greyText,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.app.offerTitle,
                            style: const TextStyle(
                              color: AppColors.primaryYellow,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Overall rating ──────────────────────────────────────
              _SectionCard(
                surface: surface,
                border: border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CALIFICACIÓN GENERAL',
                        style: TextStyle(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    const Text(
                      '¿Cómo evalúas el desempeño general del estudiante?',
                      style: TextStyle(
                          color: AppColors.greyText, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _BigStarRating(
                      value: _overall,
                      onChanged: (v) => setState(() => _overall = v),
                    ),
                    if (_overall > 0) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _overallLabel(_overall),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _starColor(_overall),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Category ratings ────────────────────────────────────
              _SectionCard(
                surface: surface,
                border: border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CATEGORÍAS',
                        style: TextStyle(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                    const SizedBox(height: 14),
                    _CategoryRow(
                      label: 'Puntualidad',
                      icon: Icons.access_time_rounded,
                      value: _punctuality,
                      onChanged: (v) =>
                          setState(() => _punctuality = v),
                    ),
                    const SizedBox(height: 14),
                    _CategoryRow(
                      label: 'Calidad del trabajo',
                      icon: Icons.workspace_premium_outlined,
                      value: _quality,
                      onChanged: (v) => setState(() => _quality = v),
                    ),
                    const SizedBox(height: 14),
                    _CategoryRow(
                      label: 'Actitud y disposición',
                      icon: Icons.sentiment_satisfied_outlined,
                      value: _attitude,
                      onChanged: (v) =>
                          setState(() => _attitude = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Feedback text ───────────────────────────────────────
              _SectionCard(
                surface: surface,
                border: border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('COMENTARIOS',
                        style: TextStyle(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _feedbackCtrl,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                            'Describe el desempeño del estudiante: puntualidad, calidad de trabajo, actitud...',
                        hintStyle:
                            const TextStyle(color: Color(0xFF9AA4B2)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primaryYellow,
                              width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Submit button ───────────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SizedBox(
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black54),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, size: 22),
                          SizedBox(width: 8),
                          Text('Enviar calificación',
                              style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _overallLabel(double v) {
    if (v >= 5) return '¡Excelente!';
    if (v >= 4) return 'Muy bueno';
    if (v >= 3) return 'Bueno';
    if (v >= 2) return 'Regular';
    return 'Deficiente';
  }

  Color _starColor(double v) {
    if (v >= 4) return AppColors.success;
    if (v >= 3) return const Color(0xFFF59E0B);
    return AppColors.danger;
  }
}

// ── Big interactive star row ──────────────────────────────────────────────────

class _BigStarRating extends StatelessWidget {
  final double value;
  final void Function(double) onChanged;

  const _BigStarRating({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starVal = (i + 1).toDouble();
        return GestureDetector(
          onTap: () => onChanged(starVal),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              value >= starVal ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 48,
              color: value >= starVal
                  ? const Color(0xFFF59E0B)
                  : AppColors.border,
            ),
          ),
        );
      }),
    );
  }
}

// ── Small category star row ───────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final void Function(double) onChanged;

  const _CategoryRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.greyText),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        Row(
          children: List.generate(5, (i) {
            final starVal = (i + 1).toDouble();
            return GestureDetector(
              onTap: () => onChanged(starVal),
              child: Icon(
                value >= starVal
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 26,
                color: value >= starVal
                    ? const Color(0xFFF59E0B)
                    : AppColors.border,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color surface;
  final Color border;

  const _SectionCard({
    required this.child,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: child,
      );
}
