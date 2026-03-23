import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/models/settings_model.dart';
import 'package:magical_community/screens/settings/account_settings_screen.dart';
import 'package:magical_community/screens/settings/change_password_screen.dart';
import 'package:magical_community/screens/settings/about_screen.dart';
import 'package:magical_community/screens/settings/support_contact_screen.dart';
import 'package:magical_community/core/utils/auth_utils.dart';
import 'package:magical_community/core/config/env.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Settings'),
            if (Env.isDev) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.warningOrange.withOpacity(0.6),
                  ),
                ),
                child: const Text(
                  'DEV',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warningOrange,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  AuthUtils.showLogoutDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.errorRed),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Account Settings (Profile + Club)
            _buildSettingsSection(
              title: 'Account Settings',
              icon: Icons.manage_accounts,
              color: AppTheme.accentYellow,
              items: [
                _buildSettingsItem(
                  title: 'Profile & Club',
                  subtitle: 'Name, contact, club details',
                  icon: Icons.info_outline,
                  onTap: () => _navigateToScreen(const AccountSettingsScreen()),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Spacer or additional settings can go here
            const SizedBox(height: 16),

            // Change Password Section (Standalone)
            _buildSettingsSection(
              title: 'Security',
              icon: Icons.security,
              color: AppTheme.warningOrange,
              items: [
                _buildSettingsItem(
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  icon: Icons.lock_reset,
                  onTap: () => _navigateToScreen(const ChangePasswordScreen()),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // About & Support Section
            _buildSettingsSection(
              title: 'About & Support',
              icon: Icons.help_outline,
              color: AppTheme.infoBlue,
              items: [
                _buildSettingsItem(
                  title: 'About App',
                  subtitle: 'Version, terms, privacy policy',
                  icon: Icons.info,
                  onTap: () => _navigateToScreen(const AboutScreen()),
                ),
                _buildSettingsItem(
                  title: 'Support & Contact',
                  subtitle: 'Get help and contact us',
                  icon: Icons.support_agent,
                  onTap: () => _navigateToScreen(const SupportContactScreen()),
                ),
                // _buildSettingsItem(
                //   title: 'Help ',
                //   subtitle: 'Help and support',
                //   icon: Icons.help_outline,
                //   onTap: () => _showSupportDialog(),
                // ),
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
}
