import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/screens/dashboard/dashboard_screen.dart';
import 'package:magical_community/screens/daily_entry/daily_entry_screen.dart';
// import 'package:magical_community/screens/accounts/accounts_screen.dart';
import 'package:magical_community/screens/settings/settings_screen.dart';
import 'package:upgrader/upgrader.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DailyEntryScreen(),
    const SettingsScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.edit_calendar),
      label: 'Daily Entry',
    ),

    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        onUpdate: () {
          debugPrint('[Upgrader] User elected to update in MainScreen.');
          return true;
        },
        onLater: () {
          debugPrint('[Upgrader] User elected to update later in MainScreen.');
          return true;
        },
        onIgnore: () {
          debugPrint('[Upgrader] User elected to ignore the update in MainScreen.');
          return true;
        },
      ),
      child: Scaffold(
        body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlack.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.primaryBlack,
          selectedItemColor: AppTheme.accentYellow,
          unselectedItemColor: AppTheme.darkGrey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: _bottomNavItems,
        ),
      ),
    ),
    );
  }
}
