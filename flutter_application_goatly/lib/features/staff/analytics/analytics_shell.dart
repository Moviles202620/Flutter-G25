import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/settings_state.dart';
import 'acceptance_rate_page.dart';
import 'gpa_dashboard_page.dart';
import 'insights_page.dart';
import 'top_applicants_page.dart';

class AnalyticsShell extends StatefulWidget {
  const AnalyticsShell({super.key});

  @override
  State<AnalyticsShell> createState() => _AnalyticsShellState();
}

class _AnalyticsShellState extends State<AnalyticsShell>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
    _controller.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTabChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 430;
    final tabs = [
      _AnalyticsTabMeta(
        label: context.t('acceptance_rate'),
        icon: Icons.percent_rounded,
      ),
      _AnalyticsTabMeta(
        label: context.t('insights'),
        icon: Icons.insights_outlined,
      ),
      _AnalyticsTabMeta(
        label: context.t('gpa_dashboard'),
        icon: Icons.school_outlined,
      ),
      _AnalyticsTabMeta(
        label: context.t('top_applicants'),
        icon: Icons.emoji_events_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: appBarBg,
        elevation: 0,
        title: Text(
          context.t('analytics'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        bottom: isCompact
            ? null
            : TabBar(
                controller: _controller,
                indicatorColor: AppColors.primaryYellow,
                labelColor: AppColors.primaryYellow,
                unselectedLabelColor:
                    isDark ? AppColors.darkGreyText : AppColors.greyText,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: tabs
                    .map(
                      (tab) => Tab(
                        icon: Icon(tab.icon, size: 18),
                        text: tab.label,
                      ),
                    )
                    .toList(),
              ),
      ),
      body: Column(
        children: [
          if (isCompact)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      tabs.length,
                      (index) => SizedBox(
                        width: itemWidth,
                        child: _AnalyticsTabButton(
                          label: tabs[index].label,
                          icon: tabs[index].icon,
                          selected: _controller.index == index,
                          onTap: () => _controller.animateTo(index),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: const [
                AcceptanceRatePage(),
                InsightsPage(),
                GpaDashboardPage(),
                TopApplicantsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTabMeta {
  final String label;
  final IconData icon;

  const _AnalyticsTabMeta({required this.label, required this.icon});
}

class _AnalyticsTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AnalyticsTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected
        ? AppColors.primaryYellow.withValues(alpha: isDark ? 0.2 : 0.14)
        : (isDark ? AppColors.darkSurface : AppColors.surface);
    final border = selected
        ? AppColors.primaryYellow.withValues(alpha: 0.45)
        : (isDark ? AppColors.darkBorder : AppColors.border);
    final fg = selected
        ? AppColors.primaryYellow
        : (isDark ? AppColors.darkGreyText : AppColors.greyText);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
