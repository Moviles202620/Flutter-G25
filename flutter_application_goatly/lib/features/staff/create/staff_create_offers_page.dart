import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../models/offer_model.dart';

class StaffCreateOffersPage extends StatelessWidget {
  const StaffCreateOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final offers = context.watch<AppState>().offers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        title: const Text('Mis ofertas', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          if (offers.isEmpty) const _EmptyOffers(),
          ...offers.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OfferCard(offer: o),
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
            label: const Text(
              'Crear oferta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Aún no has publicado ofertas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
            'Publica tu primera oferta para que\nlos estudiantes puedan postularse.',
            style: TextStyle(color: AppColors.greyText, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  const _OfferCard({required this.offer});

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
    final location = offer.isOnSite ? 'Presencial' : 'Remoto';
    final when = _fmtDateTime(offer.dateTime);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
