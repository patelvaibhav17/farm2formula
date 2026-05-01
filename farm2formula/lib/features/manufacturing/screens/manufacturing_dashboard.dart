import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/network/api_config.dart';
import '../../../core/utils/sync_provider.dart';

final lotsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/manufacturing'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data'] as List<dynamic>;
  } else {
    throw Exception('Failed to load lots');
  }
});

class ManufacturingDashboard extends ConsumerWidget {
  const ManufacturingDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Proactive Synchronization Protocol: Poll blockchain every 10s
    ref.listen(syncProvider, (_, __) {
      ref.invalidate(lotsProvider);
    });

    final lotsAsyncValue = ref.watch(lotsProvider);

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
          title: const Text('Processing & Manufacturing'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionCard(
                context,
                title: 'Create Finished Lot',
                subtitle: 'Combine raw batches into a product lot',
                icon: Icons.precision_manufacturing,
                onTap: () async {
                  await context.push('/manufacturing/create-lot');
                  ref.invalidate(lotsProvider); // Refresh list on return
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Productions', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.invalidate(lotsProvider),
                  )
                ]
              ),
              const SizedBox(height: 12),
              Expanded(
                child: lotsAsyncValue.when(
                  data: (lots) {
                    if (lots.isEmpty) {
                      return const Center(child: Text('No product lots minted yet.'));
                    }
                    return ListView.builder(
                      itemCount: lots.length,
                      itemBuilder: (context, index) {
                        final lot = lots[index];
                        final lotId = lot['lotId'] ?? lot['id'] ?? 'Unknown';
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.inventory),
                            title: Text('Lot #$lotId'),
                            subtitle: Text('Type: ${lot['productType']}\nQty: ${lot['quantity']}'),
                            isThreeLine: true,
                            trailing: const Text('Verified', style: TextStyle(color: Colors.green)),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.indigo.shade600, Colors.indigo.shade400]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
