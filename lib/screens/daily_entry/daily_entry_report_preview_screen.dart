import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'daily_entry_model.dart';
import 'daily_entry_report_service.dart';

/// Full-screen preview of the report data with share + download actions.
class DailyEntryReportPreviewScreen extends StatefulWidget {
  final List<DailyEntryData> entries;
  final ReportType reportType;

  const DailyEntryReportPreviewScreen({
    super.key,
    required this.entries,
    required this.reportType,
  });

  @override
  State<DailyEntryReportPreviewScreen> createState() =>
      _DailyEntryReportPreviewScreenState();
}

class _DailyEntryReportPreviewScreenState
    extends State<DailyEntryReportPreviewScreen> {
  bool _isSharing = false;

  String get _typeLabel =>
      widget.reportType == ReportType.weekly ? 'Weekly' : 'Monthly';

  late final List<DailyEntryData> _filtered;
  late final List<String> _productNames;

  // Fixed column definitions
  static const List<String> _fixedColumns = [
    'DATE',
    'DAY',
    'VISIT\nENTRY',
    'TRIALS\nSTART',
    'TRIAL\nSHAKES',
    'NEW\nUMS',
    'TOTAL\nUMS',
    'UMS\nSHAKES',
    'TOTAL\nSHAKES',
    'CASH\nPAYMENT',
    'UPI\nPAYMENT',
    'TOTAL\nPAYMENT',
    'CLUB\nEXPENSES',
  ];

  @override
  void initState() {
    super.initState();
    _filtered = _filterEntries();
    _productNames = _collectProductNames();
  }

  List<DailyEntryData> _filterEntries() {
    final now = DateTime.now();
    // Normalize to midnight to avoid time-of-day filtering issues
    final today = DateTime(now.year, now.month, now.day);
    late DateTime startDate;
    late DateTime endDate;

    if (widget.reportType == ReportType.weekly) {
      startDate = today.subtract(Duration(days: today.weekday - 1));
      endDate = startDate.add(const Duration(days: 7));
    } else {
      startDate = DateTime(today.year, today.month, 1);
      endDate = DateTime(today.year, today.month + 1, 1);
    }

    final result = widget.entries.where((e) {
      return !e.date.isBefore(startDate) && e.date.isBefore(endDate);
    }).toList();

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// Collect all unique product names from filtered entries
  List<String> _collectProductNames() {
    final Set<String> names = {};
    for (final entry in _filtered) {
      names.addAll(entry.products.keys);
    }
    final sorted = names.toList()..sort();
    return sorted;
  }

  /// Get all column names (fixed + dynamic products)
  List<String> get _allColumns => [
        ..._fixedColumns,
        ..._productNames,
      ];

  List<String> _rowValues(DailyEntryData e) => [
        e.formattedDate,
        e.dayName.substring(0, 3), // Mon, Tue, etc.
        '${e.visitEntry}',
        '${e.trialsStart}',
        '${e.trialShakes}',
        '${e.newUms}',
        '${e.totalUms}',
        '${e.umsShakes}',
        '${e.totalShakes}',
        '${e.cashPayment.toStringAsFixed(0)}',
        '${e.upiPayment.toStringAsFixed(0)}',
        '${e.totalPayment.toStringAsFixed(0)}',
        '${e.clubExpenses.toStringAsFixed(0)}',
        // Dynamic product columns
        ..._productNames.map((name) => '${e.products[name] ?? 0}'),
      ];

  Future<void> _shareReport() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final filePath = await DailyEntryReportService.generateReport(
        allEntries: widget.entries,
        reportType: widget.reportType,
      );

      await Share.shareXFiles(
        [XFile(filePath)],
        text: '$_typeLabel Daily Entry Report',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share report: $e'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_typeLabel Report'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          _isSharing
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share Report',
                  onPressed: _shareReport,
                ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          _buildStatsHeader(),
          // Table
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyState()
                : _buildDataTable(),
          ),
        ],
      ),
      // Bottom share button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _isSharing ? null : _shareReport,
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                  )
                : const Icon(Icons.share, size: 20),
            label: Text(
              _isSharing ? 'Generating...' : 'Share $_typeLabel Report',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentYellow,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              shadowColor: AppTheme.accentYellow.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    // Calculate summary totals
    int totalVisits = 0, totalShakes = 0;
    double totalPayment = 0;
    for (final e in _filtered) {
      totalVisits += e.visitEntry;
      totalShakes += e.totalShakes;
      totalPayment += e.totalPayment;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlack.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.reportType == ReportType.weekly
                    ? Icons.date_range
                    : Icons.calendar_month,
                color: AppTheme.accentYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$_typeLabel Report • ${_filtered.length} entries',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryChip('Visits', '$totalVisits', AppTheme.infoBlue),
              const SizedBox(width: 8),
              _buildSummaryChip('Shakes', '$totalShakes', AppTheme.accentYellow),
              const SizedBox(width: 8),
              _buildSummaryChip('Payment', '₹${totalPayment.toStringAsFixed(0)}', AppTheme.successGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: AppTheme.darkGrey.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No entries for this period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add daily entries first, then generate the report.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.darkGrey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final columns = _allColumns;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.primaryBlack),
          dataRowMinHeight: 40,
          dataRowMaxHeight: 48,
          columnSpacing: 14,
          horizontalMargin: 12,
          headingRowHeight: 52,
          border: TableBorder.all(
            color: AppTheme.lightGrey,
            width: 1,
            borderRadius: BorderRadius.circular(8),
          ),
          columns: columns
              .map(
                (col) => DataColumn(
                  label: Text(
                    col,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.white,
                      height: 1.3,
                    ),
                  ),
                ),
              )
              .toList(),
          rows: _filtered.map((entry) {
            final values = _rowValues(entry);
            return DataRow(
              cells: values
                  .map(
                    (val) => DataCell(
                      Text(
                        val,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryBlack,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
