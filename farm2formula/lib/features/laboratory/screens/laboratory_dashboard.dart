import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/lab_provider.dart';
import '../../../core/utils/sync_provider.dart';
import '../../../core/network/api_config.dart';

class LaboratoryDashboard extends ConsumerWidget {
  const LaboratoryDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Proactive Synchronization Protocol: Poll blockchain every 10s
    ref.listen(syncProvider, (_, __) {
      ref.invalidate(pendingLabBatchesProvider);
      ref.invalidate(verifiedBatchesProvider);
    });

    final pendingAsync = ref.watch(pendingLabBatchesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go('/role_selection');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.maybePop(context)),
          title: const Text('QA Laboratory'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(pendingLabBatchesProvider),
            ),
          ],
        ),
        body: pendingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _buildError(context, ref, ApiConfig.formatError(err)),
          data: (batches) => _buildBody(context, ref, batches),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> batches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildLabStat(context, 'Pending QA', batches.length.toString(), Colors.orange, Icons.science)),
              const SizedBox(width: 12),
              Expanded(child: _buildLabStat(context, 'Live Data', '✓', Colors.green, Icons.verified)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Batches Awaiting QA Testing',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: batches.isEmpty
              ? _buildEmpty(context, ref)
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(pendingLabBatchesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: batches.length,
                    itemBuilder: (context, index) {
                      final batch = batches[index];
                      final batchId = batch['batchId'] ?? batch['id'] ?? 'Unknown';
                      final herbName = batch['herbName'] ?? 'Unknown Herb';
                      final location = batch['location'] ?? 'N/A';
                      final farmerId = batch['farmerId'] ?? 'N/A';
                      final harvestDate = batch['harvestDate'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showBatchDetails(context, batchId, herbName, location, farmerId, harvestDate),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.purple.shade50,
                                  child: const Icon(Icons.biotech, color: Colors.purple),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(herbName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text('ID: ${batchId.length > 14 ? batchId.substring(0, 14) : batchId}...', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      Text('From: $farmerId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: const Text('PENDING', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLabStat(BuildContext context, String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text('No batches pending QA', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 8),
          Text('All batches are tested or none have arrived yet.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(pendingLabBatchesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Could not load lab queue', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(pendingLabBatchesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchDetails(BuildContext context, String batchId, String herbName, String location, String farmerId, String harvestDate) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QA Testing Required', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.eco, color: Colors.green),
                title: Text(herbName),
                subtitle: Text('Batch: $batchId'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: Text(location),
                subtitle: const Text('Collection origin'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.science, color: Colors.purple),
                title: const Text('Required Tests'),
                subtitle: const Text('• Heavy Metals (Pb, As, Hg, Cd)\n• Pesticide Residues\n• Microbial Count\n• Mycotoxins'),
                isThreeLine: true,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    GoRouter.of(context).push('/laboratory/submit/$batchId');
                  },
                  icon: const Icon(Icons.biotech),
                  label: const Text('Start QA Testing'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
