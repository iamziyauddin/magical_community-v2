import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/core/services/api_service.dart';
import 'daily_entry_model.dart';
import 'daily_entry_form_screen.dart';
import 'daily_entry_detail_screen.dart';
import 'daily_entry_report_service.dart';
import 'daily_entry_report_preview_screen.dart';

class DailyEntryScreen extends StatefulWidget {
  const DailyEntryScreen({super.key});

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<DailyEntryData> _entries = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDailyEntries();
  }

  // ─── API ────────────────────────────────────────────────────────

  Future<void> _fetchDailyEntries() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await ApiService.get(
        '/daily-entries/?page=1&limit=30',
        context: context,
      );

      if (response != null && response['success'] == true) {
        final List<dynamic> entriesJson =
            (response['data']?['entries'] as List?) ?? [];

        final List<DailyEntryData> fetched = entriesJson.map((json) {
          return _parseDailyEntry(json as Map<String, dynamic>);
        }).toList();

        // Sort newest first
        fetched.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          _entries
            ..clear()
            ..addAll(fetched);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load entries.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Parse a single daily entry from API JSON
  DailyEntryData _parseDailyEntry(Map<String, dynamic> json) {
    final DateTime entryDate =
        DateTime.tryParse(json['entryDate'] ?? '') ?? DateTime.now();

    // Parse products array into Map<String, int>
    final Map<String, int> productsMap = {};
    final List<dynamic> productsJson =
        (json['products'] as List?) ?? [];
    for (final p in productsJson) {
      final name = p['productName']?.toString() ?? 'Unknown';
      final qty = (p['quantity'] as num?)?.toInt() ?? 0;
      productsMap[name] = qty;
    }

    return DailyEntryData(
      id: json['id']?.toString() ?? '',
      date: DateTime(entryDate.year, entryDate.month, entryDate.day),
      visitEntry: (json['visitEntry'] as num?)?.toInt() ?? 0,
      trialsStart: (json['trialsStart'] as num?)?.toInt() ?? 0,
      trialShakes: (json['trialShakes'] as num?)?.toInt() ?? 0,
      umsShakes: (json['umsShakes'] as num?)?.toInt() ?? 0,
      newUms: (json['newUms'] as num?)?.toInt() ?? 0,
      totalUms: (json['totalUms'] as num?)?.toInt() ?? 0,
      totalShakes: (json['totalShakes'] as num?)?.toInt() ?? 0,
      cashPayment: (json['cashPayment'] as num?)?.toDouble() ?? 0,
      upiPayment: (json['upiPayment'] as num?)?.toDouble() ?? 0,
      clubExpenses: (json['clubExpenses'] as num?)?.toDouble() ?? 0,
      totalPayment: (json['totalPayment'] as num?)?.toDouble() ?? 0,
      products: productsMap,
    );
  }

  // ─── Navigation helpers ────────────────────────────────────────

  Future<void> _openAddForm() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => const DailyEntryFormScreen()),
    );
    // result is true when the POST was successful
    if (result == true) {
      _showSnackBar('Daily entry added successfully!');
      _fetchDailyEntries(); // Refresh list from API
    }
  }

  Future<void> _openEditForm(int index) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyEntryFormScreen(existingEntry: _entries[index]),
      ),
    );
    if (result == true) {
      _showSnackBar('Daily entry updated successfully!');
      _fetchDailyEntries(); // Refresh list from API
    }
  }

  void _openDetail(DailyEntryData entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyEntryDetailScreen(entry: entry),
      ),
    );
  }

  Future<void> _deleteEntry(int index) async {
    if (_isDeleting) return;

    final entry = _entries[index];
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 26),
            const SizedBox(width: 10),
            const Text('Delete Entry', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the entry for ${entry.formattedDate}?',
          style: const TextStyle(fontSize: 14, color: AppTheme.darkGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.darkGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    _showProgressDialog('Deleting entry...');

    try {
      final response = await ApiService.delete(
        '/daily-entries/${entry.id}',
        context: context,
        showSuccessMessage: false,
      );

      // Dismiss progress dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response != null && response['success'] == true) {
        _showSnackBar('Daily entry deleted successfully');
        _fetchDailyEntries(); // Refresh the list from the API
      } else {
        _showErrorSnackBar('Failed to delete entry. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // ensure progress dialog is closed
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showProgressDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.errorRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Report ────────────────────────────────────────────────────

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.darkGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined, color: AppTheme.accentYellow, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Download Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a report period to generate and share an Excel file.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkGrey.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 20),
              // Weekly
              _buildReportOption(
                ctx,
                icon: Icons.date_range,
                title: 'Weekly Report',
                subtitle: 'Current week (Mon – Sun)',
                color: AppTheme.infoBlue,
                reportType: ReportType.weekly,
              ),
              const SizedBox(height: 10),
              // Monthly
              _buildReportOption(
                ctx,
                icon: Icons.calendar_month,
                title: 'Monthly Report',
                subtitle: 'Current month',
                color: AppTheme.accentYellow,
                reportType: ReportType.monthly,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(
    BuildContext sheetCtx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ReportType reportType,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pop(sheetCtx);
          _openReportPreview(reportType);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppTheme.white,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkGrey.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openReportPreview(ReportType reportType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyEntryReportPreviewScreen(
          entries: _entries,
          reportType: reportType,
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Entry'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.description_outlined),
        //     tooltip: 'Download Report',
        //     onPressed: _showReportOptions,
        //   ),
        // ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddForm,
        backgroundColor: AppTheme.accentYellow,
        foregroundColor: AppTheme.white,
        elevation: 6,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.accentYellow,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading entries...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGrey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 56,
                color: AppTheme.errorRed.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load entries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkGrey.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchDailyEntries,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentYellow,
                  foregroundColor: AppTheme.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchDailyEntries,
      color: AppTheme.accentYellow,
      child: _buildList(),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_calendar_outlined,
                size: 64,
                color: AppTheme.accentYellow.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Entries Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlack,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the button below to add your\nfirst daily entry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkGrey.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── List ──────────────────────────────────────────────────────

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return _buildEntryCard(entry, index);
      },
    );
  }

  Widget _buildEntryCard(DailyEntryData entry, int index) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openDetail(entry),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppTheme.white,
                AppTheme.accentYellow.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Top row: date & actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today, color: AppTheme.accentYellow, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.dayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.accentYellow.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  _buildIconAction(Icons.edit_outlined, AppTheme.infoBlue, () => _openEditForm(index)),
                  const SizedBox(width: 4),
                  // Delete button
                  _buildIconAction(Icons.delete_outline, AppTheme.errorRed, () => _deleteEntry(index)),
                ],
              ),
              const SizedBox(height: 14),

              // Divider
              Container(
                height: 1,
                color: AppTheme.lightGrey,
              ),
              const SizedBox(height: 14),

              // Summary stats row
              Row(
                children: [
                  _buildStatChip(Icons.login, 'Visits', '${entry.visitEntry}', AppTheme.infoBlue),
                  _buildStatChip(Icons.local_drink, 'Shakes', '${entry.totalShakes}', AppTheme.accentYellow),
                  _buildStatChip(Icons.account_balance_wallet, 'Payment', '₹${entry.totalPayment.toStringAsFixed(0)}', AppTheme.successGreen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconAction(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
