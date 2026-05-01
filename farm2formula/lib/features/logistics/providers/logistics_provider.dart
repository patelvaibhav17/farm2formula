import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/network/api_config.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

/// Fetches batches from blockchain filtered by status
final batchesByStatusProvider =
    FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, status) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/harvesting/by-status/$status');
  final response = await http.get(uri).timeout(ApiConfig.defaultTimeout);
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final List raw = body['data'] as List? ?? [];
    return raw.cast<Map<String, dynamic>>();
  }
  throw Exception('Server returned ${response.statusCode}: ${response.body}');
});

/// Currently available batches for Logistics (status = CREATED)
final availableBatchesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(batchesByStatusProvider('CREATED').future);
});

/// Batches currently being transported (PICKED / IN_TRANSIT)
final inTransitBatchesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final picked = await ref.watch(batchesByStatusProvider('PICKED').future);
  final inTransit = await ref.watch(batchesByStatusProvider('IN_TRANSIT').future);
  return [...picked, ...inTransit];
});

// ─── Mutations ───────────────────────────────────────────────────────────────

Future<String> acceptBatch(String batchId, String transporterId) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/logistics/accept'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'batchId': batchId, 'transporterId': transporterId}),
  );
  if (response.statusCode == 200) return 'Batch accepted. Status: PICKED';
  throw Exception('Accept failed: ${response.body}');
}

Future<String> updateTransportStatus(
    String batchId, String newStatus, String transporterId) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/logistics/update-status'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'batchId': batchId,
      'newStatus': newStatus,
      'transporterId': transporterId,
    }),
  );
  if (response.statusCode == 200) return 'Status updated to $newStatus';
  throw Exception('Update failed: ${response.body}');
}

// ─── Status helpers ───────────────────────────────────────────────────────────

Color statusColor(String status) {
  switch (status) {
    case 'CREATED':
      return const Color(0xFF2196F3); // blue
    case 'PICKED':
      return const Color(0xFFFF9800); // orange
    case 'IN_TRANSIT':
      return const Color(0xFF9C27B0); // purple
    case 'DELIVERED_TO_LAB':
      return const Color(0xFF4CAF50); // green
    case 'VERIFIED':
      return const Color(0xFF009688); // teal
    case 'QA_FAILED':
      return const Color(0xFFF44336); // red
    case 'MANUFACTURED':
      return const Color(0xFF3F51B5); // indigo
    default:
      return const Color(0xFF9E9E9E); // grey
  }
}
