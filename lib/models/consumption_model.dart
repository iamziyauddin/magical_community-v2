import 'package:hive/hive.dart';

part 'consumption_model.g.dart';

@HiveType(typeId: 9)
class ConsumptionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String productId;

  @HiveField(2)
  String productName;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String addedBy;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String? notes;

  ConsumptionModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.date,
    required this.addedBy,
    required this.createdAt,
    this.notes,
  });

  ConsumptionModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    DateTime? date,
    String? addedBy,
    DateTime? createdAt,
    String? notes,
  }) {
    return ConsumptionModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}
