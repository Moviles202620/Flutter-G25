import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/application_model.dart';
import '../../../models/historical_rating_summary.dart';
import '../../../services/api_service.dart';
import '../home/widgets/live_context_card.dart';
import 'rate_student_page.dart';

class ApplicationDetailPage extends StatelessWidget {
  final ApplicationModel app;

  const ApplicationDetailPage({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = context.watch<SettingsState>().language;
    final application = state.getApplicationById(app.id) ?? app;
    final offer = state.getOfferById(application.offerId);
    final completionTime = state.getApplicationCompletionTime(application);
    final canRateNow = state.canRateApplication(application);
    final history = state.getHistoricalRatingSummary(application.applicantName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final secondary = isDark ? AppColors.darkGreyText : AppColors.greyText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        title: Text(
          context.t('application_detail'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 160),
            children: [
              _ProfileHeaderCard(
                application: application,
                isDark: isDark,
                lang: lang,
              ),
              const SizedBox(height: 14),
              _SectionCard(
                surface: surface,
                border: border,
                title: context.t('academic_profile'),
                icon: Icons.school_outlined,
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: context.t('gpa_label'),
                        value: application.gpa.toStringAsFixed(2),
                        color: _gpaColor(application.gpa),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: context.t('semester'),
                        value: '${application.semester}°',
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _HistoricalRatingCard(
                history: history,
                surface: surface,
                border: border,
                secondary: secondary,
              ),
              const SizedBox(height: 14),
              if (offer != null &&
                  offer.isOnSite &&
                  application.status == ApplicationStatus.accepted) ...[
                LiveContextCard(isDark: isDark),
                const SizedBox(height: 14),
              ],
              _SectionCard(
                surface: surface,
                border: border,
                title: context.t('motivation_letter'),
                icon: Icons.chat_bubble_outline,
                child: Text(
                  application.motivationLetter.isNotEmpty
                      ? application.motivationLetter
                      : context.t('no_motivation_letter'),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? AppColors.darkModeText : AppColors.darkText,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                surface: surface,
                border: border,
                title: context.t('job_details'),
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    _DetailRow(
                      label: context.t('offer_label'),
                      value: application.offerTitle,
                      secondary: secondary,
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(
                      label: context.t('applied_on'),
                      value: _formatDate(application.createdAt, lang),
                      secondary: secondary,
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(
                      label: context.t('status'),
                      value: _statusLabel(application.status, context),
                      valueColor: _statusColor(application.status),
                      secondary: secondary,
                    ),
                    if (completionTime != null) ...[
                      const SizedBox(height: 14),
                      _DetailRow(
                        label: context.t('estimated_completion'),
                        value: _formatDateTime(completionTime, lang),
                        secondary: secondary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: border)),
              ),
              child: _ActionArea(
                application: application,
                canRateNow: canRateNow,
                completionTime: completionTime,
                lang: lang,
                onAccept: () => _updateStatus(
                  context,
                  application.id,
                  ApplicationStatus.accepted,
                ),
                onReject: () => _updateStatus(
                  context,
                  application.id,
                  ApplicationStatus.rejected,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    String appId,
    ApplicationStatus newStatus,
  ) async {
    final appState = context.read<AppState>();
    await appState.setApplicationStatus(appId, newStatus);

    try {
      await ApiService.updateApplicationStatus(appId, newStatus);
    } catch (_) {}

    if (context.mounted) Navigator.pop(context);
  }

  static String _statusLabel(ApplicationStatus status, BuildContext context) =>
      switch (status) {
        ApplicationStatus.pending => context.t('status_pending'),
        ApplicationStatus.accepted => context.t('status_accepted'),
        ApplicationStatus.rejected => context.t('status_rejected'),
      };

  static Color _statusColor(ApplicationStatus status) => switch (status) {
        ApplicationStatus.accepted => AppColors.success,
        ApplicationStatus.rejected => AppColors.danger,
        ApplicationStatus.pending => AppColors.primaryYellow,
      };

  static Color _gpaColor(double gpa) {
    if (gpa >= 4.5) return AppColors.success;
    if (gpa >= 3.5) return const Color(0xFFF59E0B);
    return AppColors.danger;
  }

  static String _formatDate(DateTime date, String lang) {
    final months = lang == 'en'
        ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        : ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final connector = lang == 'en' ? 'of' : 'de';
    return '${date.day} $connector ${months[date.month - 1]}, ${date.year}';
  }

  static String _formatDateTime(DateTime dt, String lang) {
    final minutes = dt.minute.toString().padLeft(2, '0');
    return '${_formatDate(dt, lang)} · ${dt.hour}:$minutes';
  }
}

class _ActionArea extends StatelessWidget {
  final ApplicationModel application;
  final bool canRateNow;
  final DateTime? completionTime;
  final String lang;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ActionArea({
    required this.application,
    required this.canRateNow,
    required this.completionTime,
    required this.lang,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (application.isCompleted) {
      return _CompletedBanner(rating: application.rating ?? 0);
    }

    if (application.status == ApplicationStatus.accepted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: canRateNow
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RateStudentPage(app: application),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.star_rounded, size: 22),
              label: Text(
                context.t('complete_and_rate'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (!canRateNow) ...[
            const SizedBox(height: 10),
            Text(
              completionTime == null
                  ? context.t('cannot_verify_time')
                  : '${context.t('rating_available_when')} ${ApplicationDetailPage._formatDateTime(completionTime!, lang)}',
              style: const TextStyle(
                color: AppColors.greyText,
                fontSize: 13,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    if (application.status == ApplicationStatus.rejected) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
        ),
        child: Text(
          context.t('application_rejected_banner'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: context.t('reject'),
            icon: Icons.close,
            background: const Color(0xFFFFEEF0),
            foreground: AppColors.danger,
            onTap: onReject,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: context.t('accept'),
            icon: Icons.check,
            background: AppColors.success,
            foreground: Colors.white,
            onTap: onAccept,
          ),
        ),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final ApplicationModel application;
  final bool isDark;
  final String lang;

  const _ProfileHeaderCard({
    required this.application,
    required this.isDark,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final secondary = isDark ? AppColors.darkGreyText : AppColors.greyText;
    final availabilityLabel = switch (application.availability) {
      'full_time' => context.t('availability_full'),
      'part_time' => context.t('availability_part'),
      _ => context.t('availability_flexible'),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
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
                application.applicantInitials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            application.applicantName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkModeText : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            application.career.isNotEmpty
                ? application.career
                : context.t('student_label'),
            style: TextStyle(color: secondary, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.primaryYellow.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              availabilityLabel.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9A5B00),
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

class _HistoricalRatingCard extends StatelessWidget {
  final HistoricalRatingSummary history;
  final Color surface;
  final Color border;
  final Color secondary;

  const _HistoricalRatingCard({
    required this.history,
    required this.surface,
    required this.border,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      surface: surface,
      border: border,
      title: context.t('historical_rating'),
      icon: Icons.insights_outlined,
      child: history.hasHistory
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: context.t('average'),
                        value: history.averageRating.toStringAsFixed(1),
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        label: context.t('weighted_avg'),
                        value: history.weightedRating.toStringAsFixed(1),
                        color: AppColors.primaryYellow,
                        icon: Icons.balance_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        label: context.t('rated_jobs'),
                        value: history.ratedJobsCount.toString(),
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                if (history.lastRating != null) ...[
                  const SizedBox(height: 14),
                  _DetailRow(
                    label: context.t('last_rating'),
                    value: '${history.lastRating!.toStringAsFixed(1)} ★',
                    valueColor: const Color(0xFFF59E0B),
                    secondary: secondary,
                  ),
                ],
              ],
            )
          : Text(
              context.t('no_rating_history'),
              style: TextStyle(color: secondary, height: 1.35),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Color surface;
  final Color border;
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.surface,
    required this.border,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryYellow),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Color secondary;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.secondary,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: secondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  final double rating;

  const _CompletedBanner({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Text(
        '${context.t('job_completed_banner')} · ${rating.toStringAsFixed(1)} ★',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}
