import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/network/api_config.dart';
import 'auth_provider.dart';

class UserStats {
  final int transactions;
  final String trustScore;
  final int badges;

  UserStats({
    required this.transactions,
    required this.trustScore,
    required this.badges,
  });
}

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null || user.email == null) {
    return UserStats(transactions: 0, trustScore: 'N/A', badges: 0);
  }

  // To simulate identity, we use email prefix or a known ID string
  final userId = user.email!.split('@')[0].toLowerCase();
  
  try {
    final uri = Uri.parse('${ApiConfig.baseUrl}/harvesting/all');
    final response = await http.get(uri).timeout(ApiConfig.defaultTimeout);
    
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List rawBatches = body['data'] as List? ?? [];
      
      int userTxCount = 0;
      int passCount = 0;
      int failCount = 0;

      for (var batch in rawBatches) {
        bool involved = false;
        
        // Check if user is the owner or farmer
        if ((batch['owner'] ?? '').toString().toLowerCase().contains(userId) ||
            (batch['farmerId'] ?? '').toString().toLowerCase().contains(userId)) {
          involved = true;
        }

        // Check timeline events
        final timeline = batch['timeline'] as List? ?? [];
        for (var event in timeline) {
          if ((event['user'] ?? '').toString().toLowerCase().contains(userId)) {
            involved = true;
          }
        }

        if (involved) {
          userTxCount++;
          // Basic trust score logic based on QA status of batches they are involved in
          if (batch['qaStatus'] == 'PASSED' || batch['status'] == 'VERIFIED') passCount++;
          if (batch['qaStatus'] == 'FAILED' || batch['status'] == 'QA_FAILED') failCount++;
        }
      }

      // Calculate Trust Score
      String trust = '100%';
      if (passCount > 0 || failCount > 0) {
        final total = passCount + failCount;
        final percentage = (passCount / total) * 100;
        trust = '${percentage.toStringAsFixed(0)}%';
      } else if (userTxCount > 0) {
        trust = '95%'; // Base trust for active users without QA yet
      } else {
        trust = 'New';
      }

      // Calculate Badges (1 badge per 5 tx, +1 for flawless trust)
      int badges = (userTxCount / 3).floor();
      if (trust == '100%') badges += 1;
      if (badges > 10) badges = 10; // Cap
      if (userTxCount == 0) badges = 0;

      return UserStats(transactions: userTxCount, trustScore: trust, badges: badges);
    }
  } catch (e) {
    print('Failed to fetch user stats: $e');
  }

  // Fallback if offline or error
  return UserStats(transactions: 0, trustScore: 'Offline', badges: 0);
});
