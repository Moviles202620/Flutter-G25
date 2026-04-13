import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../app/localization.dart';
import '../../../models/application_model.dart';
import 'application_detail_page.dart';
import 'notifications_page.dart';
import 'search_applications_page.dart';
import 'package:provider/provider.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';


class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final apps = state.pendingApplications;
    final activeOffers = state.offers.length;
    context.watch<SettingsState>(); // Escuchar cambios de idioma y tema
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? AppColors.darkSurface : AppColors.surface;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: appBarBg,
        elevation: 0,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: Text(
          context.t('home'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: context.t('search_tooltip'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchApplicationsPage()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsPage()),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 28),
                  if (context.watch<AppState>().unreadNotificationCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${context.read<AppState>().unreadNotificationCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: apps.isEmpty
          ? const _EmptyState()
          : _HomeWithApps(apps: apps, activeOffers: activeOffers),
    );
  }
}

class _HomeWithApps extends StatelessWidget {
  final List<ApplicationModel> apps;
  final int activeOffers;

  const _HomeWithApps({
    required this.apps,
    required this.activeOffers,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>(); // Escuchar cambios
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _ActivitySummaryCard(
          pendingCount: apps.where((a) => a.status == ApplicationStatus.pending).length,
          activeOffers: activeOffers,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.t('recent_applications'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              context.t('view_all'),
              style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...apps.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ApplicationDetailPage(app: a)),
              );
            },
            child: _ApplicationCard(
              app: a,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ),
        )),
      ],
    );
  }
}

class _ActivitySummaryCard extends StatelessWidget {
  final int pendingCount;
  final int activeOffers;
  final Color surfaceColor;
  final Color borderColor;

  const _ActivitySummaryCard({
    required this.pendingCount,
    required this.activeOffers,
    required this.surfaceColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('activity_summary'),
            style: const TextStyle(letterSpacing: 1.4, color: Color(0xFF9AA4B2), fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: pendingCount.toString(),
                  label: context.t('pending_applications'),
                ),
              ),
              Container(width: 1, height: 50, color: borderColor),
              Expanded(
                child: _Metric(
                  value: activeOffers.toString(),
                  label: context.t('active_offers'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.greyText, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel app;
  final Color surfaceColor;
  final Color borderColor;

  const _ApplicationCard({
    required this.app,
    required this.surfaceColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = switch (app.status) {
      ApplicationStatus.pending => context.t('chip_pending'),
      ApplicationStatus.accepted => context.t('chip_accepted'),
      ApplicationStatus.rejected => context.t('chip_rejected'),
    };

    final statusColor = switch (app.status) {
      ApplicationStatus.pending => const Color(0xFF9AA4B2),
      ApplicationStatus.accepted => AppColors.success,
      ApplicationStatus.rejected => AppColors.danger,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryYellow.withOpacity(0.35)),
            ),
            child: Center(
              child: Text(
                app.applicantInitials,
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A5B00)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.applicantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(app.offerTitle, style: const TextStyle(color: AppColors.greyText, fontSize: 16)),
              ],
            ),
          ),
          Text(statusText, style: TextStyle(fontWeight: FontWeight.w900, color: statusColor)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final containerBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final iconColor = isDark ? const Color(0xFF666C78) : const Color(0xFFB6BFCC);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 70),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: containerBg,
              shape: BoxShape.circle,
              border: Border.all(color: containerBorder),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 14,
                  offset: Offset(0, 8),
                  color: Color(0x12000000),
                ),
              ],
            ),
            child: Icon(Icons.inbox_outlined, size: 46, color: iconColor),
          ),
          const SizedBox(height: 22),
          Text(
            context.t('empty_state_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            context.t('empty_state_subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: AppColors.greyText, height: 1.35),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 22),
              label: Text(
                context.t('create_offer_action'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
