// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consumption_group_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConsumptionGroupModelAdapter extends TypeAdapter<ConsumptionGroupModel> {
  @override
  final int typeId = 10;

  @override
  ConsumptionGroupModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConsumptionGroupModel(
      id: fields[0] as String,
      items: (fields[1] as List).cast<ConsumptionItem>(),
      date: fields[2] as DateTime,
      addedBy: fields[3] as String,
      createdAt: fields[4] as DateTime,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ConsumptionGroupModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.addedBy)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsumptionGroupModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConsumptionItemAdapter extends TypeAdapter<ConsumptionItem> {
  @override
  final int typeId = 11;

  @override
  ConsumptionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConsumptionItem(
      productId: fields[0] as String,
      productName: fields[1] as String,
      quantity: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ConsumptionItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsumptionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
