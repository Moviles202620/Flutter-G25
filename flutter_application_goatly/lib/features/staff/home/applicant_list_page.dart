import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../models/offer_model.dart';
import '../../../models/application_model.dart';
import '../../../services/api_service.dart';
import 'application_detail_page.dart';

class ApplicantListPage extends StatefulWidget {
  final OfferModel offer;
  const ApplicantListPage({super.key, required this.offer});

  @override
  State<ApplicantListPage> createState() => _ApplicantListPageState();
}

class _ApplicantListPageState extends State<ApplicantListPage> {
  // ── Filter state ──────────────────────────────────────────────────────────
  double _minGpa = 0.0;
  int? _semester;          // null = any
  String _availability = ''; // '' = any
  String _sortBy = 'gpa';
  bool _filtersOpen = false;

  // ── Data state ────────────────────────────────────────────────────────────
  List<ApplicationModel> _results = [];
  bool _loading = true;
  String? _errorBanner; // non-null when using local fallback

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadApplicants() async {
    setState(() {
      _loading = true;
      _errorBanner = null;
    });

    try {
      final list = await ApiService.filterApplications(
        offerId: widget.offer.id,
        minGpa: _minGpa > 0 ? _minGpa : null,
        semester: _semester,
        availability: _availability.isNotEmpty ? _availability : null,
        sortBy: _sortBy,
      );
      if (mounted) setState(() { _results = list; _loading = false; });
    } catch (_) {
      // Backend unavailable → filter locally
      if (!mounted) return;
      final local = context.read<AppState>().filterApplicationsLocal(
        offerId: widget.offer.id,
        minGpa: _minGpa > 0 ? _minGpa : null,
        semester: _semester,
        availability: _availability.isNotEmpty ? _availability : null,
        sortBy: _sortBy,
      );
      setState(() {
        _results = local;
        _loading = false;
        _errorBanner = 'Sin conexión al servidor — mostrando datos locales';
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Postulantes',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(
              widget.offer.title,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.greyText),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Filtros',
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              backgroundColor: AppColors.primaryYellow,
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: () =>
                setState(() => _filtersOpen = !_filtersOpen),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Offline banner ──────────────────────────────────────────────
          if (_errorBanner != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 16, color: Color(0xFF92400E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorBanner!,
                      style: const TextStyle(
                          color: Color(0xFF92400E), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // ── Filter panel (collapsible) ──────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _filtersOpen
                ? _FilterPanel(
                    minGpa: _minGpa,
                    semester: _semester,
                    availability: _availability,
                    sortBy: _sortBy,
                    surface: surface,
                    border: border,
                    onChanged: ({
                      required double minGpa,
                      required int? semester,
                      required String availability,
                      required String sortBy,
                    }) {
                      setState(() {
                        _minGpa = minGpa;
                        _semester = semester;
                        _availability = availability;
                        _sortBy = sortBy;
                      });
                      _loadApplicants();
                    },
                  )
                : const SizedBox.shrink(),
          ),

          // ── Results ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryYellow))
                : _results.isEmpty
                    ? _EmptyResults(hasFilters: _hasActiveFilters)
                    : _ApplicantList(
                        applicants: _results,
                        offer: widget.offer,
                        surface: surface,
                        border: border,
                      ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _minGpa > 0 ||
      _semester != null ||
      _availability.isNotEmpty ||
      _sortBy != 'gpa';
}

// ── Filter panel ──────────────────────────────────────────────────────────────

class _FilterPanel extends StatefulWidget {
  final double minGpa;
  final int? semester;
  final String availability;
  final String sortBy;
  final Color surface;
  final Color border;
  final void Function({
    required double minGpa,
    required int? semester,
    required String availability,
    required String sortBy,
  }) onChanged;

  const _FilterPanel({
    required this.minGpa,
    required this.semester,
    required this.availability,
    required this.sortBy,
    required this.surface,
    required this.border,
    required this.onChanged,
  });

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late double _gpa;
  late int? _semester;
  late String _availability;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _gpa = widget.minGpa;
    _semester = widget.semester;
    _availability = widget.availability;
    _sortBy = widget.sortBy;
  }

  void _emit() => widget.onChanged(
        minGpa: _gpa,
        semester: _semester,
        availability: _availability,
        sortBy: _sortBy,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.surface,
        border: Border(bottom: BorderSide(color: widget.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GPA minimum
          Row(
            children: [
              const Text('GPA mínimo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                _gpa == 0 ? 'Cualquiera' : _gpa.toStringAsFixed(1),
                style: const TextStyle(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Slider(
            value: _gpa,
            min: 0,
            max: 5,
            divisions: 50,
            activeColor: AppColors.primaryYellow,
            inactiveColor: AppColors.border,
            onChanged: (v) => setState(() => _gpa = v),
            onChangeEnd: (_) => _emit(),
          ),
          const SizedBox(height: 8),

          // Semester
          Row(
            children: [
              const Text('Semestre',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SemChip(
                        label: 'Todos',
                        selected: _semester == null,
                        onTap: () {
                          setState(() => _semester = null);
                          _emit();
                        },
                      ),
                      ...List.generate(10, (i) => i + 1).map((s) =>
                          _SemChip(
                            label: '$s',
                            selected: _semester == s,
                            onTap: () {
                              setState(() =>
                                  _semester = _semester == s ? null : s);
                              _emit();
                            },
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Availability
          const Text('Disponibilidad',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _AvailChip(
                label: 'Cualquiera',
                value: '',
                selected: _availability.isEmpty,
                onTap: () {
                  setState(() => _availability = '');
                  _emit();
                },
              ),
              _AvailChip(
                label: 'Tiempo completo',
                value: 'full_time',
                selected: _availability == 'full_time',
                onTap: () {
                  setState(() => _availability =
                      _availability == 'full_time' ? '' : 'full_time');
                  _emit();
                },
              ),
              _AvailChip(
                label: 'Medio tiempo',
                value: 'part_time',
                selected: _availability == 'part_time',
                onTap: () {
                  setState(() => _availability =
                      _availability == 'part_time' ? '' : 'part_time');
                  _emit();
                },
              ),
              _AvailChip(
                label: 'Flexible',
                value: 'flexible',
                selected: _availability == 'flexible',
                onTap: () {
                  setState(() => _availability =
                      _availability == 'flexible' ? '' : 'flexible');
                  _emit();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sort
          Row(
            children: [
              const Text('Ordenar por',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              _SortChip(
                label: 'Mayor GPA',
                value: 'gpa',
                current: _sortBy,
                onTap: (v) {
                  setState(() => _sortBy = v);
                  _emit();
                },
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Semestre',
                value: 'semester',
                current: _sortBy,
                onTap: (v) {
                  setState(() => _sortBy = v);
                  _emit();
                },
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Más reciente',
                value: 'date',
                current: _sortBy,
                onTap: (v) {
                  setState(() => _sortBy = v);
                  _emit();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chip helpers ──────────────────────────────────────────────────────────────

class _SemChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SemChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryYellow
                  : AppColors.border.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.black : AppColors.greyText,
              ),
            ),
          ),
        ),
      );
}

class _AvailChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _AvailChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryYellow
                : AppColors.border.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : AppColors.greyText,
            ),
          ),
        ),
      );
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;
  const _SortChip(
      {required this.label,
      required this.value,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.darkText
              : AppColors.border.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primaryYellow : AppColors.greyText,
          ),
        ),
      ),
    );
  }
}

// ── Applicant list ────────────────────────────────────────────────────────────

class _ApplicantList extends StatelessWidget {
  final List<ApplicationModel> applicants;
  final OfferModel offer;
  final Color surface;
  final Color border;

  const _ApplicantList({
    required this.applicants,
    required this.offer,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: applicants.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final app = applicants[i];
        return _ApplicantCard(
          app: app,
          rank: i + 1,
          surface: surface,
          border: border,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApplicationDetailPage(app: app),
            ),
          ),
        );
      },
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicationModel app;
  final int rank;
  final Color surface;
  final Color border;
  final VoidCallback onTap;

  const _ApplicantCard({
    required this.app,
    required this.rank,
    required this.surface,
    required this.border,
    required this.onTap,
  });

  String get _availLabel => switch (app.availability) {
        'full_time' => 'Tiempo completo',
        'part_time' => 'Medio tiempo',
        _ => 'Flexible',
      };

  Color get _availColor => switch (app.availability) {
        'full_time' => AppColors.success,
        'part_time' => const Color(0xFF3B82F6),
        _ => AppColors.greyText,
      };

  String get _statusLabel => switch (app.status) {
        ApplicationStatus.accepted => 'ACEPTADA',
        ApplicationStatus.rejected => 'RECHAZADA',
        _ => 'PENDIENTE',
      };

  Color get _statusColor => switch (app.status) {
        ApplicationStatus.accepted => AppColors.success,
        ApplicationStatus.rejected => AppColors.danger,
        _ => AppColors.greyText,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // Rank + avatar
            Column(
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: rank == 1
                        ? const Color(0xFFB45309)
                        : AppColors.greyText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primaryYellow
                            .withValues(alpha: 0.35)),
                  ),
                  child: Center(
                    child: Text(
                      app.applicantInitials,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF9A5B00)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Name, career, semester
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.applicantName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(
                    '${app.career.isNotEmpty ? app.career : "—"} • Sem ${app.semester}',
                    style: const TextStyle(
                        color: AppColors.greyText, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Availability chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _availColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _availColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _availLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _availColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _statusColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // GPA badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _gpaColor(app.gpa).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    app.gpa.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _gpaColor(app.gpa),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Text('GPA',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.greyText)),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right,
                    color: AppColors.greyText, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _gpaColor(double gpa) {
    if (gpa >= 4.5) return AppColors.success;
    if (gpa >= 3.5) return const Color(0xFFF59E0B);
    return AppColors.danger;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyResults extends StatelessWidget {
  final bool hasFilters;
  const _EmptyResults({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.inbox_outlined,
              size: 64,
              color: AppColors.greyText.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'Sin resultados con estos filtros'
                  : 'Aún no hay postulantes',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Intenta ajustando el GPA mínimo, semestre o disponibilidad.'
                  : 'Los postulantes aparecerán aquí cuando apliquen a esta oferta.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.greyText, fontSize: 15, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
