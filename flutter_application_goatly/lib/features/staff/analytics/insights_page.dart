import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/settings_state.dart';
import '../../../models/insights_model.dart';
import '../../../services/api_service.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late Future<InsightsModel> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getInsights();
  }

  void _reload() {
    setState(() {
      _future = ApiService.getInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<InsightsModel>(
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

        final insights = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          color: AppColors.primaryYellow,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildKpiRow(context, isDark, [
                _KpiData(
                  icon: Icons.work_outline,
                  value: insights.totalOffers.toString(),
                  label: context.t('total_offers'),
                ),
                _KpiData(
                  icon: Icons.people_outline,
                  value: insights.totalApplications.toString(),
                  label: context.t('total_applications'),
                ),
              ]),
              const SizedBox(height: 14),
              _buildKpiCard(
                context,
                isDark,
                icon: Icons.percent,
                value: '${insights.overallAcceptanceRate.toStringAsFixed(1)}%',
                label: context.t('overall_acceptance_rate'),
                valueColor: AppColors.primaryYellow,
              ),
              const SizedBox(height: 14),
              _buildKpiCard(
                context,
                isDark,
                icon: Icons.trending_up,
                value: insights.mostPopularOffer,
                label: context.t('most_popular_offer'),
                subtitle:
                    '${insights.mostPopularOfferApplications} ${context.t('applications_label')}',
                valueColor: AppColors.success,
              ),
              const SizedBox(height: 14),
              _buildKpiCard(
                context,
                isDark,
                icon: Icons.trending_down,
                value: insights.leastPopularOffer,
                label: context.t('least_popular_offer'),
                subtitle:
                    '${insights.leastPopularOfferApplications} ${context.t('applications_label')}',
                valueColor: AppColors.danger,
              ),
              const SizedBox(height: 14),
              _buildKpiCard(
                context,
                isDark,
                icon: Icons.analytics_outlined,
                value: insights.avgApplicationsPerOffer.toStringAsFixed(1),
                label: context.t('avg_apps_per_offer'),
                valueColor: AppColors.primaryYellow,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiRow(BuildContext context, bool isDark, List<_KpiData> items) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: EdgeInsets.only(
                    right: item == items.last ? 0 : 7,
                    left: item == items.first ? 0 : 7),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(item.icon, color: AppColors.primaryYellow, size: 28),
                    const SizedBox(height: 10),
                    Text(
                      item.value,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.greyText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
    String? subtitle,
  }) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (valueColor ?? AppColors.primaryYellow).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: valueColor ?? AppColors.primaryYellow),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: valueColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.greyText, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final IconData icon;
  final String value;
  final String label;

  _KpiData({required this.icon, required this.value, required this.label});
}
