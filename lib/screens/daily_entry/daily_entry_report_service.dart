import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'daily_entry_model.dart';

enum ReportType { weekly, monthly }

class DailyEntryReportService {
  /// Generates an Excel report for the given entries and report type.
  /// Returns the file path of the generated Excel file.
  static Future<String> generateReport({
    required List<DailyEntryData> allEntries,
    required ReportType reportType,
  }) async {
    final now = DateTime.now();
    // Normalize to midnight to avoid time-of-day filtering issues
    final today = DateTime(now.year, now.month, now.day);
    late DateTime startDate;
    late String periodLabel;

    if (reportType == ReportType.weekly) {
      // Start from Monday of current week
      startDate = today.subtract(Duration(days: today.weekday - 1));
      final endDate = startDate.add(const Duration(days: 6));
      periodLabel =
          '${DateFormat('dd_MMM').format(startDate)}_to_${DateFormat('dd_MMM').format(endDate)}_${today.year}';
    } else {
      // Start from 1st of current month
      startDate = DateTime(today.year, today.month, 1);
      periodLabel = DateFormat('MMM_yyyy').format(today);
    }

    // Filter entries within range
    final endDate = reportType == ReportType.weekly
        ? startDate.add(const Duration(days: 7))
        : DateTime(today.year, today.month + 1, 1);

    final filtered = allEntries.where((e) {
      return !e.date.isBefore(startDate) && e.date.isBefore(endDate);
    }).toList();

    // Sort by date ascending
    filtered.sort((a, b) => a.date.compareTo(b.date));

    // Collect all unique product names across all filtered entries
    final Set<String> allProductNames = {};
    for (final entry in filtered) {
      allProductNames.addAll(entry.products.keys);
    }
    final productNames = allProductNames.toList()..sort();

    // Create Excel workbook
    final excel = Excel.createExcel();
    final sheetName = reportType == ReportType.weekly ? 'Weekly Report' : 'Monthly Report';
    final sheet = excel[sheetName];

    // Remove default sheet if different name
    if (excel.getDefaultSheet() != sheetName) {
      excel.delete(excel.getDefaultSheet()!);
    }

    // Column headers (fixed + dynamic products)
    final headers = [
      'DATE',
      'DAY',
      'VISIT ENTRY',
      'TRIALS START',
      'TRIAL SHAKES',
      'NEW UMS',
      'TOTAL UMS',
      'UMS SHAKES',
      'TOTAL SHAKES',
      'CASH PAYMENT',
      'UPI PAYMENT',
      'TOTAL PAYMENT',
      'CLUB EXPENSES',
      ...productNames,
    ];

    // Header style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2B2A29'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    // Write headers
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Data style
    final dataStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Write data rows
    for (var row = 0; row < filtered.length; row++) {
      final entry = filtered[row];
      final rowIndex = row + 1;

      final values = <CellValue>[
        TextCellValue(DateFormat('dd-MM-yyyy').format(entry.date)),
        TextCellValue(entry.dayName),
        IntCellValue(entry.visitEntry),
        IntCellValue(entry.trialsStart),
        IntCellValue(entry.trialShakes),
        IntCellValue(entry.newUms),
        IntCellValue(entry.totalUms),
        IntCellValue(entry.umsShakes),
        IntCellValue(entry.totalShakes),
        DoubleCellValue(entry.cashPayment),
        DoubleCellValue(entry.upiPayment),
        DoubleCellValue(entry.totalPayment),
        DoubleCellValue(entry.clubExpenses),
        // Dynamic product columns
        ...productNames.map((name) => IntCellValue(entry.products[name] ?? 0)),
      ];

      for (var col = 0; col < values.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
        );
        cell.value = values[col];
        cell.cellStyle = dataStyle;
      }
    }

    // Set column widths for readability
    for (var col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, headers[col].length < 10 ? 12 : headers[col].length.toDouble() + 4);
    }

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final typeLabel = reportType == ReportType.weekly ? 'Weekly' : 'Monthly';
    final fileName = 'DailyEntry_${typeLabel}_Report_$periodLabel.xlsx';
    final filePath = '${dir.path}/$fileName';
    final fileBytes = excel.save();

    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
    }

    return filePath;
  }

  /// Shares the generated Excel file
  static Future<void> shareReport(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Daily Entry Report',
    );
  }
}
