import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';

/// Analytics dashboard — BQ7 (Santiago Reyes):
/// "Average days between job offer publication and first application."
///
/// Connectivity strategy: cache-first.
/// 1. Renders cached result immediately if available (shows last-updated label).
/// 2. Background network refresh updates the UI without blocking it.
/// 3. When offline and no cache exists, shows an informative empty state.
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  Map<String, dynamic>? _data;
  String? _lastUpdated;
  bool _loading = false;
  String? _error;

  static const _endpoint = 'time_to_first_application';

  @override
  void initState() {
    super.initState();
    _loadWithCache();
  }

  // ── Cache-first load ───────────────────────────────────────────────────────

  Future<void> _loadWithCache() async {
    // Step 1: serve cached data immediately (no spinner for the user).
    final cached = await CacheService.loadAnalytics(_endpoint);
    final ts = await CacheService.getAnalyticsTimestamp(_endpoint);
    if (cached != null) {
      if (mounted) setState(() { _data = cached; _lastUpdated = ts; });
    } else {
      if (mounted) setState(() => _loading = true);
    }

    // Step 2: background network refresh (fire-and-forget multi-threading).
    await _refreshFromNetwork();
  }

  Future<void> _refreshFromNetwork() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final fresh = await ApiService.getTimeToFirstApplication();
      await CacheService.saveAnalytics(_endpoint, fresh);
      final ts = await CacheService.getAnalyticsTimestamp(_endpoint);
      if (mounted) {
        setState(() { _data = fresh; _lastUpdated = ts; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_data == null) _error = 'Sin conexión y sin datos en caché.';
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
    final isOnline = context.watch<AppState>().isOnline;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? AppColors.darkSurface : AppColors.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: appBarBg,
        elevation: 0,
        title: const Text(
          'Analítica',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryYellow,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refreshFromNetwork,
              tooltip: 'Actualizar',
            ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (!isOnline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                children: const [
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // Section header
                const Text(
                  'MÉTRICAS',
                  style: TextStyle(
                    letterSpacing: 1.4,
                    color: Color(0xFF9AA4B2),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),

                if (_error != null && _data == null)
                  _ErrorCard(message: _error!)
                else if (_data == null && _loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: CircularProgressIndicator(color: AppColors.primaryYellow),
                    ),
                  )
                else if (_data != null)
                  _BQ7Card(
                    data: _data!,
                    lastUpdated: _fmtTimestamp(_lastUpdated),
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── BQ7 card ─────────────────────────────────────────────────────────────────

class _BQ7Card extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lastUpdated;
  final bool isDark;

  const _BQ7Card({
    required this.data,
    required this.lastUpdated,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final avgDays = (data['average_days_to_first_application'] as num?)?.toDouble() ?? 0.0;
    final offersWithApps = data['offers_with_applications'] as int? ?? 0;
    final totalOffers = data['total_offers'] as int? ?? 0;

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BQ label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'BQ7',
              style: TextStyle(
                color: Color(0xFF9A5B00),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          const Text(
            'Promedio de días hasta\nla primera postulación',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tiempo medio entre la publicación de una oferta y la recepción de la primera aplicación.',
            style: TextStyle(color: AppColors.greyText, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Main metric
          Center(
            child: Column(
              children: [
                Text(
                  avgDays.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryYellow,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'días promedio',
                  style: TextStyle(fontSize: 16, color: AppColors.greyText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sub-metrics row
          Row(
            children: [
              Expanded(
                child: _SubMetric(
                  value: offersWithApps.toString(),
                  label: 'Ofertas con\naplicaciones',
                  borderColor: borderColor,
                ),
              ),
              Container(width: 1, height: 48, color: borderColor),
              Expanded(
                child: _SubMetric(
                  value: totalOffers.toString(),
                  label: 'Total de\nofertas',
                  borderColor: borderColor,
                ),
              ),
            ],
          ),

          if (lastUpdated.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.update_rounded, size: 14, color: AppColors.greyText),
                const SizedBox(width: 6),
                Text(
                  'Última actualización: $lastUpdated',
                  style: const TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SubMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color borderColor;

  const _SubMetric({
    required this.value,
    required this.label,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.greyText, fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
