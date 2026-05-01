import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/network/api_config.dart';

final timelineProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/harvesting/batch/$id'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load trace. Are you sure this lot exists?');
  }
});

class ConsumerTimelineScreen extends ConsumerWidget {
  final String lotId;
  const ConsumerTimelineScreen({super.key, required this.lotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traceAsync = ref.watch(timelineProvider(lotId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Trace Analysis: #$lotId')),
      body: traceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(err.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (json) {
          final dataList = json['data'] as List?;
          if (dataList == null || dataList.isEmpty) {
            return const Center(child: Text('No trace record found on the blockchain.'));
          }

          // The last element in the history array contains the latest state
          final latestState = dataList.last['value'];
          final timeline = latestState['timeline'] as List? ?? [];
          final productDesc = latestState['productType'] ?? latestState['herbName'] ?? 'Unknown Botanical';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('✅ Blockchain Verification Successful', 
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)
              ),
              const SizedBox(height: 8),
              Text('Asset: $productDesc', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('Owner: ${latestState['owner']}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              
              ...timeline.asMap().entries.map((entry) {
                final idx = entry.key;
                final event = entry.value;
                final isLast = idx == timeline.length - 1;

                IconData icon;
                final status = event['status'] ?? '';
                if (status == 'HARVESTED' || status == 'INITIALIZED') icon = Icons.eco;
                else if (status == 'TESTED') icon = Icons.biotech;
                else if (status == 'MANUFACTURED') icon = Icons.precision_manufacturing;
                else icon = Icons.local_shipping;

                // Format timestamp
                String timeStr = event['timestamp'] ?? '';
                try {
                  final dt = DateTime.parse(timeStr);
                  timeStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                } catch (_) {}

                return _buildTimelineItem(
                  '$status',
                  '$timeStr | by ${event['user']}',
                  event['details'] ?? 'State updated on Ledger',
                  icon,
                  !isLast,
                );
              }).toList(),

              if (latestState['certificateCID'] != null && latestState['certificateCID'] != 'N/A')
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.description),
                    label: Text('IPFS CoA: ${latestState['certificateCID']}'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, String details, IconData icon, bool hasConnector) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(backgroundColor: Colors.indigo.shade100, child: Icon(icon, size: 20, color: Colors.indigo)),
                if (hasConnector) Container(width: 2, height: 80, color: Colors.indigo.shade100),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(details, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
