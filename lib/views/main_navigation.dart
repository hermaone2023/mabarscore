import 'package:flutter/material.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/views/dashboard/dashboard_view.dart';
import 'package:mabarscore/views/fivehero/fivehero_view.dart';
import 'package:mabarscore/views/profile/profile_view.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Default ke indeks 1 (Menu FIVEHERO ARENA)

  final List<Widget> _pages = [
    const HomeView(),
    FiveheroView(),
    const ProfileView(), // Ganti dengan halaman profil yang sesuai
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Menggunakan extendBody agar sistem tahu konten kita akan memenuhi layar hingga ke belakang navbar
      extendBody: true,
      body: Stack(
        children: [
          // 1. Konten Halaman Aktif
          // PADDING BAWAH DIHAPUS kawan! Biarkan halaman mengisi layar sepenuhnya dari ujung ke ujung.
          _pages[_currentIndex],

          // 2. Komponen Navbar Melayang (Floating)
          Positioned(
            left: 24,
            right: 24,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.navBarBg.withValues(
                  alpha: 0.9,
                ), // Warna abu-abu transparan mockup
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.emoji_events_outlined,
                    activeIcon: Icons.emoji_events,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.hub_outlined,
                    activeIcon: Icons.hub,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Kustom untuk Item Ikon di Dalam Navbar
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.backgroundDark.withValues(alpha: 0.4)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          size: 32,
          color: isActive ? Colors.amber : AppColors.navBarIconUnselected,
        ),
      ),
    );
  }
}
