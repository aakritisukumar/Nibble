// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodEntryAdapter extends TypeAdapter<FoodEntry> {
  @override
  final int typeId = 0;

  @override
  FoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodEntry(
      id: fields[0] as String,
      foodName: fields[1] as String,
      calories: fields[2] as int,
      timestamp: fields[3] as DateTime,
      rawInput: fields[4] as String,
      carbs: (fields[5] as int?) ?? 0,
      protein: (fields[6] as int?) ?? 0,
      fat: (fields[7] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, FoodEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.foodName)
      ..writeByte(2)
      ..write(obj.calories)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.rawInput)
      ..writeByte(5)
      ..write(obj.carbs)
      ..writeByte(6)
      ..write(obj.protein)
      ..writeByte(7)
      ..write(obj.fat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
