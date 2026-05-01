// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'harvest_batch.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HarvestBatchAdapter extends TypeAdapter<HarvestBatch> {
  @override
  final int typeId = 0;

  @override
  HarvestBatch read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HarvestBatch(
      id: fields[0] as String,
      herbName: fields[1] as String,
      farmerId: fields[2] as String,
      location: fields[3] as String,
      weight: fields[4] as double,
      harvestDate: fields[5] as DateTime,
      status: fields[6] as String,
      imagePath: fields[7] as String?,
      isSynced: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HarvestBatch obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.herbName)
      ..writeByte(2)
      ..write(obj.farmerId)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.weight)
      ..writeByte(5)
      ..write(obj.harvestDate)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarvestBatchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
