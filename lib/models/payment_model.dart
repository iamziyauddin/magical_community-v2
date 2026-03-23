import 'package:hive/hive.dart';

part 'payment_model.g.dart';

@HiveType(typeId: 3)
enum PaymentType {
  @HiveField(0)
  trial,
  @HiveField(1)
  membership,
  @HiveField(2)
  expense,
}

// Enum for income types in the UI (not stored directly in Hive)
enum IncomeType {
  ums, // UMS option - pass 'membership' to API
  trial, // Trial option - pass 'trial' to API
  others, // Others option - existing flow
}

@HiveType(typeId: 4)
enum PaymentMode {
  @HiveField(0)
  cash,
  @HiveField(1)
  online,
  // @HiveField(2)
  // upi,
  // @HiveField(3)
  // netBanking,
  // @HiveField(4)
  // other,
}

@HiveType(typeId: 5)
class PaymentModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String? userId; // null for expenses

  @HiveField(10)
  String? linkedUserName; // Store user name for display purposes

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  PaymentType type;

  @HiveField(5)
  PaymentMode? mode;

  @HiveField(6)
  String? description;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  bool isIncome; // true for trial/membership, false for expenses

  @HiveField(9)
  DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.amount,
    this.userId,
    this.linkedUserName,
    required this.date,
    required this.type,
    this.mode,
    this.description,
    this.notes,
    required this.isIncome,
    required this.createdAt,
  });

  PaymentModel copyWith({
    String? id,
    double? amount,
    String? userId,
    String? linkedUserName,
    DateTime? date,
    PaymentType? type,
    PaymentMode? mode,
    String? description,
    String? notes,
    bool? isIncome,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      userId: userId ?? this.userId,
      linkedUserName: linkedUserName ?? this.linkedUserName,
      date: date ?? this.date,
      type: type ?? this.type,
      mode: mode ?? this.mode,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      isIncome: isIncome ?? this.isIncome,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
