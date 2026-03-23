// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 2;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      name: fields[1] as String,
      mobileNumber: fields[2] as String,
      address: fields[3] as String,
      referredBy: fields[4] as ReferralSource,
      visitDate: fields[5] as DateTime,
      userType: fields[6] as UserType,
      trialStartDate: fields[7] as DateTime?,
      trialEndDate: fields[8] as DateTime?,
      membershipStartDate: fields[9] as DateTime?,
      membershipEndDate: fields[10] as DateTime?,
      totalPaid: fields[11] as double,
      pendingDues: fields[12] as double,
      isActive: fields[13] as bool,
      notes: fields[14] as String?,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
      role: fields[17] as UserRole,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.mobileNumber)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.referredBy)
      ..writeByte(5)
      ..write(obj.visitDate)
      ..writeByte(6)
      ..write(obj.userType)
      ..writeByte(7)
      ..write(obj.trialStartDate)
      ..writeByte(8)
      ..write(obj.trialEndDate)
      ..writeByte(9)
      ..write(obj.membershipStartDate)
      ..writeByte(10)
      ..write(obj.membershipEndDate)
      ..writeByte(11)
      ..write(obj.totalPaid)
      ..writeByte(12)
      ..write(obj.pendingDues)
      ..writeByte(13)
      ..write(obj.isActive)
      ..writeByte(14)
      ..write(obj.notes)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.role);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserTypeAdapter extends TypeAdapter<UserType> {
  @override
  final int typeId = 0;

  @override
  UserType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserType.visitor;
      case 1:
        return UserType.trial;
      case 2:
        return UserType.member;
      default:
        return UserType.visitor;
    }
  }

  @override
  void write(BinaryWriter writer, UserType obj) {
    switch (obj) {
      case UserType.visitor:
        writer.writeByte(0);
        break;
      case UserType.trial:
        writer.writeByte(1);
        break;
      case UserType.member:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReferralSourceAdapter extends TypeAdapter<ReferralSource> {
  @override
  final int typeId = 1;

  @override
  ReferralSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReferralSource.friend;
      case 1:
        return ReferralSource.family;
      case 2:
        return ReferralSource.google;
      case 3:
        return ReferralSource.other;
      default:
        return ReferralSource.friend;
    }
  }

  @override
  void write(BinaryWriter writer, ReferralSource obj) {
    switch (obj) {
      case ReferralSource.friend:
        writer.writeByte(0);
        break;
      case ReferralSource.family:
        writer.writeByte(1);
        break;
      case ReferralSource.google:
        writer.writeByte(2);
        break;
      case ReferralSource.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferralSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 3;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.member;
      case 1:
        return UserRole.coach;
      case 2:
        return UserRole.seniorCoach;
      default:
        return UserRole.member;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.member:
        writer.writeByte(0);
        break;
      case UserRole.coach:
        writer.writeByte(1);
        break;
      case UserRole.seniorCoach:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
