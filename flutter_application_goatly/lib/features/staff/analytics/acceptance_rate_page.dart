import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/settings_state.dart';
import '../../../models/acceptance_rate_model.dart';
import '../../../services/api_service.dart';

class AcceptanceRatePage extends StatefulWidget {
  const AcceptanceRatePage({super.key});

  @override
  State<AcceptanceRatePage> createState() => _AcceptanceRatePageState();
}

class _AcceptanceRatePageState extends State<AcceptanceRatePage> {
  late Future<List<AcceptanceRateModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getAcceptanceRates();
  }

  void _reload() {
    setState(() {
      _future = ApiService.getAcceptanceRates();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<AcceptanceRateModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primaryYellow),
                const SizedBox(height: 12),
                Text(context.t('loading')),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48,
                    color: isDark ? AppColors.darkGreyText : AppColors.greyText),
                const SizedBox(height: 12),
                Text(context.t('error_loading')),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.t('retry')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          );
        }

        final rates = snapshot.data!;
        if (rates.isEmpty) {
          return Center(
            child: Text(
              context.t('no_acceptance_data'),
              style: TextStyle(
                color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                fontSize: 16,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _reload();
          },
          color: AppColors.primaryYellow,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: rates.length,
            itemBuilder: (context, index) =>
                _AcceptanceRateCard(rate: rates[index], isDark: isDark),
          ),
        );
      },
    );
  }
}

class _AcceptanceRateCard extends StatelessWidget {
  final AcceptanceRateModel rate;
  final bool isDark;

  const _AcceptanceRateCard({required this.rate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & category
          Text(
            rate.offerTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            rate.category,
            style: TextStyle(
                color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                fontSize: 14),
          ),
          const SizedBox(height: 14),

          // Acceptance rate bar
          Row(
            children: [
              Text(
                '${rate.acceptanceRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryYellow,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('acceptance_rate'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkGreyText
                            : AppColors.greyText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: rate.acceptanceRate / 100,
                        minHeight: 10,
                        backgroundColor: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE8E8E8),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryYellow),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Breakdown chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                symbol: '✅',
                semanticLabel: context.t('accepted_label'),
                count: rate.accepted,
                color: AppColors.success,
              ),
              _StatusChip(
                symbol: '❌',
                semanticLabel: context.t('rejected_label'),
                count: rate.rejected,
                color: AppColors.danger,
              ),
              _StatusChip(
                symbol: '⏳',
                semanticLabel: context.t('pending_label'),
                count: rate.pending,
                color: const Color(0xFF9AA4B2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${context.t('total_apps')}: ${rate.totalApplications}',
            style: TextStyle(
                color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String symbol;
  final String semanticLabel;
  final int count;
  final Color color;

  const _StatusChip({
    required this.symbol,
    required this.semanticLabel,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticLabel: $count',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(symbol, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
