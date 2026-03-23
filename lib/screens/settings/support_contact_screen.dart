import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';

class SupportContactScreen extends StatelessWidget {
  const SupportContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Support & Contact'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
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
                padding: const EdgeInsets.all(32),
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
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlack.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        size: 60,
                        color: AppTheme.infoBlue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Get Help & Support',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We\'re here to help you with any questions or issues',
                      style: TextStyle(fontSize: 16, color: AppTheme.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact Methods Section
            _buildSection(
              title: 'Contact Methods',
              icon: Icons.contact_support,
              color: AppTheme.infoBlue,
              children: [
                _buildContactItem(
                  title: 'Email Support',
                  subtitle: 'support@magicalcommunity.com',
                  icon: Icons.email,
                  color: AppTheme.infoBlue,
                  onTap: () => _contactSupport(context, 'email'),
                ),
                _buildContactItem(
                  title: 'Phone Support',
                  subtitle: '+91 85301 40707',
                  icon: Icons.phone,
                  color: AppTheme.softGreen,
                  onTap: () => _contactSupport(context, 'phone'),
                ),
                _buildContactItem(
                  title: 'WhatsApp Support',
                  subtitle: '+91 85301 40707',
                  icon: Icons.chat,
                  color: AppTheme.successGreen,
                  onTap: () => _contactSupport(context, 'whatsapp'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Online Resources Section
            // _buildSection(
            //   title: 'Online Resources',
            //   icon: Icons.public,
            //   color: AppTheme.accentYellow,
            //   children: [
            //     _buildContactItem(
            //       title: 'Website',
            //       subtitle: 'www.magicalcommunity.com',
            //       icon: Icons.web,
            //       color: AppTheme.accentYellow,
            //       onTap: () => _openWebsite(context),
            //     ),
            //     _buildContactItem(
            //       title: 'FAQ & Documentation',
            //       subtitle: 'Find answers to common questions',
            //       icon: Icons.help_center,
            //       color: AppTheme.infoBlue,
            //       onTap: () => _openFAQ(context),
            //     ),
            //     _buildContactItem(
            //       title: 'Video Tutorials',
            //       subtitle: 'Watch step-by-step guides',
            //       icon: Icons.play_circle,
            //       color: AppTheme.errorRed,
            //       onTap: () => _openTutorials(context),
            //     ),
            //   ],
            // ),

            // const SizedBox(height: 16),

            // // Feedback Section
            // _buildSection(
            //   title: 'Feedback & Reports',
            //   icon: Icons.feedback,
            //   color: AppTheme.warningOrange,
            //   children: [
            //     _buildContactItem(
            //       title: 'Report a Bug',
            //       subtitle: 'Help us improve the app',
            //       icon: Icons.bug_report,
            //       color: AppTheme.errorRed,
            //       onTap: () => _reportBug(context),
            //     ),
            //     _buildContactItem(
            //       title: 'Feature Request',
            //       subtitle: 'Suggest new features',
            //       icon: Icons.lightbulb,
            //       color: AppTheme.accentYellow,
            //       onTap: () => _requestFeature(context),
            //     ),
            //     _buildContactItem(
            //       title: 'Rate Our App',
            //       subtitle: 'Share your experience',
            //       icon: Icons.star_rate,
            //       color: AppTheme.warningOrange,
            //       onTap: () => _rateApp(context),
            //     ),
            //   ],
            // ),

            // const SizedBox(height: 24),

            // Support Hours Info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.softGreen.withOpacity(0.05),
                  border: Border.all(
                    color: AppTheme.softGreen.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: AppTheme.softGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Support Hours',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.softGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Monday - Friday: 9:00 AM to 6:00 PM\n'
                      '• Saturday: 10:00 AM to 4:00 PM\n'
                      '• Sunday: Closed\n'
                      '• Emergency support: 24/7 via email',
                      style: TextStyle(
                        color: AppTheme.darkGrey,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildContactItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
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
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.darkGrey.withOpacity(0.7),
        ),
      ),
    );
  }

  void _contactSupport(BuildContext context, String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $method support...'),
        backgroundColor: AppTheme.infoBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openWebsite(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening website...'),
        backgroundColor: AppTheme.accentYellow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFAQ(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening FAQ section...'),
        backgroundColor: AppTheme.infoBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openTutorials(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening video tutorials...'),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reportBug(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening bug report form...'),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _requestFeature(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening feature request form...'),
        backgroundColor: AppTheme.accentYellow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening app store for rating...'),
        backgroundColor: AppTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
