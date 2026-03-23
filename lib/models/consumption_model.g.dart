// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consumption_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConsumptionModelAdapter extends TypeAdapter<ConsumptionModel> {
  @override
  final int typeId = 9;

  @override
  ConsumptionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConsumptionModel(
      id: fields[0] as String,
      productId: fields[1] as String,
      productName: fields[2] as String,
      quantity: fields[3] as int,
      date: fields[4] as DateTime,
      addedBy: fields[5] as String,
      createdAt: fields[6] as DateTime,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ConsumptionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.addedBy)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsumptionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
