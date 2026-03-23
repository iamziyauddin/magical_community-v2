// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 9;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      trialFee: fields[0] as double,
      membershipFee: fields[1] as double,
      membershipDurationDays: fields[2] as int,
      clubName: fields[3] as String,
      adminName: fields[4] as String,
      adminPhone: fields[5] as String,
      clubAddress: fields[6] as String,
      enableNotifications: fields[7] as bool,
      lastUpdated: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.trialFee)
      ..writeByte(1)
      ..write(obj.membershipFee)
      ..writeByte(2)
      ..write(obj.membershipDurationDays)
      ..writeByte(3)
      ..write(obj.clubName)
      ..writeByte(4)
      ..write(obj.adminName)
      ..writeByte(5)
      ..write(obj.adminPhone)
      ..writeByte(6)
      ..write(obj.clubAddress)
      ..writeByte(7)
      ..write(obj.enableNotifications)
      ..writeByte(8)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
