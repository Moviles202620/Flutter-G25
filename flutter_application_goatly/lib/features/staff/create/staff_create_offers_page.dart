import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../app/localization.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/offer_model.dart';
import '../home/applicant_list_page.dart';

class StaffCreateOffersPage extends StatelessWidget {
  const StaffCreateOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final offers = appState.offers;
    final isOnline = appState.isOnline;
    final pendingOps = appState.pendingOpsCount;
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
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pendingOps > 0
                          ? 'Sin conexión — $pendingOps oferta(s) en cola para sincronizar'
                          : 'Sin conexión — las nuevas ofertas se guardarán localmente',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                if (offers.isEmpty) _EmptyOffers(isDark: isDark),
                ...offers.map(
                  (o) => Padding(
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
                  ),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final location = offer.isOnSite ? 'Presencial' : 'Remoto';
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
          Text(offer.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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
