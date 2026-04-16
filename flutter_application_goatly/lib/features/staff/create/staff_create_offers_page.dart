import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../app/localization.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/offer_model.dart';
import '../../../services/api_service.dart';
import 'offer_detail_page.dart';
import 'edit_offer_page.dart';

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
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final o = filtered[i];
                      return Padding(
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
                          child: _OfferCard(offer: o, isDark: isDark),
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

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final bool isDark;

  const _OfferCard({required this.offer, required this.isDark});

  String _fmtDateTime(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = (d.hour % 12 == 0 ? 12 : d.hour % 12).toString();
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$mm/$dd ${hh.padLeft(2, '0')}:$min $ampm';
  }

  Future<void> _deleteOffer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.t('delete_offer_confirm'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(context.t('delete_offer_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.t('cancel'),
                style: const TextStyle(color: AppColors.greyText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('delete'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ApiService.deleteOffer(offer.id);
      if (context.mounted) {
        context.read<AppState>().removeOffer(offer.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('offer_deleted')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final location = offer.isOnSite
        ? context.t('on_site')
        : context.t('remote');
    final when = _fmtDateTime(offer.dateTime);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(offer.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              _LifecycleBadge(offer: offer),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.primaryYellow,
                tooltip: context.t('edit_offer'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditOfferPage(offer: offer),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.danger,
                tooltip: context.t('delete_offer'),
                onPressed: () => _deleteOffer(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${offer.category} • \$${offer.valueCop} COP',
            style: const TextStyle(color: AppColors.greyText, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            '$when • ${offer.durationHours}h • $location',
            style: const TextStyle(color: AppColors.greyText, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _LifecycleBadge extends StatelessWidget {
  final OfferModel offer;
  const _LifecycleBadge({required this.offer});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final (label, color, icon) = switch (offer.offerState) {
      OfferState.upcoming => (
          context.t('state_badge_upcoming'),
          const Color(0xFF3B82F6),
          Icons.schedule_outlined,
        ),
      OfferState.active when offer.endTime.difference(now).inHours < 24 => (
          context.t('state_badge_closing_soon'),
          const Color(0xFFF5A623),
          Icons.warning_amber_rounded,
        ),
      OfferState.active => (
          context.t('state_badge_active'),
          AppColors.success,
          Icons.circle,
        ),
      OfferState.closed => (
          context.t('state_badge_closed'),
          AppColors.greyText,
          Icons.lock_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
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
