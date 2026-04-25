import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/applications_per_semester_model.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';

class ApplicationsPerSemesterPage extends StatefulWidget {
  const ApplicationsPerSemesterPage({super.key});

  @override
  State<ApplicationsPerSemesterPage> createState() =>
      _ApplicationsPerSemesterPageState();
}

class _ApplicationsPerSemesterPageState
    extends State<ApplicationsPerSemesterPage> {
  List<ApplicationsPerSemesterModel>? _items;
  String? _lastUpdated;
  bool _loading = false;
  String? _error;

  static const _endpoint = 'applications_per_semester';

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
          .map((e) => ApplicationsPerSemesterModel.fromJson(
              e as Map<String, dynamic>))
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
      // Multi-threading: ApiService.getApplicationsPerSemester() corre en el
      // event loop de Dart sin bloquear el UI thread (async I/O concurrente).
      final fresh = await ApiService.getApplicationsPerSemester();
      final payload = {
        'data': fresh
            .map((e) => {
                  'semester': e.semester,
                  'total_applications': e.totalApplications,
                  'unique_students': e.uniqueStudents,
                  'avg_applications_per_student': e.avgApplicationsPerStudent,
                })
            .toList(),
      };
      await CacheService.saveAnalytics(_endpoint, payload);
      final ts = await CacheService.getAnalyticsTimestamp(_endpoint);
      if (mounted) {
        setState(() { _items = fresh; _lastUpdated = ts; _loading = false; });
      }
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

  Color _avgColor(double avg) {
    if (avg >= 2.0) return AppColors.success;
    if (avg >= 1.5) return const Color(0xFFF5A623);
    return AppColors.greyText;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isOnline = context.watch<AppState>().isOnline;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Error state (no cache, no network)
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

    // Initial loading (no cache)
    if (_items == null && _loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryYellow),
      );
    }

    final items = _items ?? [];

    return Column(
      children: [
        // Offline banner
        if (!isOnline)
          Container(
            width: double.infinity,
            color: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sin conexión — mostrando datos en caché',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshFromNetwork,
            color: AppColors.primaryYellow,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: items.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _Header(
                    isDark: isDark,
                    lastUpdated: _fmtTimestamp(_lastUpdated),
                    loading: _loading,
                    context: context,
                  );
                }
                return _SemesterCard(
                  item: items[index - 1],
                  isDark: isDark,
                  avgColor: _avgColor(items[index - 1].avgApplicationsPerStudent),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isDark;
  final String lastUpdated;
  final bool loading;
  final BuildContext context;

  const _Header({
    required this.isDark,
    required this.lastUpdated,
    required this.loading,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final mutedText = isDark ? AppColors.darkGreyText : AppColors.greyText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('apps_per_semester_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            context.t('apps_per_semester_subtitle'),
            style: TextStyle(color: mutedText, fontSize: 13, height: 1.4),
          ),
          if (lastUpdated.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.update_rounded,
                    size: 13, color: AppColors.greyText),
                const SizedBox(width: 5),
                Text(
                  '${context.t('last_updated')}: $lastUpdated',
                  style: const TextStyle(
                      color: AppColors.greyText, fontSize: 12),
                ),
                if (loading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.primaryYellow),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Semester card ─────────────────────────────────────────────────────────────

class _SemesterCard extends StatelessWidget {
  final ApplicationsPerSemesterModel item;
  final bool isDark;
  final Color avgColor;

  const _SemesterCard({
    required this.item,
    required this.isDark,
    required this.avgColor,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final mutedText = isDark ? AppColors.darkGreyText : AppColors.greyText;
    final progress = (item.avgApplicationsPerStudent / 5.0).clamp(0.0, 1.0);

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
          // Header row: semester title + avg chip
          Row(
            children: [
              Expanded(
                child: Text(
                  'Semestre ${item.semester}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: avgColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: avgColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'Avg ${item.avgApplicationsPerStudent.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: avgColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8),
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryYellow),
            ),
          ),
          const SizedBox(height: 14),

          // Metrics row
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: item.totalApplications.toString(),
                  label: 'Total apps',
                  color: AppColors.primaryYellow,
                  mutedText: mutedText,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: borderColor),
              Expanded(
                child: _Metric(
                  value: item.uniqueStudents.toString(),
                  label: 'Estudiantes únicos',
                  color: AppColors.success,
                  mutedText: mutedText,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: borderColor),
              Expanded(
                child: _Metric(
                  value: item.avgApplicationsPerStudent.toStringAsFixed(2),
                  label: 'Apps/estudiante',
                  color: avgColor,
                  mutedText: mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color mutedText;

  const _Metric({
    required this.value,
    required this.label,
    required this.color,
    required this.mutedText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11, color: mutedText, height: 1.3),
          ),
        ],
      ),
    );
  }
}
