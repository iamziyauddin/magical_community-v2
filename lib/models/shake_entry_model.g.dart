// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shake_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShakeEntryModelAdapter extends TypeAdapter<ShakeEntryModel> {
  @override
  final int typeId = 6;

  @override
  ShakeEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShakeEntryModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      memberShakes: fields[2] as int,
      trialShakes: fields[3] as int,
      addedBy: fields[4] as String,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ShakeEntryModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.memberShakes)
      ..writeByte(3)
      ..write(obj.trialShakes)
      ..writeByte(4)
      ..write(obj.addedBy)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShakeEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
