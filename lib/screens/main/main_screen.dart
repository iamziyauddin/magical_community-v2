import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/screens/dashboard/dashboard_screen.dart';
import 'package:magical_community/screens/daily_entry/daily_entry_screen.dart';
// import 'package:magical_community/screens/accounts/accounts_screen.dart';
import 'package:magical_community/screens/settings/settings_screen.dart';
import 'package:upgrader/upgrader.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;
    
    if (!hasSeenIntro && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIntroDialog();
      });
    }
  }

  void _showIntroDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.accentYellow, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Welcome to Magical Community!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Here is a comprehensive overview of how to use the app:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 16),
              _buildFeatureRow(Icons.dashboard_customize, 'Dashboard Analytics', 'View real-time statistics, active members, and observe your income summaries at a glance.'),
              _buildFeatureRow(Icons.edit_calendar, 'Daily Entry', 'Record daily wellness metrics, manage club attendance, and track trial participants efficiently.'),
              _buildFeatureRow(Icons.people_alt, 'User Management', 'Seamlessly handle memberships, track trial visitors, and monitor their wellness paths.'),
              _buildFeatureRow(Icons.inventory_2, 'Inventory & Finances', 'Track product consumption, monitor stock levels, and review all daily payments/expenses.'),
              _buildFeatureRow(Icons.settings, 'System Settings', 'Configure your app preferences, check your profile, and explore open source licenses.'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Enjoy tracking your wellness community with ease! Tap "Okay" to get started.', 
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: AppTheme.primaryBlack, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlack,
              foregroundColor: AppTheme.accentYellow,
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_seen_intro', true);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.darkGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.darkGrey)),
              ],
            ),
          ),
        ],
      ),
    );
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
      upgrader: Upgrader(),
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
