import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
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
    final appState = context.read<AppState>();
    final currentApplication =
        appState.getApplicationById(widget.app.id) ?? widget.app;

    if (!appState.canRateApplication(currentApplication)) {
      _showError(context.t('cannot_rate_yet'));
      return;
    }
    if (_overall == 0) {
      _showError(context.t('err_select_rating'));
      return;
    }
    if (_feedbackCtrl.text.trim().isEmpty) {
      _showError(context.t('err_write_comment'));
      return;
    }

    setState(() => _submitting = true);

    final saved = await appState.completeAndRate(
      appId: currentApplication.id,
      rating: _overall,
      feedback: _feedbackCtrl.text.trim(),
      punctuality: _punctuality == 0 ? _overall : _punctuality,
      quality: _quality == 0 ? _overall : _quality,
      attitude: _attitude == 0 ? _overall : _attitude,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!saved) {
      _showError(context.t('cannot_save_rating'));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${context.t('submit_rating')}: ${currentApplication.applicantName}',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
    Navigator.pop(context);
  }

  void _showError(String message) {
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
    final appState = context.watch<AppState>();
    final application =
        appState.getApplicationById(widget.app.id) ?? widget.app;
    final canRateNow = appState.canRateApplication(application);
    final completionTime = appState.getApplicationCompletionTime(application);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final secondary = isDark ? AppColors.darkGreyText : AppColors.greyText;
    final textColor = isDark ? AppColors.darkModeText : AppColors.darkText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        title: Text(
          context.t('rate_student'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
            children: [
              _Card(
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
                          application.applicantInitials,
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
                          Text(
                            application.applicantName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            application.career.isNotEmpty
                                ? '${application.career} · ${context.t('semester')} ${application.semester}'
                                : context.t('student_label'),
                            style: TextStyle(color: secondary, fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            application.offerTitle,
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
              if (!canRateNow) ...[
                const SizedBox(height: 16),
                _Card(
                  surface: surface,
                  border: border,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        color: AppColors.primaryYellow,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          completionTime == null
                              ? context.t('cannot_verify_time')
                              : '${context.t('rating_enabled_when')} ${completionTime.day.toString().padLeft(2, '0')}/${completionTime.month.toString().padLeft(2, '0')}/${completionTime.year} ${completionTime.hour}:${completionTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: secondary, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _Card(
                surface: surface,
                border: border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('overall_rating_section'),
                      style: const TextStyle(
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.t('rate_question'),
                      style: TextStyle(color: secondary, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _StarSelector(
                      value: _overall,
                      onChanged: (value) => setState(() => _overall = value),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                surface: surface,
                border: border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('categories_section'),
                      style: const TextStyle(
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MetricRatingRow(
                      label: context.t('punctuality'),
                      icon: Icons.access_time_rounded,
                      value: _punctuality,
                      secondary: secondary,
                      isDark: isDark,
                      onChanged: (value) =>
                          setState(() => _punctuality = value),
                    ),
                    const SizedBox(height: 14),
                    _MetricRatingRow(
                      label: context.t('work_quality'),
                      icon: Icons.workspace_premium_outlined,
                      value: _quality,
                      secondary: secondary,
                      isDark: isDark,
                      onChanged: (value) => setState(() => _quality = value),
                    ),
                    const SizedBox(height: 14),
                    _MetricRatingRow(
                      label: context.t('attitude'),
                      icon: Icons.sentiment_satisfied_outlined,
                      value: _attitude,
                      secondary: secondary,
                      isDark: isDark,
                      onChanged: (value) => setState(() => _attitude = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                surface: surface,
                border: border,
                child: TextFormField(
                  controller: _feedbackCtrl,
                  maxLines: 5,
                  maxLength: 500,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: context.t('comments'),
                    hintText: context.t('hint_comments'),
                    hintStyle: TextStyle(color: secondary),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF202020) : Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryYellow,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitting || !canRateNow ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black54,
                        ),
                      )
                    : Text(
                        context.t('submit_rating'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color surface;
  final Color border;

  const _Card({
    required this.child,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class _StarSelector extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double iconSize;
  final bool isDark;

  const _StarSelector({
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.iconSize = 42,
  });

  @override
  Widget build(BuildContext context) {
    final emptyColor = isDark ? AppColors.darkBorder : AppColors.border;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = (index + 1).toDouble();
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              value >= starValue
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: iconSize,
              color: value >= starValue
                  ? const Color(0xFFF59E0B)
                  : emptyColor,
            ),
          ),
        );
      }),
    );
  }
}

class _MetricRatingRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final Color secondary;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _MetricRatingRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.secondary,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        _StarSelector(
          value: value,
          onChanged: onChanged,
          isDark: isDark,
          iconSize: 24,
        ),
      ],
    );
  }
}
