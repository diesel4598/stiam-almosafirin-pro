import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:water_tracker_mobile/theme/app_theme.dart';
import 'package:water_tracker_mobile/screens/dashboard_screen.dart';
import 'package:water_tracker_mobile/screens/trips_screen.dart';
import 'package:water_tracker_mobile/screens/inventory_screen.dart';
import 'package:water_tracker_mobile/screens/reports_screen.dart';
import 'package:water_tracker_mobile/screens/users_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      DashboardScreen(
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const TripsScreen(),
      const InventoryScreen(),
      const ReportsScreen(),
      const UsersScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: AppTheme.onSurfaceVariant.withValues(
                alpha: 0.6,
              ),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.layoutDashboard),
                  label: 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.bus),
                  label: 'الرحلات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.package),
                  label: 'المخزون',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.fileText),
                  label: 'التقارير',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.users),
                  label: 'المستخدمين',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
