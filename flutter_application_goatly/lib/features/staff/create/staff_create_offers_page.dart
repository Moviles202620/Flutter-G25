import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../app/localization.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/offer_model.dart';
import '../../../services/api_service.dart';
import '../home/applicant_list_page.dart';
import 'edit_offer_page.dart';

class StaffCreateOffersPage extends StatelessWidget {
  const StaffCreateOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final offers = context.watch<AppState>().offers;
    context.watch<SettingsState>(); // Escuchar cambios

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? AppColors.darkSurface : AppColors.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: appBarBg,
        elevation: 0,
        title: Text(
          context.t('my_offers'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          if (offers.isEmpty)
            _EmptyOffers(
              isDark: isDark,
            ),
          ...offers.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApplicantListPage(offer: o),
                    ),
                  ),
                  child: _OfferCard(offer: o, isDark: isDark),
                ),
              )),
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
            label: Text(
              context.t('create_offer'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  final bool isDark;

  const _EmptyOffers({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('no_offers_yet'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('publish_first_offer'),
            style: const TextStyle(color: AppColors.greyText, height: 1.3),
          ),
        ],
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
