// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentModelAdapter extends TypeAdapter<PaymentModel> {
  @override
  final int typeId = 5;

  @override
  PaymentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      userId: fields[2] as String?,
      linkedUserName: fields[10] as String?,
      date: fields[3] as DateTime,
      type: fields[4] as PaymentType,
      mode: fields[5] as PaymentMode?,
      description: fields[6] as String?,
      notes: fields[7] as String?,
      isIncome: fields[8] as bool,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(10)
      ..write(obj.linkedUserName)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.mode)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.isIncome)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentTypeAdapter extends TypeAdapter<PaymentType> {
  @override
  final int typeId = 3;

  @override
  PaymentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentType.trial;
      case 1:
        return PaymentType.membership;
      case 2:
        return PaymentType.expense;
      default:
        return PaymentType.trial;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentType obj) {
    switch (obj) {
      case PaymentType.trial:
        writer.writeByte(0);
        break;
      case PaymentType.membership:
        writer.writeByte(1);
        break;
      case PaymentType.expense:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentModeAdapter extends TypeAdapter<PaymentMode> {
  @override
  final int typeId = 4;

  @override
  PaymentMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMode.cash;
      case 1:
        return PaymentMode.online;
      // case 2:
      //   return PaymentMode.upi;
      // case 3:
      //   return PaymentMode.netBanking;
      // case 4:
      //   return PaymentMode.other;
      default:
        return PaymentMode.cash;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentMode obj) {
    switch (obj) {
      case PaymentMode.cash:
        writer.writeByte(0);
        break;
      case PaymentMode.online:
        writer.writeByte(1);
        break;
      // case PaymentMode.upi:
      //   writer.writeByte(2);
      //   break;
      // case PaymentMode.netBanking:
      //   writer.writeByte(3);
      //   break;
      // case PaymentMode.other:
      //   writer.writeByte(4);
      //   break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
