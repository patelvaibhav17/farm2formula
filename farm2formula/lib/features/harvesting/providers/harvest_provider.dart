import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../data/harvest_repository.dart';
import '../models/harvest_batch.dart';
import '../../../core/network/sync_service.dart';

final harvestBoxProvider = Provider<Box<HarvestBatch>>((ref) {
  return Hive.box<HarvestBatch>('harvest_batches');
});

final harvestRepositoryProvider = Provider<HarvestRepository>((ref) {
  final box = ref.watch(harvestBoxProvider);
  return HarvestRepository(box);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final repository = ref.watch(harvestRepositoryProvider);
  return SyncService(repository);
});

final isSyncingProvider = StateProvider<bool>((ref) => false);

class HarvestNotifier extends StateNotifier<List<HarvestBatch>> {
  final HarvestRepository _repository;
  final SyncService _syncService;
  final StateController<bool> _isSyncingController;

  HarvestNotifier(this._repository, this._syncService, this._isSyncingController) : super([]) {
    loadBatches();
  }

  void loadBatches() {
    state = _repository.getAllBatches();
  }

  Future<void> addBatch(HarvestBatch batch) async {
    await _repository.saveBatch(batch);
    loadBatches();
    // Try syncing immediately
    syncNow();
  }

  Future<String> syncNow() async {
    _isSyncingController.state = true;
    final result = await _syncService.syncAll();
    loadBatches();
    _isSyncingController.state = false;
    return result;
  }
}

final harvestProvider = StateNotifierProvider<HarvestNotifier, List<HarvestBatch>>((ref) {
  final repository = ref.watch(harvestRepositoryProvider);
  final syncService = ref.watch(syncServiceProvider);
  final isSyncingController = ref.watch(isSyncingProvider.notifier);
  return HarvestNotifier(repository, syncService, isSyncingController);
});
