import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  // Demo preference values - in real app, these would come from Hive
  bool _enableNotifications = true;
  bool _enablePushNotifications = true;
  bool _enableEmailNotifications = false;
  bool _enableSoundNotifications = true;
  bool _enableDarkMode = false;
  bool _enableAutoBackup = true;
  bool _enableBiometricLogin = false;
  String _selectedLanguage = 'English';
  String _selectedDateFormat = 'DD/MM/YYYY';
  String _selectedCurrency = 'INR (₹)';

  final List<String> _languages = [
    'English',
    'Hindi',
    'Marathi',
    'Tamil',
    'Telugu',
  ];
  final List<String> _dateFormats = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];
  final List<String> _currencies = ['INR (₹)', 'USD (\$)', 'EUR (€)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('App Preferences'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _savePreferences, icon: const Icon(Icons.save)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.infoBlue,
                      AppTheme.infoBlue.withOpacity(0.8),
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
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.tune,
                        size: 40,
                        color: AppTheme.infoBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'App Preferences',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Customize your app experience with notifications, appearance, and regional settings',
                      style: TextStyle(fontSize: 14, color: AppTheme.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notifications Section
            _buildSection(
              title: 'Notifications',
              icon: Icons.notifications,
              color: AppTheme.accentYellow,
              children: [
                _buildSwitchTile(
                  title: 'Enable Notifications',
                  subtitle: 'Receive app notifications',
                  icon: Icons.notifications_active,
                  value: _enableNotifications,
                  onChanged: (value) =>
                      setState(() => _enableNotifications = value),
                ),
                if (_enableNotifications) ...[
                  _buildSwitchTile(
                    title: 'Push Notifications',
                    subtitle: 'Get instant push notifications',
                    icon: Icons.phone_android,
                    value: _enablePushNotifications,
                    onChanged: (value) =>
                        setState(() => _enablePushNotifications = value),
                  ),
                  _buildSwitchTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive notifications via email',
                    icon: Icons.email,
                    value: _enableEmailNotifications,
                    onChanged: (value) =>
                        setState(() => _enableEmailNotifications = value),
                  ),
                  _buildSwitchTile(
                    title: 'Sound & Vibration',
                    subtitle: 'Play notification sounds',
                    icon: Icons.volume_up,
                    value: _enableSoundNotifications,
                    onChanged: (value) =>
                        setState(() => _enableSoundNotifications = value),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Appearance Section
            _buildSection(
              title: 'Appearance',
              icon: Icons.palette,
              color: AppTheme.softGreen,
              children: [
                _buildSwitchTile(
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme (Coming Soon)',
                  icon: Icons.dark_mode,
                  value: _enableDarkMode,
                  onChanged: (value) => setState(() => _enableDarkMode = value),
                ),
                _buildInfoTile(
                  title: 'Current Theme',
                  subtitle: 'Black & Yellow theme is active',
                  icon: Icons.color_lens,
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlack, AppTheme.accentYellow],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Regional Settings Section
            _buildSection(
              title: 'Regional Settings',
              icon: Icons.language,
              color: AppTheme.infoBlue,
              children: [
                _buildDropdownTile(
                  title: 'Language',
                  subtitle: 'App display language',
                  icon: Icons.translate,
                  value: _selectedLanguage,
                  items: _languages,
                  onChanged: (value) =>
                      setState(() => _selectedLanguage = value!),
                ),
                _buildDropdownTile(
                  title: 'Date Format',
                  subtitle: 'How dates are displayed',
                  icon: Icons.date_range,
                  value: _selectedDateFormat,
                  items: _dateFormats,
                  onChanged: (value) =>
                      setState(() => _selectedDateFormat = value!),
                ),
                _buildDropdownTile(
                  title: 'Currency',
                  subtitle: 'Currency symbol and format',
                  icon: Icons.attach_money,
                  value: _selectedCurrency,
                  items: _currencies,
                  onChanged: (value) =>
                      setState(() => _selectedCurrency = value!),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Security & Privacy Section
            _buildSection(
              title: 'Security & Privacy',
              icon: Icons.security,
              color: AppTheme.errorRed,
              children: [
                _buildSwitchTile(
                  title: 'Biometric Login',
                  subtitle: 'Use fingerprint or face unlock',
                  icon: Icons.fingerprint,
                  value: _enableBiometricLogin,
                  onChanged: (value) =>
                      setState(() => _enableBiometricLogin = value),
                ),
                _buildSwitchTile(
                  title: 'Auto Backup',
                  subtitle: 'Automatically backup data',
                  icon: Icons.backup,
                  value: _enableAutoBackup,
                  onChanged: (value) =>
                      setState(() => _enableAutoBackup = value),
                ),
                _buildActionTile(
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  icon: Icons.cleaning_services,
                  onTap: _clearCache,
                ),
                _buildActionTile(
                  title: 'Reset Preferences',
                  subtitle: 'Restore default settings',
                  icon: Icons.restore,
                  onTap: _resetPreferences,
                  isDestructive: true,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack,
                  foregroundColor: AppTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save),
                    const SizedBox(width: 8),
                    const Text(
                      'Save Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
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
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlack.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlack, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.primaryBlack,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.darkGrey.withOpacity(0.7),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentYellow,
          activeTrackColor: AppTheme.accentYellow.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.infoBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.infoBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.primaryBlack,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.darkGrey.withOpacity(0.7),
          ),
        ),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          underline: const SizedBox(),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.softGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.softGreen, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.primaryBlack,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.darkGrey.withOpacity(0.7),
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildActionTile({
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

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services, color: AppTheme.infoBlue),
            SizedBox(width: 8),
            Text('Clear Cache'),
          ],
        ),
        content: const Text(
          'This will clear temporary files and free up storage space. Your personal data will not be affected.',
        ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _resetPreferences() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text('Reset Preferences'),
          ],
        ),
        content: const Text(
          'This will reset all app preferences to their default values. This action cannot be undone.',
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
              _resetToDefaults();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _enableNotifications = true;
      _enablePushNotifications = true;
      _enableEmailNotifications = false;
      _enableSoundNotifications = true;
      _enableDarkMode = false;
      _enableAutoBackup = true;
      _enableBiometricLogin = false;
      _selectedLanguage = 'English';
      _selectedDateFormat = 'DD/MM/YYYY';
      _selectedCurrency = 'INR (₹)';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences reset to defaults'),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  void _savePreferences() {
    // In real app, save to Hive
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved successfully!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );

    // Optional: Navigate back
    Navigator.pop(context);
  }
}
