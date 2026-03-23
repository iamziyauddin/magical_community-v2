import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';

class FeesSettingsScreen extends StatefulWidget {
  const FeesSettingsScreen({super.key});

  @override
  State<FeesSettingsScreen> createState() => _FeesSettingsScreenState();
}

class _FeesSettingsScreenState extends State<FeesSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _trialFeeController = TextEditingController();
  final _membershipFeeController = TextEditingController();
  final _membershipDurationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // In real app, load from Hive
    _trialFeeController.text = '700';
    _membershipFeeController.text = '7500';
    _membershipDurationController.text = '30';
  }

  @override
  void dispose() {
    _trialFeeController.dispose();
    _membershipFeeController.dispose();
    _membershipDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Fees & Pricing'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _saveSettings, icon: const Icon(Icons.save)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                        AppTheme.softGreen,
                        AppTheme.softGreen.withOpacity(0.8),
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
                          Icons.attach_money,
                          size: 40,
                          color: AppTheme.softGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Fees & Pricing',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Configure trial fees, membership rates, and duration settings',
                        style: TextStyle(fontSize: 14, color: AppTheme.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Trial Fee Section
              _buildSection(
                title: 'Trial Settings',
                icon: Icons.fitness_center,
                color: AppTheme.accentYellow,
                children: [
                  _buildAmountField(
                    controller: _trialFeeController,
                    label: 'Trial Fee',
                    icon: Icons.money,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter trial fee';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentYellow.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.accentYellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Trial fee is charged for new members who want to try the gym before committing to a full membership.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.darkGrey.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Membership Fee Section
              _buildSection(
                title: 'Membership Settings',
                icon: Icons.card_membership,
                color: AppTheme.softGreen,
                children: [
                  _buildAmountField(
                    controller: _membershipFeeController,
                    label: 'Monthly Membership Fee',
                    icon: Icons.payment,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter membership fee';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    controller: _membershipDurationController,
                    label: 'Membership Duration (Days)',
                    icon: Icons.schedule,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter membership duration';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number of days';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.softGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.softGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.softGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Membership duration determines how long access is granted after payment.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.darkGrey.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Pricing Summary
              _buildPricingSummary(),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveSettings,
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
                        'Save Pricing',
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
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 16,
        color: AppTheme.primaryBlack,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.darkGrey),
        prefixText: '₹ ',
        prefixStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.softGreen,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.softGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.white,
        labelStyle: TextStyle(color: AppTheme.darkGrey.withOpacity(0.8)),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 16,
        color: AppTheme.primaryBlack,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.darkGrey),
        suffixText: 'days',
        suffixStyle: const TextStyle(fontSize: 14, color: AppTheme.darkGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.white,
        labelStyle: TextStyle(color: AppTheme.darkGrey.withOpacity(0.8)),
      ),
    );
  }

  Widget _buildPricingSummary() {
    double trialFee = double.tryParse(_trialFeeController.text) ?? 0;
    double membershipFee = double.tryParse(_membershipFeeController.text) ?? 0;
    int duration = int.tryParse(_membershipDurationController.text) ?? 0;
    double dailyRate = duration > 0 ? membershipFee / duration : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.infoBlue.withOpacity(0.1),
              AppTheme.infoBlue.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calculate,
                    color: AppTheme.infoBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pricing Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummaryRow('Trial Fee', '₹${trialFee.toInt()}'),
            _buildSummaryRow('Monthly Membership', '₹${membershipFee.toInt()}'),
            _buildSummaryRow('Membership Duration', '$duration days'),
            if (dailyRate > 0)
              _buildSummaryRow(
                'Daily Rate',
                '₹${dailyRate.toStringAsFixed(2)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.darkGrey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      // In real app, save to Hive
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pricing settings updated successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      // Optional: Navigate back
      Navigator.pop(context);
    }
  }
}
