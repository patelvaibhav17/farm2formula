import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/logistics_provider.dart';
import '../../../core/utils/sync_provider.dart';
import '../../../core/network/api_config.dart';
import 'batch_qr_dialog.dart';

class LogisticsDashboard extends ConsumerWidget {
  const LogisticsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Proactive Synchronization Protocol: Poll blockchain every 10s
    ref.listen(syncProvider, (_, __) {
      ref.invalidate(availableBatchesProvider);
      ref.invalidate(inTransitBatchesProvider);
    });

    final availableAsync = ref.watch(availableBatchesProvider);

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
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => Navigator.maybePop(context)),
            title: const Text('Logistics Hub'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () {
                  ref.invalidate(availableBatchesProvider);
                  ref.invalidate(inTransitBatchesProvider);
                },
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.inbox), text: 'Available'),
                Tab(icon: Icon(Icons.local_shipping), text: 'In Transit'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _BatchList(asyncValue: availableAsync, emptyMsg: 'No batches ready for pickup', ref: ref, isAvailable: true),
              Consumer(builder: (context, ref, _) {
                final inTransitAsync = ref.watch(inTransitBatchesProvider);
                return _BatchList(asyncValue: inTransitAsync, emptyMsg: 'No batches currently in transit', ref: ref, isAvailable: false);
              }),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/logistics/scan'),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Batch'),
          ),
        ),
      ),
    );
  }
}

class _BatchList extends ConsumerWidget {
  final AsyncValue<List<Map<String, dynamic>>> asyncValue;
  final String emptyMsg;
  final WidgetRef ref;
  final bool isAvailable;

  const _BatchList({
    required this.asyncValue,
    required this.emptyMsg,
    required this.ref,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: ApiConfig.formatError(e), onRetry: () {
        ref.invalidate(availableBatchesProvider);
        ref.invalidate(inTransitBatchesProvider);
      }),
      data: (batches) {
        if (batches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(emptyMsg, style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(availableBatchesProvider);
                    ref.invalidate(inTransitBatchesProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(availableBatchesProvider);
            ref.invalidate(inTransitBatchesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              final batchId = batch['batchId'] ?? batch['id'] ?? 'Unknown';
              final herbName = batch['herbName'] ?? 'Unknown Herb';
              final status = batch['status'] ?? 'CREATED';
              final location = batch['location'] ?? 'N/A';
              final color = statusColor(status);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(Icons.eco, color: color),
                  ),
                  title: Text(herbName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${batchId.length > 12 ? batchId.substring(0, 12) : batchId}...'),
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.4)),
                            ),
                            child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showBatchActions(context, ref, batch, batchId, herbName, status, location),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showBatchActions(BuildContext context, WidgetRef ref, Map<String, dynamic> batch,
      String batchId, String herbName, String status, String location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _BatchActionsSheet(
        batchId: batchId,
        herbName: herbName,
        status: status,
        location: location,
        batch: batch,
        onActionDone: () {
          ref.invalidate(availableBatchesProvider);
          ref.invalidate(inTransitBatchesProvider);
        },
      ),
    );
  }
}

class _BatchActionsSheet extends StatefulWidget {
  final String batchId;
  final String herbName;
  final String status;
  final String location;
  final Map<String, dynamic> batch;
  final VoidCallback onActionDone;

  const _BatchActionsSheet({
    required this.batchId,
    required this.herbName,
    required this.status,
    required this.location,
    required this.batch,
    required this.onActionDone,
  });

  @override
  State<_BatchActionsSheet> createState() => _BatchActionsSheetState();
}

class _BatchActionsSheetState extends State<_BatchActionsSheet> {
  bool _isLoading = false;

  Future<void> _doAction(BuildContext context, Future<String> Function() action) async {
    setState(() => _isLoading = true);
    try {
      final msg = await action();
      
      // Wait for blockchain consensus to settle before refreshing UI
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (!mounted) return;
      Navigator.pop(context);
      widget.onActionDone();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg), 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${ApiConfig.formatError(e)}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor_ = statusColor(widget.status);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Batch Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor_.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor_.withOpacity(0.4)),
                ),
                child: Text(widget.status, style: TextStyle(color: statusColor_, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 24),
          _infoRow(Icons.eco, 'Herb', widget.herbName),
          _infoRow(Icons.qr_code, 'Batch ID', widget.batchId.length > 20 ? widget.batchId.substring(0, 20) + '...' : widget.batchId),
          _infoRow(Icons.location_on, 'Origin', widget.location),
          _infoRow(Icons.person, 'Farmer', widget.batch['farmerId'] ?? widget.batch['FarmerId'] ?? 'N/A'),
          _infoRow(Icons.monitor_weight, 'Weight', '${widget.batch['weight'] ?? widget.batch['Weight'] ?? 'N/A'} kg'),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.status == 'CREATED')
                  ElevatedButton.icon(
                    onPressed: () => _doAction(context, () => acceptBatch(widget.batchId, 'TRANSPORTER_1')),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Accept & Pick Up'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                if (widget.status == 'PICKED') ...[
                  ElevatedButton.icon(
                    onPressed: () => _doAction(context, () => updateTransportStatus(widget.batchId, 'IN_TRANSIT', 'TRANSPORTER_1')),
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Mark In Transit'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                ],
                if (widget.status == 'IN_TRANSIT') ...[
                  ElevatedButton.icon(
                    onPressed: () => _doAction(context, () => updateTransportStatus(widget.batchId, 'DELIVERED_TO_LAB', 'TRANSPORTER_1')),
                    icon: const Icon(Icons.science),
                    label: const Text('Deliver to Lab'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => BatchQrDialog(batchId: widget.batchId),
                    );
                  },
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Show QR Code'),
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load batches', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'CREATED': return const Color(0xFF2196F3);
    case 'PICKED': return const Color(0xFFFF9800);
    case 'IN_TRANSIT': return const Color(0xFF9C27B0);
    case 'DELIVERED_TO_LAB': return const Color(0xFF4CAF50);
    case 'VERIFIED': return const Color(0xFF009688);
    case 'QA_FAILED': return const Color(0xFFF44336);
    case 'MANUFACTURED': return const Color(0xFF3F51B5);
    default: return const Color(0xFF9E9E9E);
  }
}
