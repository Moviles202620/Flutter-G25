import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/settings_state.dart';
import 'acceptance_rate_page.dart';
import 'insights_page.dart';

class AnalyticsShell extends StatelessWidget {
  const AnalyticsShell({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? AppColors.darkSurface : AppColors.surface;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            indicatorColor: AppColors.primaryYellow,
            labelColor: AppColors.primaryYellow,
            unselectedLabelColor:
                isDark ? AppColors.darkGreyText : AppColors.greyText,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: [
              Tab(text: context.t('acceptance_rate')),
              Tab(text: context.t('insights')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AcceptanceRatePage(),
            InsightsPage(),
          ],
        ),
      ),
    );
  }
}
