import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/settings_state.dart';
import '../../../models/gpa_analytics_model.dart';
import '../../../services/api_service.dart';

class GpaDashboardPage extends StatefulWidget {
  const GpaDashboardPage({super.key});

  @override
  State<GpaDashboardPage> createState() => _GpaDashboardPageState();
}

class _GpaDashboardPageState extends State<GpaDashboardPage> {
  late Future<List<GpaAnalyticsModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getGpaByOffer();
  }

  void _reload() {
    setState(() {
      _future = ApiService.getGpaByOffer();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<GpaAnalyticsModel>>(
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
                Icon(Icons.error_outline,
                    size: 48,
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

        final data = snapshot.data!;
        if (data.isEmpty) {
          return Center(
            child: Text(
              context.t('no_gpa_data'),
              style: TextStyle(
                color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                fontSize: 16,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          color: AppColors.primaryYellow,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: data.length,
            itemBuilder: (context, index) =>
                _GpaCard(item: data[index], isDark: isDark),
          ),
        );
      },
    );
  }
}

class _GpaCard extends StatelessWidget {
  final GpaAnalyticsModel item;
  final bool isDark;

  const _GpaCard({required this.item, required this.isDark});

  Color _gpaColor(double gpa) {
    if (gpa >= 4.0) return AppColors.success;
    if (gpa >= 3.5) return const Color(0xFFF5A623);
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final barColor = _gpaColor(item.averageGpa);

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
            item.offerTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          if (item.category != null) ...[
            const SizedBox(height: 4),
            Text(
              item.category!,
              style: TextStyle(
                  color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                  fontSize: 14),
            ),
          ],
          const SizedBox(height: 14),

          // GPA average + bar
          Row(
            children: [
              Text(
                item.averageGpa.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: barColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ 5.0',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('avg_gpa'),
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
                        value: item.averageGpa / 5.0,
                        minHeight: 10,
                        backgroundColor: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE8E8E8),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Min / Max / Applicants chips
          Row(
            children: [
              _InfoChip(
                label: context.t('min_gpa'),
                value: item.minGpa.toStringAsFixed(2),
                color: AppColors.danger,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: context.t('max_gpa'),
                value: item.maxGpa.toStringAsFixed(2),
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: context.t('total_applicants'),
                value: '${item.totalApplicants}',
                color: AppColors.primaryYellow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
