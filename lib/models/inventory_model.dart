import 'package:hive/hive.dart';

part 'inventory_model.g.dart';

@HiveType(typeId: 7)
class InventoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String productName;

  @HiveField(2)
  int currentStock;

  @HiveField(3)
  int totalReceived;

  @HiveField(4)
  int totalUsed;

  @HiveField(5)
  DateTime lastUpdated;

  @HiveField(6)
  String? description;

  @HiveField(7)
  DateTime createdAt;

  InventoryModel({
    required this.id,
    required this.productName,
    required this.currentStock,
    required this.totalReceived,
    required this.totalUsed,
    required this.lastUpdated,
    this.description,
    required this.createdAt,
  });

  InventoryModel copyWith({
    String? id,
    String? productName,
    int? currentStock,
    int? totalReceived,
    int? totalUsed,
    DateTime? lastUpdated,
    String? description,
    DateTime? createdAt,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      currentStock: currentStock ?? this.currentStock,
      totalReceived: totalReceived ?? this.totalReceived,
      totalUsed: totalUsed ?? this.totalUsed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@HiveType(typeId: 8)
class InventoryLogModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String inventoryId;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  bool isAddition; // true for stock received, false for usage

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  DateTime createdAt;

  InventoryLogModel({
    required this.id,
    required this.inventoryId,
    required this.quantity,
    required this.isAddition,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  InventoryLogModel copyWith({
    String? id,
    String? inventoryId,
    int? quantity,
    bool? isAddition,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return InventoryLogModel(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      quantity: quantity ?? this.quantity,
      isAddition: isAddition ?? this.isAddition,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
