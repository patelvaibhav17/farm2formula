import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/harvest_provider.dart';
import '../../../core/widgets/server_settings_dialog.dart';

class HarvestingDashboard extends ConsumerWidget {
  const HarvestingDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(harvestProvider);
    final isSyncing = ref.watch(isSyncingProvider);

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
          title: GestureDetector(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) => const ServerSettingsDialog(),
              );
            },
            child: const Text('Farmer Dashboard'),
          ),
          actions: [
            if (isSyncing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () async {
                  final message = await ref.read(harvestProvider.notifier).syncNow();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                },
                tooltip: 'Sync with Blockchain',
              ),
          ],
        ),
        body: batches.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No harvest batches yet', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: batches.length,
                itemBuilder: (context, index) {
                  final batch = batches[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: batch.imagePath != null
                            ? Image.file(
                                File(batch.imagePath!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.green.shade50,
                                child: const Icon(Icons.eco, color: Colors.green),
                              ),
                      ),
                      title: Text(batch.herbName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${batch.id.substring(0, 8)}...'),
                          Text('Weight: ${batch.weight}kg'),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            batch.isSynced ? Icons.check_circle : Icons.offline_pin,
                            color: batch.isSynced ? Colors.blue : Colors.orange,
                          ),
                          Text(
                            batch.isSynced ? 'Synced' : 'Local',
                            style: TextStyle(
                              fontSize: 10,
                              color: batch.isSynced ? Colors.blue : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/harvesting/register'),
          label: const Text('New Harvest'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
