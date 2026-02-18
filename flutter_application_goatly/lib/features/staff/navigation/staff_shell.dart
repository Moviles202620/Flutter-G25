import 'package:flutter/material.dart';
import '../home/staff_home_page.dart';
import '../create/staff_create_offers_page.dart';
import '../profile/staff_profile_page.dart';
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
  StaffProfilePage(),
];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryYellow,
        unselectedItemColor: const Color(0xFF8A94A6),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Crear'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
