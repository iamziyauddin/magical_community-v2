import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'daily_entry_model.dart';

/// Read-only detail view of a single daily entry.
class DailyEntryDetailScreen extends StatelessWidget {
  final DailyEntryData entry;

  const DailyEntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Details'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date & Day Header Card
            _buildDateHeader(),
            const SizedBox(height: 20),

            // Entry Details
            _buildSection('Entry Details', Icons.edit_note, [
              _DetailItem('Visit Entry', '${entry.visitEntry}', Icons.login),
              _DetailItem("Trial's Start", '${entry.trialsStart}', Icons.play_arrow),
            ]),
            const SizedBox(height: 16),

            // Shakes & UMS
            _buildSection('Shakes & UMS', Icons.local_drink, [
              _DetailItem('Trial Shakes', '${entry.trialShakes}', Icons.science),
              _DetailItem('UMS Shakes', '${entry.umsShakes}', Icons.blender),
              _DetailItem('New UMS', '${entry.newUms}', Icons.person_add),
              _DetailItem('Total UMS', '${entry.totalUms}', Icons.groups),
            ]),
            const SizedBox(height: 8),
            _buildTotalCard('Total Shakes', '${entry.totalShakes}', AppTheme.accentYellow, Icons.calculate),
            const SizedBox(height: 16),

            // Payments
            _buildSection('Payments', Icons.payment, [
              _DetailItem('Cash Payment', '₹${entry.cashPayment.toStringAsFixed(2)}', Icons.money),
              _DetailItem('UPI Payment', '₹${entry.upiPayment.toStringAsFixed(2)}', Icons.phone_android),
              _DetailItem('Club Expenses', '₹${entry.clubExpenses.toStringAsFixed(2)}', Icons.account_balance),
            ]),
            const SizedBox(height: 8),
            _buildTotalCard('Total Payment', '₹${entry.totalPayment.toStringAsFixed(2)}', AppTheme.successGreen, Icons.account_balance_wallet),
            const SizedBox(height: 16),

            // Products (dynamic)
            if (entry.products.isNotEmpty)
              _buildSection('Products', Icons.inventory_2, [
                ...entry.products.entries.map(
                  (e) => _DetailItem(e.key, '${e.value}', _getProductIcon(e.key)),
                ),
              ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Returns an icon based on the product name
  IconData _getProductIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('sofit') || lower.contains('soft')) return Icons.local_cafe;
    if (lower.contains('formula') || lower.contains('fi')) return Icons.fitness_center;
    if (lower.contains('ppp') || lower.contains('ptt') || lower.contains('ppt')) return Icons.sports_gymnastics;
    if (lower.contains('afresh')) return Icons.local_florist;
    if (lower.contains('hydrate')) return Icons.water_drop;
    if (lower.contains('shake')) return Icons.local_drink;
    return Icons.inventory_2;
  }

  Widget _buildDateHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlack,
              AppTheme.primaryBlack.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today, color: AppTheme.accentYellow, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.formattedDate,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.dayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.accentYellow.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData headerIcon, List<_DetailItem> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppTheme.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(headerIcon, color: AppTheme.accentYellow, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlack,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildDetailRow(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(_DetailItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(item.icon, color: AppTheme.accentYellow, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.darkGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGrey,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  final IconData icon;

  _DetailItem(this.label, this.value, this.icon);
}
