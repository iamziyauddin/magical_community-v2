import 'package:hive/hive.dart';

part 'consumption_group_model.g.dart';

@HiveType(typeId: 10)
class ConsumptionGroupModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  List<ConsumptionItem> items;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String addedBy;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? notes;

  ConsumptionGroupModel({
    required this.id,
    required this.items,
    required this.date,
    required this.addedBy,
    required this.createdAt,
    this.notes,
  });

  // Get total number of products in this consumption
  int get totalProducts => items.length;

  // Get total quantity consumed
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  ConsumptionGroupModel copyWith({
    String? id,
    List<ConsumptionItem>? items,
    DateTime? date,
    String? addedBy,
    DateTime? createdAt,
    String? notes,
  }) {
    return ConsumptionGroupModel(
      id: id ?? this.id,
      items: items ?? this.items,
      date: date ?? this.date,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

@HiveType(typeId: 11)
class ConsumptionItem extends HiveObject {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String productName;

  @HiveField(2)
  int quantity;

  ConsumptionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  ConsumptionItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
  }) {
    return ConsumptionItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
    );
  }
}
