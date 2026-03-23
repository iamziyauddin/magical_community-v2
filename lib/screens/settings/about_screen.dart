import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentYellow.withOpacity(0.1),
                      AppTheme.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.accentYellow,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentYellow.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 60,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Magical Community',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentYellow),
                      ),
                      child: const Text(
                        // 'Version 1.0.10',
                        'Version 1.0.10 v13',
                        style: TextStyle(
                          color: AppTheme.primaryBlack,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Comprehensive Wellness Community System',
                      style: TextStyle(fontSize: 16, color: AppTheme.darkGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Information Section
            // _buildSection(
            //   title: 'App Information',
            //   icon: Icons.info,
            //   color: AppTheme.infoBlue,
            //   children: [
            //     _buildInfoRow('Version', '1.0.0 (Build 1)'),
            //     _buildInfoRow('Release Date', 'January 2024'),
            //     _buildInfoRow('Platform', 'Flutter (Android & iOS)'),
            //     _buildInfoRow('Database', 'Hive (Local Storage)'),
            //     _buildInfoRow('Last Updated', 'December 2024'),
            //   ],
            // ),
            const SizedBox(height: 16),

            // Features Section
            _buildSection(
              title: 'Key Features',
              icon: Icons.star,
              color: AppTheme.accentYellow,
              children: [
                _buildFeatureItem(
                  'User Management',
                  'Members, trials, and visitor tracking',
                ),
                _buildFeatureItem(
                  'Financial Tracking',
                  'Income, expenses, and payment management',
                ),
                _buildFeatureItem(
                  'Inventory System',
                  'Product consumption and stock management',
                ),
                _buildFeatureItem(
                  'Dashboard Analytics',
                  'Real-time stats and attendance tracking',
                ),
                _buildFeatureItem(
                  'Settings & Preferences',
                  'Customizable app configuration',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Legal & Privacy Section
            _buildSection(
              title: 'Legal & Privacy',
              icon: Icons.privacy_tip,
              color: AppTheme.errorRed,
              children: [
                _buildActionItem(
                  title: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  icon: Icons.policy,
                  onTap: () => _showPrivacyPolicy(context),
                ),
                _buildActionItem(
                  title: 'Terms of Service',
                  subtitle: 'App usage terms and conditions',
                  icon: Icons.description,
                  onTap: () => _showTermsOfService(context),
                ),
                _buildActionItem(
                  title: 'Open Source Licenses',
                  subtitle: 'Third-party libraries and licenses',
                  icon: Icons.code,
                  onTap: () => _showLicenses(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Footer
            _buildFooter(),

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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.darkGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.primaryBlack,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentYellow.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentYellow.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.check_circle,
              color: AppTheme.accentYellow,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGrey.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: AppTheme.lightGrey.withOpacity(0.5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.errorRed, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.primaryBlack,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.darkGrey.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.darkGrey.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.darkGrey.withOpacity(0.1),
              AppTheme.darkGrey.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              '© 2024 Magical Community Solutions',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkGrey.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Text(
            //   'Made with ❤️ using Flutter',
            //   style: TextStyle(
            //     fontSize: 12,
            //     color: AppTheme.darkGrey.withOpacity(0.6),
            //   ),
            //   textAlign: TextAlign.center,
            // ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: AppTheme.softGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Trusted by wellness communities',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.softGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last updated: August 2025',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkGrey.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Magical Community is a wellness program app that helps manage members, payments, and program participation.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data we collect',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _PolicyBullet(
                'Basic info: name, phone, and contact details you provide.',
              ),
              _PolicyBullet(
                'Membership details: plan type, start/end dates, and fees.',
              ),
              _PolicyBullet(
                'Program activity: attendance and participation records.',
              ),
              _PolicyBullet(
                'Payments: amounts, dates, and payment method (cash/online).',
              ),
              const SizedBox(height: 16),
              const Text(
                'How we use your data',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _PolicyBullet(
                'Provide and manage membership and wellness program services.',
              ),
              _PolicyBullet(
                'Record payments, track dues, and generate summaries.',
              ),
              _PolicyBullet(
                'Send reminders/notifications related to program activity.',
              ),
              _PolicyBullet(
                'Improve service quality through aggregate analytics.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Legal basis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _PolicyBullet(
                'Your consent and/or performance of a membership agreement.',
              ),
              _PolicyBullet(
                'Legitimate interests in running a wellness program safely.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Storage & security',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _PolicyBullet(
                'Data is stored securely. We apply reasonable technical and organizational measures to protect it.',
              ),
              _PolicyBullet(
                'Access is limited to authorized personnel and your organization as applicable.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Sharing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _PolicyBullet('We do not sell your data.'),
              _PolicyBullet(
                'We may share minimal data with service providers (e.g., hosting) under strict contracts.',
              ),
              _PolicyBullet(
                'We may disclose information if required by law or to protect rights and safety.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Retention',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _PolicyBullet(
                'We retain data for as long as your account is active or as needed to provide services and comply with legal obligations.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Your rights',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _PolicyBullet(
                'Request access, correction, export, or deletion of your data (subject to legal limits).',
              ),
              _PolicyBullet(
                'Withdraw consent where processing relies on consent.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Children',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _PolicyBullet(
                'The app is intended for use by organizations managing members. Parental/guardian consent may be required for minors as per local law.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'For privacy questions or requests, contact support@magicalcommunity.example',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
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

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Last updated: August 2025',
                style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
              ),
              SizedBox(height: 12),
              Text(
                'These Terms govern your use of Magical Community, a wellness program management app. By using the app, you agree to these Terms.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                '1. Service Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _PolicyBullet(
                'Tools to manage members, program participation, and payments.',
              ),
              _PolicyBullet('May include reminders, summaries, and analytics.'),
              SizedBox(height: 16),
              Text(
                '2. Accounts & Responsibilities',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _PolicyBullet(
                'Provide accurate information and keep credentials secure.',
              ),
              _PolicyBullet(
                'Comply with applicable data protection laws when handling member data.',
              ),
              SizedBox(height: 16),
              Text(
                '3. Payments & Refunds',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _PolicyBullet(
                'The app records payments and dues. Any fees or refunds are managed by your organization’s policy.',
              ),
              SizedBox(height: 16),
              Text(
                '4. Acceptable Use',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _PolicyBullet(
                'Do not misuse, disrupt, or attempt to gain unauthorized access to the app or data.',
              ),
              _PolicyBullet(
                'Do not upload unlawful content or violate others’ rights.',
              ),
              SizedBox(height: 16),
              Text(
                '5. Intellectual Property',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _PolicyBullet(
                'The app and its content are owned by the developer. You receive a limited right to use the app subject to these Terms.',
              ),
              SizedBox(height: 16),
              Text(
                '6. Disclaimers & Liability',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _PolicyBullet(
                'The app is provided “as is”. We disclaim warranties to the extent permitted by law.',
              ),
              _PolicyBullet(
                'We are not liable for indirect or consequential damages to the extent permitted by law.',
              ),
              SizedBox(height: 16),
              Text(
                '7. Termination',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _PolicyBullet(
                'We may suspend or terminate access for breach of these Terms or unlawful use.',
              ),
              SizedBox(height: 16),
              Text(
                '8. Changes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _PolicyBullet(
                'We may update these Terms. Continued use means you accept the updated Terms.',
              ),
              SizedBox(height: 16),
              Text(
                '9. Contact',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Questions? Contact support@magicalcommunity.example',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
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

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Magical Community',
      applicationVersion: '1.0.0',
    );
  }
}

// Small helper used in dialogs for bullet items
class _PolicyBullet extends StatelessWidget {
  final String text;
  const _PolicyBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
