import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../home/staff_home_page.dart';
import '../create/staff_create_offers_page.dart';
import '../profile/staff_profile_page.dart';
import '../analytics/analytics_page.dart';
import '../../../app/theme.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;

  final _pages = const [
    StaffHomePage(),
    StaffCreateOffersPage(),
    AnalyticsPage(),
    StaffProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final pendingOps = context.watch<AppState>().pendingOpsCount;

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        selectedItemColor: AppColors.primaryYellow,
        unselectedItemColor: const Color(0xFF8A94A6),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            label: context.t('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            label: context.t('create'),
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.bar_chart_rounded),
                if (pendingOps > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Analítica',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: context.t('profile'),
          ),
        ],
      ),
    );
  }
}
