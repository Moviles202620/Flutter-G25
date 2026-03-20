import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/settings_state.dart';
import '../../../models/application_search_model.dart';
import '../../../services/api_service.dart';

class SearchApplicationsPage extends StatefulWidget {
  const SearchApplicationsPage({super.key});

  @override
  State<SearchApplicationsPage> createState() => _SearchApplicationsPageState();
}

class _SearchApplicationsPageState extends State<SearchApplicationsPage> {
  final TextEditingController _queryCtrl = TextEditingController();
  int? _semesterFilter;
  List<ApplicationSearchModel>? _results;
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final results = await ApiService.searchApplications(
        q: q.isEmpty ? null : q,
        semester: _semesterFilter,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: appBarBg,
        elevation: 0,
        title: Text(
          context.t('search_applications'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar + filters
          Container(
            color: appBarBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _queryCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: context.t('search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _queryCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _queryCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFF0F0F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      context.t('filter_semester'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _SemChip(
                              label: 'Todos',
                              selected: _semesterFilter == null,
                              onTap: () =>
                                  setState(() => _semesterFilter = null),
                            ),
                            ...List.generate(10, (i) => i + 1).map((s) =>
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: _SemChip(
                                    label: '$s',
                                    selected: _semesterFilter == s,
                                    onTap: () =>
                                        setState(() => _semesterFilter = s),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: const Icon(Icons.search, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _buildBody(
              context, isDark, surfaceColor, borderColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, Color surfaceColor,
      Color borderColor) {
    if (_loading) {
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _search,
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

    if (!_searched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search,
                size: 64,
                color: isDark ? AppColors.darkGreyText : AppColors.greyText),
            const SizedBox(height: 12),
            Text(
              context.t('search_empty_hint'),
              style: TextStyle(
                color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_results == null || _results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64,
                color: isDark ? AppColors.darkGreyText : AppColors.greyText),
            const SizedBox(height: 12),
            Text(
              context.t('no_search_results'),
              style: TextStyle(
                color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _results!.length,
      itemBuilder: (context, index) => _SearchResultCard(
        app: _results![index],
        surfaceColor: surfaceColor,
        borderColor: borderColor,
      ),
    );
  }
}

class _SemChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SemChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryYellow
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryYellow
                : AppColors.greyText.withValues(alpha: 0.4),
          ),
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
}

class _SearchResultCard extends StatelessWidget {
  final ApplicationSearchModel app;
  final Color surfaceColor;
  final Color borderColor;

  const _SearchResultCard({
    required this.app,
    required this.surfaceColor,
    required this.borderColor,
  });

  Color get _statusColor {
    switch (app.status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return const Color(0xFF9AA4B2);
    }
  }

  String _statusLabel(BuildContext context) {
    switch (app.status) {
      case 'accepted':
        return context.t('accepted_label').toUpperCase();
      case 'rejected':
        return context.t('rejected_label').toUpperCase();
      default:
        return context.t('pending_label').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                app.initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9A5B00),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.applicantName,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  app.offerTitle,
                  style: const TextStyle(
                      color: AppColors.greyText, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${app.career} • Sem. ${app.semester} • GPA ${app.gpa.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.greyText, fontSize: 13),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel(context),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
