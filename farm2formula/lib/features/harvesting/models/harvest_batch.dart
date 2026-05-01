import 'package:hive/hive.dart';

part 'harvest_batch.g.dart';

@HiveType(typeId: 0)
class HarvestBatch extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String herbName;

  @HiveField(2)
  final String farmerId;

  @HiveField(3)
  final String location; // GPS Coordinates: "lat,long"

  @HiveField(4)
  final double weight;

  @HiveField(5)
  final DateTime harvestDate;

  @HiveField(6)
  final String status; // 'HARVESTED', 'SYNCED', 'FAILED'

  @HiveField(7)
  final String? imagePath;

  @HiveField(8)
  final bool isSynced;

  HarvestBatch({
    required this.id,
    required this.herbName,
    required this.farmerId,
    required this.location,
    required this.weight,
    required this.harvestDate,
    this.status = 'HARVESTED',
    this.imagePath,
    this.isSynced = false,
  });

  HarvestBatch copyWith({
    String? status,
    bool? isSynced,
  }) {
    return HarvestBatch(
      id: id,
      herbName: herbName,
      farmerId: farmerId,
      location: location,
      weight: weight,
      harvestDate: harvestDate,
      status: status ?? this.status,
      imagePath: imagePath,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
