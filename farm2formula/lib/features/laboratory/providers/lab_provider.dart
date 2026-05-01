import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/network/api_config.dart';

/// Fetches batches with status DELIVERED_TO_LAB (pending QA testing)
final pendingLabBatchesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/harvesting/by-status/DELIVERED_TO_LAB');
  final response = await http.get(uri).timeout(ApiConfig.defaultTimeout);
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final List raw = body['data'] as List? ?? [];
    return raw.cast<Map<String, dynamic>>();
  }
  throw Exception('Server returned ${response.statusCode}');
});

/// Fetches VERIFIED batches (completed QA, ready for manufacturing)
final verifiedBatchesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final uri =
      Uri.parse('${ApiConfig.baseUrl}/harvesting/by-status/VERIFIED');
  final response = await http.get(uri).timeout(ApiConfig.defaultTimeout);
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final List raw = body['data'] as List? ?? [];
    return raw.cast<Map<String, dynamic>>();
  }
  throw Exception('Server returned ${response.statusCode}');
});
