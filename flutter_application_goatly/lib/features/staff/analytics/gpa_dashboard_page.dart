import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/gpa_analytics_model.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';

class GpaDashboardPage extends StatefulWidget {
  const GpaDashboardPage({super.key});

  @override
  State<GpaDashboardPage> createState() => _GpaDashboardPageState();
}

class _GpaDashboardPageState extends State<GpaDashboardPage> {
  List<GpaAnalyticsModel>? _items;
  String? _lastUpdated;
  bool _loading = false;
  String? _error;

  static const _endpoint = 'gpa_by_offer';

  @override
  void initState() {
    super.initState();
    _loadWithCache();
  }

  // ── Cache-first load ───────────────────────────────────────────────────────

  Future<void> _loadWithCache() async {
    final cached = await CacheService.loadAnalytics(_endpoint);
    final ts = await CacheService.getAnalyticsTimestamp(_endpoint);
    if (cached != null) {
      final list = (cached['data'] as List)
          .map((e) => GpaAnalyticsModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _items = list; _lastUpdated = ts; });
    } else {
      if (mounted) setState(() => _loading = true);
    }
    await _refreshFromNetwork();
  }

  Future<void> _refreshFromNetwork() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      // Multi-threading: ApiService.getGpaByOffer() corre en el
      // event loop de Dart sin bloquear el UI thread (async I/O concurrente).
      final fresh = await ApiService.getGpaByOffer();
      final payload = {'data': fresh.map((e) => e.toJson()).toList()};
      await CacheService.saveAnalytics(_endpoint, payload);
      final ts = await CacheService.getAnalyticsTimestamp(_endpoint);
      if (mounted) setState(() { _items = fresh; _lastUpdated = ts; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_items == null) _error = 'Sin conexión y sin datos en caché.';
        });
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtTimestamp(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$min';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_error != null && _items == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48,
                color: isDark ? AppColors.darkGreyText : AppColors.greyText),
            const SizedBox(height: 12),
            Text(context.t('no_cache_offline')),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadWithCache,
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

    if (_items == null && _loading) {
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

    final items = _items ?? [];

    if (items.isEmpty && !_loading) {
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
      onRefresh: _refreshFromNetwork,
      color: AppColors.primaryYellow,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: items.length + 1, // +1 for last-updated header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _LastUpdatedRow(
              lastUpdated: _fmtTimestamp(_lastUpdated),
              loading: _loading,
              context: context,
            );
          }
          return _GpaCard(item: items[index - 1], isDark: isDark);
        },
      ),
    );
  }
}

// ── Last updated row ──────────────────────────────────────────────────────────

class _LastUpdatedRow extends StatelessWidget {
  final String lastUpdated;
  final bool loading;
  final BuildContext context;

  const _LastUpdatedRow({
    required this.lastUpdated,
    required this.loading,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    if (lastUpdated.isEmpty && !loading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (lastUpdated.isNotEmpty) ...[
            const Icon(Icons.update_rounded,
                size: 13, color: AppColors.greyText),
            const SizedBox(width: 5),
            Text(
              '${context.t('last_updated')}: $lastUpdated',
              style:
                  const TextStyle(color: AppColors.greyText, fontSize: 12),
            ),
          ],
          if (loading) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: AppColors.primaryYellow),
            ),
          ],
        ],
      ),
    );
  }
}

// ── GPA card ──────────────────────────────────────────────────────────────────

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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(barColor),
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
