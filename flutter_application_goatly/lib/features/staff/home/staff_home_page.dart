import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/offer_model.dart';
import '../create/offer_detail_page.dart';
import 'notifications_page.dart';
import 'search_applications_page.dart';

class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    final activeOffer = state.activeOffer;
    final upcoming = state.upcomingOffers;
    final unrated = state.offersWithUnratedStudents;
    final hasAnything =
        activeOffer != null || upcoming.isNotEmpty || unrated.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: Text(context.t('home'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: context.t('search_tooltip'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchApplicationsPage()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 28),
                  if (state.unreadNotificationCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          '${state.unreadNotificationCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!state.isOnline)
            Container(
              width: double.infinity,
              color: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    context.t('offline_banner'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: hasAnything
                ? _CockpitBody(
                    activeOffer: activeOffer,
                    upcoming: upcoming,
                    unrated: unrated,
                    isDark: isDark,
                  )
                : const _EmptyState(),
          ),
        ],
      ),
    );
  }
}

class _CockpitBody extends StatelessWidget {
  final OfferModel? activeOffer;
  final List<OfferModel> upcoming;
  final List<OfferModel> unrated;
  final bool isDark;

  const _CockpitBody({
    required this.activeOffer,
    required this.upcoming,
    required this.unrated,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final secondary = isDark ? AppColors.darkGreyText : AppColors.greyText;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Active labor hero card ──────────────────────────────────────
        if (activeOffer != null) ...[
          _ActiveOfferHero(
              offer: activeOffer!,
              isDark: isDark,
              surface: surface,
              border: border),
          const SizedBox(height: 18),
        ],

        // ── Unrated students alert ──────────────────────────────────────
        if (unrated.isNotEmpty) ...[
          _UnratedAlert(
              offers: unrated,
              isDark: isDark,
              surface: surface,
              border: border),
          const SizedBox(height: 18),
        ],

        // ── Upcoming offers ─────────────────────────────────────────────
        if (upcoming.isNotEmpty) ...[
          Text(context.t('cockpit_upcoming'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...upcoming.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _UpcomingOfferCard(
                    offer: o,
                    isDark: isDark,
                    surface: surface,
                    border: border,
                    secondary: secondary),
              )),
        ],
      ],
    );
  }
}

class _ActiveOfferHero extends StatelessWidget {
  final OfferModel offer;
  final bool isDark;
  final Color surface, border;

  const _ActiveOfferHero(
      {required this.offer,
      required this.isDark,
      required this.surface,
      required this.border});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OfferDetailPage(offer: offer)),
      ).then((_) => appState.loadOffersFromBackend()),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1B4332), const Color(0xFF144226)]
                : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radio_button_checked,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Text(context.t('cockpit_active_now'),
                    style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.success),
              ],
            ),
            const SizedBox(height: 10),
            Text(offer.title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.darkModeText
                        : AppColors.darkText)),
            const SizedBox(height: 4),
            Text(
              '${offer.category ?? ''} · ${offer.durationHours}h · '
              '${offer.isOnSite ? context.t("on_site") : context.t("remote")}',
              style: const TextStyle(color: AppColors.success, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnratedAlert extends StatelessWidget {
  final List<OfferModel> offers;
  final bool isDark;
  final Color surface, border;

  const _UnratedAlert(
      {required this.offers,
      required this.isDark,
      required this.surface,
      required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow
            .withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primaryYellow.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_outline_rounded,
                  color: Color(0xFF9A5B00), size: 20),
              const SizedBox(width: 8),
              Text(context.t('cockpit_unrated'),
                  style: const TextStyle(
                      color: Color(0xFF9A5B00),
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          Text(context.t('cockpit_unrated_desc'),
              style: const TextStyle(
                  color: Color(0xFF9A5B00), fontSize: 13, height: 1.35)),
          const SizedBox(height: 10),
          ...offers.map((o) {
            final appState = context.read<AppState>();
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OfferDetailPage(offer: o)),
              ).then((_) => appState.loadOffersFromBackend()),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right,
                        color: Color(0xFF9A5B00), size: 18),
                    Text(o.title,
                        style: const TextStyle(
                            color: Color(0xFF9A5B00),
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _UpcomingOfferCard extends StatelessWidget {
  final OfferModel offer;
  final bool isDark;
  final Color surface, border, secondary;

  const _UpcomingOfferCard({
    required this.offer,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final dt = offer.dateTime;
    final formatted =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OfferDetailPage(offer: offer)),
      ).then((_) => appState.loadOffersFromBackend()),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.schedule_outlined,
                  color: Color(0xFF3B82F6), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(formatted,
                      style: TextStyle(color: secondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.greyText),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        isDark ? const Color(0xFF666C78) : const Color(0xFFB6BFCC);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: iconColor),
          const SizedBox(height: 18),
          Text(context.t('cockpit_no_activity'),
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(context.t('cockpit_no_activity_sub'),
              style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.darkGreyText
                      : AppColors.greyText,
                  height: 1.35),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
