import 'package:hive/hive.dart';

part 'attendance_model.g.dart';

@HiveType(typeId: 6)
class AttendanceModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  bool isPresent;

  @HiveField(4)
  DateTime? checkInTime;

  @HiveField(5)
  DateTime? checkOutTime;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.isPresent,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    required this.createdAt,
  });

  AttendanceModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    bool? isPresent,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? notes,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      isPresent: isPresent ?? this.isPresent,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
