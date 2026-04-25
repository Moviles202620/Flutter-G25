import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/settings_state.dart';
import '../../../services/api_service.dart';

class GpaHighRatePage extends StatefulWidget {
  const GpaHighRatePage({super.key});

  @override
  State<GpaHighRatePage> createState() => _GpaHighRatePageState();
}

class _GpaHighRatePageState extends State<GpaHighRatePage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getGpaHighRate();
  }

  void _reload() {
    setState(() {
      _future = ApiService.getGpaHighRate();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
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

        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return Center(
            child: Text(
              context.t('no_high_gpa_data'),
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
            itemCount: rows.length,
            itemBuilder: (context, index) =>
                _GpaHighRateCard(row: rows[index], isDark: isDark),
          ),
        );
      },
    );
  }
}

class _GpaHighRateCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isDark;

  const _GpaHighRateCard({required this.row, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final title = row['offer_title'] as String? ?? '';
    final category = row['category'] as String? ?? '';
    final total = (row['total_applicants'] as num?)?.toInt() ?? 0;
    final highCount = (row['high_gpa_count'] as num?)?.toInt() ?? 0;
    final pct = (row['high_gpa_percentage'] as num?)?.toDouble() ?? 0.0;

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final greyText = isDark ? AppColors.darkGreyText : AppColors.greyText;

    // Color the bar: green when high, amber when medium, red when low
    final barColor = pct >= 60
        ? AppColors.success
        : pct >= 30
            ? AppColors.primaryYellow
            : AppColors.danger;

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
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(category, style: TextStyle(color: greyText, fontSize: 13)),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: barColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('high_gpa_pct'),
                      style: TextStyle(
                        color: greyText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor:
                            isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                label: context.t('high_gpa_count'),
                value: '$highCount',
                color: AppColors.success,
              ),
              _InfoChip(
                label: context.t('total_applicants'),
                value: '$total',
                color: greyText,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
