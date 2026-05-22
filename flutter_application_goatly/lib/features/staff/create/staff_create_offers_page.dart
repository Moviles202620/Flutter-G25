import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../app/localization.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/offer_model.dart';
import 'offer_card.dart';
import 'offer_detail_page.dart';

class StaffCreateOffersPage extends StatefulWidget {
  const StaffCreateOffersPage({super.key});

  @override
  State<StaffCreateOffersPage> createState() => _StaffCreateOffersPageState();
}

class _StaffCreateOffersPageState extends State<StaffCreateOffersPage> {
  String _selectedState = 'all';

  List<OfferModel> _filtered(List<OfferModel> all) {
    if (_selectedState == 'all') return all;
    return all.where((o) => o.state == _selectedState).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadOffersFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allOffers = context.watch<AppState>().offers;
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final filtered = _filtered(allOffers.toList());

    final counts = {
      'all':      allOffers.length,
      'upcoming': allOffers.where((o) => o.state == 'upcoming').length,
      'active':   allOffers.where((o) => o.state == 'active').length,
      'closed':   allOffers.where((o) => o.state == 'closed').length,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        title: Text(context.t('my_offers'), style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Offline banner ──────────────────────────────────────────────
          if (!context.watch<AppState>().isOnline)
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
          // ── State filter chips ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 430;
                final chips = [
                  _FilterChip(
                    label: context.t('filter_all'),
                    count: counts['all']!,
                    selected: _selectedState == 'all',
                    color: AppColors.greyText,
                    onTap: () => setState(() => _selectedState = 'all'),
                  ),
                  _FilterChip(
                    label: context.t('state_upcoming'),
                    count: counts['upcoming']!,
                    selected: _selectedState == 'upcoming',
                    color: const Color(0xFF3B82F6),
                    onTap: () => setState(() => _selectedState = 'upcoming'),
                  ),
                  _FilterChip(
                    label: context.t('state_active'),
                    count: counts['active']!,
                    selected: _selectedState == 'active',
                    color: AppColors.success,
                    onTap: () => setState(() => _selectedState = 'active'),
                  ),
                  _FilterChip(
                    label: context.t('state_closed'),
                    count: counts['closed']!,
                    selected: _selectedState == 'closed',
                    color: AppColors.greyText,
                    onTap: () => setState(() => _selectedState = 'closed'),
                  ),
                ];

                if (!isCompact) {
                  return SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: chips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => chips[index],
                    ),
                  );
                }

                final chipWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips
                      .map((chip) => SizedBox(width: chipWidth, child: chip))
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // ── Offer list ──────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
                    child: _EmptyOffers(
                      isDark: isDark,
                      selectedState: _selectedState,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    // Keeps only 400 px of off-screen items painted at a time,
                    // reducing GPU rasterisation work during fast flings.
                    cacheExtent: 400.0,
                    // Disable automatic KeepAlive — the analytics shell already
                    // manages tab lifecycle; keeping all items alive wastes RAM.
                    addAutomaticKeepAlives: false,
                    // Flutter will wrap each item in a RepaintBoundary; combined
                    // with the one inside OfferCard this is intentional double-
                    // isolation: the ListView boundary catches layout changes and
                    // the card boundary catches internal repaints.
                    addRepaintBoundaries: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final o = filtered[i];
                      return Padding(
                        // ValueKey lets Flutter diff the list efficiently when
                        // items are reordered or removed.
                        key: ValueKey(o.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OfferDetailPage(offer: o)),
                            );
                            if (context.mounted) {
                              context.read<AppState>().loadOffersFromBackend();
                            }
                          },
                          child: OfferCard(offer: o, isDark: isDark),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: SizedBox(
          height: 58,
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pushNamed(context, Routes.createOfferForm),
            icon: const Icon(Icons.add),
            label: Text(context.t('create_offer'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  final bool isDark;
  final String selectedState;

  const _EmptyOffers({required this.isDark, required this.selectedState});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final secondaryText = isDark ? AppColors.darkGreyText : AppColors.greyText;

    final (titleKey, subtitleKey) = switch (selectedState) {
      'upcoming' => ('no_upcoming_offers_title', 'no_upcoming_offers_sub'),
      'active'   => ('no_active_offers_title',   'no_active_offers_sub'),
      'closed'   => ('no_closed_offers_title',   'no_closed_offers_sub'),
      _          => ('no_offers_yet',             'publish_first_offer'),
    };

    return SizedBox.expand(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t(titleKey),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              context.t(subtitleKey),
              style: TextStyle(color: secondaryText, height: 1.4, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected
        ? color.withValues(alpha: isDark ? 0.25 : 0.15)
        : (isDark ? AppColors.darkSurface : AppColors.surface);
    final borderColor = selected
        ? color.withValues(alpha: 0.5)
        : (isDark ? AppColors.darkBorder : AppColors.border);
    final textColor =
        selected ? color : (isDark ? AppColors.darkGreyText : AppColors.greyText);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: textColor, fontSize: 13)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.2)
                    : textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count',
                  style: TextStyle(
                      color: textColor, fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
