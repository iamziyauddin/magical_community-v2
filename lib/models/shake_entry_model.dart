import 'package:hive/hive.dart';

part 'shake_entry_model.g.dart';

@HiveType(typeId: 6)
class ShakeEntryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int memberShakes;

  @HiveField(3)
  final int trialShakes;

  @HiveField(4)
  final String addedBy;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  ShakeEntryModel({
    required this.id,
    required this.date,
    required this.memberShakes,
    required this.trialShakes,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  ShakeEntryModel copyWith({
    String? id,
    DateTime? date,
    int? memberShakes,
    int? trialShakes,
    String? addedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShakeEntryModel(
      id: id ?? this.id,
      date: date ?? this.date,
      memberShakes: memberShakes ?? this.memberShakes,
      trialShakes: trialShakes ?? this.trialShakes,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get totalShakes => memberShakes + trialShakes;

  @override
  String toString() {
    return 'ShakeEntryModel(id: $id, date: $date, memberShakes: $memberShakes, trialShakes: $trialShakes, addedBy: $addedBy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ShakeEntryModel &&
        other.id == id &&
        other.date == date &&
        other.memberShakes == memberShakes &&
        other.trialShakes == trialShakes &&
        other.addedBy == addedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        memberShakes.hashCode ^
        trialShakes.hashCode ^
        addedBy.hashCode;
  }
}
