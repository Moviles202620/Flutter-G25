import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/application_model.dart';
import '../../../models/offer_model.dart';
import '../../../services/api_service.dart';
import '../../../services/live_context_service.dart';
import '../home/application_detail_page.dart';

class OfferDetailPage extends StatefulWidget {
  final OfferModel offer;
  const OfferDetailPage({super.key, required this.offer});

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  List<ApplicationModel> _applicants = [];
  bool _loading = true;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AppState>().authToken;
      if (token != null) {
        final list = await ApiService.getStaffApplicationsByOffer(
            widget.offer.id, token);
        if (mounted) setState(() { _applicants = list; _loading = false; });
      } else {
        _loadLocal();
      }
    } catch (_) {
      _loadLocal();
    }
  }

  void _loadLocal() {
    final state = context.read<AppState>();
    final all = state.getApplicationsByOffer(widget.offer.id);
    final offerState = widget.offer.offerState;
    final filtered = (offerState == OfferState.upcoming)
        ? all
        : all.where((a) => a.status == ApplicationStatus.accepted).toList();
    if (mounted) setState(() { _applicants = filtered; _loading = false; });
  }

  Future<void> _closeOfferNow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.t('close_offer_confirm_title'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(context.t('close_offer_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.t('cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('close_offer_btn'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _closing = true);
    final ok = await context.read<AppState>().closeOffer(widget.offer.id);
    if (!mounted) return;
    setState(() => _closing = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('offer_closed_snack')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('error_closing_offer')),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final offer = context.watch<AppState>().offers
        .firstWhere((o) => o.id == widget.offer.id, orElse: () => widget.offer);
    final offerState = offer.offerState;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final secondary = isDark ? AppColors.darkGreyText : AppColors.greyText;

    final stateBadge = _StateBadge(offerState: offerState);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        title: Text(offer.title,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: stateBadge,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadApplicants,
              child: switch (offerState) {
                OfferState.upcoming => _UpcomingBody(
                    offer: offer,
                    applicants: _applicants,
                    isDark: isDark,
                    surface: surface,
                    border: border,
                    secondary: secondary,
                    onRefresh: _loadApplicants,
                  ),
                OfferState.active => _ActiveBody(
                    offer: offer,
                    applicants: _applicants,
                    isDark: isDark,
                    surface: surface,
                    border: border,
                    secondary: secondary,
                    closing: _closing,
                    onClose: _closeOfferNow,
                    onRefresh: _loadApplicants,
                  ),
                OfferState.closed => _ClosedBody(
                    offer: offer,
                    applicants: _applicants,
                    isDark: isDark,
                    surface: surface,
                    border: border,
                    secondary: secondary,
                    onRefresh: _loadApplicants,
                  ),
              },
            ),
    );
  }
}

// ── State badge ───────────────────────────────────────────────────────────────

class _StateBadge extends StatelessWidget {
  final OfferState offerState;
  const _StateBadge({required this.offerState});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (offerState) {
      OfferState.upcoming => (context.t('state_upcoming'), const Color(0xFF3B82F6), Icons.schedule_outlined),
      OfferState.active   => (context.t('state_active'),   AppColors.success,       Icons.radio_button_checked),
      OfferState.closed   => (context.t('state_closed'),   AppColors.greyText,      Icons.lock_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ── Upcoming body ─────────────────────────────────────────────────────────────

class _UpcomingBody extends StatelessWidget {
  final OfferModel offer;
  final List<ApplicationModel> applicants;
  final bool isDark;
  final Color surface, border;
  final Color secondary;
  final VoidCallback onRefresh;

  const _UpcomingBody({
    required this.offer,
    required this.applicants,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.secondary,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final byStatus = <ApplicationStatus, List<ApplicationModel>>{
      ApplicationStatus.pending:  applicants.where((a) => a.status == ApplicationStatus.pending).toList(),
      ApplicationStatus.accepted: applicants.where((a) => a.status == ApplicationStatus.accepted).toList(),
      ApplicationStatus.rejected: applicants.where((a) => a.status == ApplicationStatus.rejected).toList(),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _OfferInfoCard(offer: offer, isDark: isDark, surface: surface, border: border, secondary: secondary),
        const SizedBox(height: 16),
        _SectionHeader(
          title: context.t('applicants_pending_section'),
          count: byStatus[ApplicationStatus.pending]!.length,
          color: AppColors.primaryYellow,
        ),
        ...byStatus[ApplicationStatus.pending]!.map((a) => _ApplicantTile(
            app: a, isDark: isDark, surface: surface, border: border, offerState: OfferState.upcoming)),
        const SizedBox(height: 12),
        _SectionHeader(
          title: context.t('applicants_accepted_section'),
          count: byStatus[ApplicationStatus.accepted]!.length,
          color: AppColors.success,
        ),
        ...byStatus[ApplicationStatus.accepted]!.map((a) => _ApplicantTile(
            app: a, isDark: isDark, surface: surface, border: border, offerState: OfferState.upcoming)),
        const SizedBox(height: 12),
        _SectionHeader(
          title: context.t('applicants_rejected_section'),
          count: byStatus[ApplicationStatus.rejected]!.length,
          color: AppColors.danger,
        ),
        ...byStatus[ApplicationStatus.rejected]!.map((a) => _ApplicantTile(
            app: a, isDark: isDark, surface: surface, border: border, offerState: OfferState.upcoming)),
        if (applicants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(context.t('no_applicants_yet'), style: TextStyle(color: secondary)),
            ),
          ),
      ],
    );
  }
}

// ── Active body ───────────────────────────────────────────────────────────────

class _ActiveBody extends StatelessWidget {
  final OfferModel offer;
  final List<ApplicationModel> applicants;
  final bool isDark;
  final Color surface, border;
  final Color secondary;
  final bool closing;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  const _ActiveBody({
    required this.offer,
    required this.applicants,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.secondary,
    required this.closing,
    required this.onClose,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _OfferInfoCard(offer: offer, isDark: isDark, surface: surface, border: border, secondary: secondary),
        const SizedBox(height: 12),
        // Sensor banner (mobile only, on-site offers)
        if (LiveContextService.isSupportedMobilePlatform && offer.isOnSite) ...[
          _SensorBanner(isDark: isDark, surface: surface, border: border),
          const SizedBox(height: 12),
        ],
        // Close early button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: closing ? null : onClose,
            icon: closing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
                : const Icon(Icons.stop_circle_outlined, size: 20),
            label: Text(context.t('close_offer_btn'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: context.t('applicants_accepted_section'),
          count: applicants.length,
          color: AppColors.success,
        ),
        ...applicants.map((a) => _ApplicantTile(
            app: a, isDark: isDark, surface: surface, border: border, offerState: OfferState.active)),
        if (applicants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text(context.t('no_accepted_students'), style: TextStyle(color: secondary))),
          ),
      ],
    );
  }
}

// ── Closed body ───────────────────────────────────────────────────────────────

class _ClosedBody extends StatelessWidget {
  final OfferModel offer;
  final List<ApplicationModel> applicants;
  final bool isDark;
  final Color surface, border;
  final Color secondary;
  final VoidCallback onRefresh;

  const _ClosedBody({
    required this.offer,
    required this.applicants,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.secondary,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _OfferInfoCard(offer: offer, isDark: isDark, surface: surface, border: border, secondary: secondary),
        const SizedBox(height: 16),
        _SectionHeader(
          title: context.t('applicants_accepted_section'),
          count: applicants.length,
          color: AppColors.greyText,
        ),
        ...applicants.map((a) => _RatableApplicantTile(
            app: a, offer: offer, isDark: isDark, surface: surface, border: border, secondary: secondary)),
        if (applicants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text(context.t('no_accepted_students'), style: TextStyle(color: secondary))),
          ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _OfferInfoCard extends StatelessWidget {
  final OfferModel offer;
  final bool isDark;
  final Color surface, border;
  final Color secondary;

  const _OfferInfoCard({
    required this.offer,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final dt = offer.dateTime;
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${offer.category ?? ''} · \$${offer.valueCop} COP',
              style: TextStyle(color: secondary, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            '$mm/$dd $hh:$min $ampm · ${offer.durationHours}h · '
            '${offer.isOnSite ? context.t("on_site") : context.t("remote")}',
            style: TextStyle(color: secondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ApplicantTile extends StatelessWidget {
  final ApplicationModel app;
  final bool isDark;
  final Color surface, border;
  final OfferState offerState;

  const _ApplicantTile({
    required this.app,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.offerState,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (app.status) {
      ApplicationStatus.pending  => AppColors.primaryYellow,
      ApplicationStatus.accepted => AppColors.success,
      ApplicationStatus.rejected => AppColors.danger,
    };
    final statusLabel = switch (app.status) {
      ApplicationStatus.pending  => context.t('chip_pending'),
      ApplicationStatus.accepted => context.t('chip_accepted'),
      ApplicationStatus.rejected => context.t('chip_rejected'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ApplicationDetailPage(app: app)),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(app.applicantInitials,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A5B00)))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.applicantName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    Text('${app.career} · ${app.gpa.toStringAsFixed(2)} GPA',
                        style: TextStyle(
                            color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                            fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatableApplicantTile extends StatelessWidget {
  final ApplicationModel app;
  final OfferModel offer;
  final bool isDark;
  final Color surface, border;
  final Color secondary;

  const _RatableApplicantTile({
    required this.app,
    required this.offer,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ApplicationDetailPage(app: app)),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(app.applicantInitials,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A5B00)))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.applicantName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    if (app.isCompleted && app.rating != null)
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            (i + 1) <= app.rating!.round()
                                ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14,
                            color: (i + 1) <= app.rating!.round()
                                ? const Color(0xFFF59E0B) : AppColors.border,
                          )),
                          const SizedBox(width: 4),
                          Text(app.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
                        ],
                      )
                    else
                      Text('${app.career} · ${app.gpa.toStringAsFixed(2)} GPA',
                          style: TextStyle(color: secondary, fontSize: 13)),
                  ],
                ),
              ),
              if (app.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(context.t('rated_label'),
                      style: const TextStyle(
                          color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 12)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(context.t('rate_pending_label'),
                      style: const TextStyle(
                          color: Color(0xFF9A5B00), fontWeight: FontWeight.w800, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorBanner extends StatelessWidget {
  final bool isDark;
  final Color surface, border;

  const _SensorBanner({required this.isDark, required this.surface, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_outlined, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t('sensor_active_banner'),
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
