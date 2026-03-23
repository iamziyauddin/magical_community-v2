import 'package:intl/intl.dart';

class DailyEntryData {
  final String id;
  final DateTime date;
  final int visitEntry;
  final int trialsStart;
  final int trialShakes;
  final int umsShakes;
  final int newUms;
  final int totalUms;
  final int totalShakes;
  final double cashPayment;
  final double upiPayment;
  final double clubExpenses;
  final double totalPayment;

  /// Dynamic products map: key = product name, value = quantity
  final Map<String, int> products;

  DailyEntryData({
    required this.id,
    required this.date,
    this.visitEntry = 0,
    this.trialsStart = 0,
    this.trialShakes = 0,
    this.umsShakes = 0,
    this.newUms = 0,
    this.totalUms = 0,
    this.totalShakes = 0,
    this.cashPayment = 0,
    this.upiPayment = 0,
    this.clubExpenses = 0,
    this.totalPayment = 0,
    this.products = const {},
  });

  String get dayName => DateFormat('EEEE').format(date);
  String get formattedDate => DateFormat('dd MMM yyyy').format(date);

  /// Helper to get a product quantity by name (case-insensitive)
  int getProductQuantity(String name) {
    final key = products.keys.firstWhere(
      (k) => k.toLowerCase() == name.toLowerCase(),
      orElse: () => '',
    );
    return key.isEmpty ? 0 : products[key] ?? 0;
  }

  DailyEntryData copyWith({
    String? id,
    DateTime? date,
    int? visitEntry,
    int? trialsStart,
    int? trialShakes,
    int? umsShakes,
    int? newUms,
    int? totalUms,
    int? totalShakes,
    double? cashPayment,
    double? upiPayment,
    double? clubExpenses,
    double? totalPayment,
    Map<String, int>? products,
  }) {
    return DailyEntryData(
      id: id ?? this.id,
      date: date ?? this.date,
      visitEntry: visitEntry ?? this.visitEntry,
      trialsStart: trialsStart ?? this.trialsStart,
      trialShakes: trialShakes ?? this.trialShakes,
      umsShakes: umsShakes ?? this.umsShakes,
      newUms: newUms ?? this.newUms,
      totalUms: totalUms ?? this.totalUms,
      totalShakes: totalShakes ?? this.totalShakes,
      cashPayment: cashPayment ?? this.cashPayment,
      upiPayment: upiPayment ?? this.upiPayment,
      clubExpenses: clubExpenses ?? this.clubExpenses,
      totalPayment: totalPayment ?? this.totalPayment,
      products: products ?? this.products,
    );
  }
}
