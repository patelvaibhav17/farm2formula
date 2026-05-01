import 'package:hive/hive.dart';
import '../models/harvest_batch.dart';

class HarvestRepository {
  final Box<HarvestBatch> _box;

  HarvestRepository(this._box);

  Future<void> saveBatch(HarvestBatch batch) async {
    await _box.put(batch.id, batch);
  }

  List<HarvestBatch> getAllBatches() {
    return _box.values.toList();
  }

  List<HarvestBatch> getUnsyncedBatches() {
    return _box.values.where((batch) => !batch.isSynced).toList();
  }

  Future<void> markAsSynced(String id) async {
    final batch = _box.get(id);
    if (batch != null) {
      await _box.put(id, batch.copyWith(isSynced: true, status: 'SYNCED'));
    }
  }

  Future<void> deleteBatch(String id) async {
    await _box.delete(id);
  }
}
