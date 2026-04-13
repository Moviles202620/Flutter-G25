import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../home/staff_home_page.dart';
import '../create/staff_create_offers_page.dart';
import '../profile/staff_profile_page.dart';
import '../analytics/analytics_shell.dart';
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
    AnalyticsShell(),
    StaffProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadStaffWorkspace();
    });
  }


  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>(); // Escuchar cambios de idioma

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
            icon: const Icon(Icons.analytics_outlined),
            label: context.t('analytics'),
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
