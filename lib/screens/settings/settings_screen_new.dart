import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/models/settings_model.dart';
import 'package:magical_community/screens/settings/account_settings_screen.dart';
import 'package:magical_community/screens/settings/fees_settings_screen.dart';
import 'package:magical_community/screens/settings/app_preferences_screen.dart';
import 'package:magical_community/screens/settings/about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Demo settings data - in real app, this would come from Hive
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    _settings = AppSettings(
      trialFee: 700.0,
      membershipFee: 7500.0,
      membershipDurationDays: 30,
      clubName: 'Magical Community',
      adminName: 'Admin User',
      adminPhone: '+91 98765 43210',
      clubAddress: '123 Fitness Street, Wellness City',
      enableNotifications: true,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [const Text('Settings'), const Text('Settings')],
        ),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with Club Info
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // Settings Categories
            Text(
              'Settings Categories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Account Settings (Profile + Club) and Fees
            _buildSettingsSection(
              title: 'Account & Club',
              icon: Icons.manage_accounts,
              color: AppTheme.accentYellow,
              items: [
                _buildSettingsItem(
                  title: 'Profile & Club',
                  subtitle: 'Name, contact, club details',
                  icon: Icons.info_outline,
                  onTap: () => _navigateToScreen(const AccountSettingsScreen()),
                ),
                _buildSettingsItem(
                  title: 'Fees & Pricing',
                  subtitle:
                      'Trial fee: ₹${_settings.trialFee.toInt()}, Membership: ₹${_settings.membershipFee.toInt()}',
                  icon: Icons.attach_money,
                  onTap: () => _navigateToScreen(const FeesSettingsScreen()),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Preferences Section
            _buildSettingsSection(
              title: 'Preferences',
              icon: Icons.person,
              color: AppTheme.softGreen,
              items: [
                _buildSettingsItem(
                  title: 'App Preferences',
                  subtitle: 'Notifications, theme, language',
                  icon: Icons.tune,
                  onTap: () => _navigateToScreen(const AppPreferencesScreen()),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Data & Backup Section
            _buildSettingsSection(
              title: 'Data & Backup',
              icon: Icons.storage,
              color: AppTheme.infoBlue,
              items: [
                _buildSettingsItem(
                  title: 'Export Data',
                  subtitle: 'Export users, payments, attendance',
                  icon: Icons.download,
                  onTap: () => _showExportDialog(),
                ),
                _buildSettingsItem(
                  title: 'Import Data',
                  subtitle: 'Import from backup or CSV',
                  icon: Icons.upload,
                  onTap: () => _showImportDialog(),
                ),
                _buildSettingsItem(
                  title: 'Clear Data',
                  subtitle: 'Reset all app data',
                  icon: Icons.delete_sweep,
                  onTap: () => _showClearDataDialog(),
                  isDestructive: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // About & Support Section
            _buildSettingsSection(
              title: 'About & Support',
              icon: Icons.help_outline,
              color: AppTheme.darkGrey,
              items: [
                _buildSettingsItem(
                  title: 'About App',
                  subtitle: 'Version, developer info',
                  icon: Icons.info,
                  onTap: () => _navigateToScreen(const AboutScreen()),
                ),
                _buildSettingsItem(
                  title: 'Help & Support',
                  subtitle: 'User guide, contact support',
                  icon: Icons.support,
                  onTap: () => _showSupportDialog(),
                ),
                _buildSettingsItem(
                  title: 'Rate App',
                  subtitle: 'Rate us on Play Store',
                  icon: Icons.star,
                  onTap: () => _rateApp(),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlack,
              AppTheme.primaryBlack.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.settings,
                size: 40,
                color: AppTheme.primaryBlack,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _settings.clubName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentYellow),
              ),
              child: Text(
                'Admin: ${_settings.adminName}',
                style: const TextStyle(
                  color: AppTheme.accentYellow,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isDestructive
            ? AppTheme.errorRed.withOpacity(0.05)
            : AppTheme.lightGrey.withOpacity(0.5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppTheme.errorRed.withOpacity(0.1)
                : AppTheme.primaryBlack.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppTheme.errorRed : AppTheme.primaryBlack,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDestructive ? AppTheme.errorRed : AppTheme.primaryBlack,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDestructive
                ? AppTheme.errorRed.withOpacity(0.7)
                : AppTheme.darkGrey.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDestructive
              ? AppTheme.errorRed.withOpacity(0.7)
              : AppTheme.darkGrey.withOpacity(0.7),
        ),
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: AppTheme.infoBlue),
            SizedBox(width: 8),
            Text('Export Data'),
          ],
        ),
        content: const Text('Select the data you want to export:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.infoBlue,
              foregroundColor: AppTheme.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _exportData();
            },
            child: const Text('Export All'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.upload, color: AppTheme.softGreen),
            SizedBox(width: 8),
            Text('Import Data'),
          ],
        ),
        content: const Text(
          'This will import data from a backup file. Existing data may be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.softGreen,
              foregroundColor: AppTheme.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _importData();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text('Clear All Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all users, payments, attendance records, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support, color: AppTheme.accentYellow),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: AppTheme.infoBlue),
              title: const Text('Email Support'),
              subtitle: const Text('support@magicalcommunity.com'),
              onTap: () => _contactSupport('email'),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.softGreen),
              title: const Text('Phone Support'),
              subtitle: const Text('+91 98765 43210'),
              onTap: () => _contactSupport('phone'),
            ),
            ListTile(
              leading: const Icon(Icons.book, color: AppTheme.accentYellow),
              title: const Text('User Guide'),
              subtitle: const Text('View documentation'),
              onTap: () => _openUserGuide(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data export initiated. File will be saved to Downloads.',
        ),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data import completed successfully.'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _clearAllData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data has been cleared.'),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  void _contactSupport(String method) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $method support...'),
        backgroundColor: AppTheme.infoBlue,
      ),
    );
  }

  void _openUserGuide() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening user guide...'),
        backgroundColor: AppTheme.accentYellow,
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Play Store...'),
        backgroundColor: AppTheme.softGreen,
      ),
    );
  }
}
