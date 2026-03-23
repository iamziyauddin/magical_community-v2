import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 9)
class AppSettings extends HiveObject {
  @HiveField(0)
  double trialFee;

  @HiveField(1)
  double membershipFee;

  @HiveField(2)
  int membershipDurationDays;

  @HiveField(3)
  String clubName;

  @HiveField(4)
  String adminName;

  @HiveField(5)
  String adminPhone;

  @HiveField(6)
  String clubAddress;

  @HiveField(7)
  bool enableNotifications;

  @HiveField(8)
  DateTime lastUpdated;

  AppSettings({
    this.trialFee = 700.0,
    this.membershipFee = 7500.0,
    this.membershipDurationDays = 30,
    this.clubName = 'Magical Community',
    this.adminName = 'Admin',
    this.adminPhone = '',
    this.clubAddress = '',
    this.enableNotifications = true,
    required this.lastUpdated,
  });

  AppSettings copyWith({
    double? trialFee,
    double? membershipFee,
    int? membershipDurationDays,
    String? clubName,
    String? adminName,
    String? adminPhone,
    String? clubAddress,
    bool? enableNotifications,
    DateTime? lastUpdated,
  }) {
    return AppSettings(
      trialFee: trialFee ?? this.trialFee,
      membershipFee: membershipFee ?? this.membershipFee,
      membershipDurationDays:
          membershipDurationDays ?? this.membershipDurationDays,
      clubName: clubName ?? this.clubName,
      adminName: adminName ?? this.adminName,
      adminPhone: adminPhone ?? this.adminPhone,
      clubAddress: clubAddress ?? this.clubAddress,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
