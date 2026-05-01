import 'dart:convert';
import 'dart:io' as java_io;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/harvesting/data/harvest_repository.dart';
import '../../features/harvesting/models/harvest_batch.dart';
import 'api_config.dart';

class SyncResult {
  final bool success;
  final String message;
  SyncResult(this.success, this.message);
}

class SyncService {
  final HarvestRepository _repository;

  bool _isSyncing = false;

  SyncService(this._repository);

  Future<String> syncAll() async {
    if (_isSyncing) {
      return 'Sync in progress...';
    }

    _isSyncing = true;
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return 'No internet connection.';
      }

      final unsynced = _repository.getUnsyncedBatches();
      if (unsynced.isEmpty) return 'Everything is up to date.';
      
      int successCount = 0;
      int failCount = 0;

      for (var batch in unsynced) {
        try {
          final result = await _syncBatch(batch);
          if (result.success) {
            await _repository.markAsSynced(batch.id);
            successCount++;
          } else {
            print('Sync failed for batch ${batch.id}: ${result.message}');
            failCount++;
          }
        } catch (e) {
          print('Exception during batch ${batch.id} sync: $e');
          failCount++;
        }
      }
      
      if (failCount > 0) {
         return 'Synced $successCount batches, $failCount failed.';
      }
      return 'Successfully synced $successCount batches.';
    } catch(e) {
       return 'Sync error: ${ApiConfig.formatError(e)}';
    } finally {
      _isSyncing = false;
    }
  }

  Future<SyncResult> _syncBatch(HarvestBatch batch) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/harvesting/register');
    
    // Using simple approach vs Multipart request based on whether there's an image
    bool hasImage = batch.imagePath != null && batch.imagePath!.isNotEmpty;
    if (hasImage && !kIsWeb) {
      hasImage = await java_io.File(batch.imagePath!).exists();
    }

    try {
      if (hasImage) {
        final request = http.MultipartRequest('POST', uri);
        request.headers['Bypass-Tunnel-Reminder'] = 'true';
        
        request.fields['batchId'] = batch.id;
        request.fields['herbName'] = batch.herbName;
        request.fields['farmerId'] = batch.farmerId;
        request.fields['location'] = batch.location;
        request.fields['weight'] = batch.weight.toString();
        request.fields['harvestDate'] = batch.harvestDate.toIso8601String();
        request.fields['metadata'] = jsonEncode({
          'originalImagePath': batch.imagePath,
        });

        if (!kIsWeb) {
          request.files.add(await http.MultipartFile.fromPath('image', batch.imagePath!));
        }

        final streamedResponse = await request.send().timeout(ApiConfig.longTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return SyncResult(true, 'Success');
        } else {
          final body = jsonDecode(response.body);
          return SyncResult(false, 'Server Error (${response.statusCode}): ${body['message'] ?? response.body}');
        }
      } else {
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Bypass-Tunnel-Reminder': 'true',
          },
          body: jsonEncode({
            'batchId': batch.id,
            'herbName': batch.herbName,
            'farmerId': batch.farmerId,
            'location': batch.location,
            'weight': batch.weight,
            'harvestDate': batch.harvestDate.toIso8601String(),
            'metadata': jsonEncode({}),
          }),
        ).timeout(ApiConfig.longTimeout);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return SyncResult(true, 'Success');
        } else {
          final body = jsonDecode(response.body);
          return SyncResult(false, 'Server Error (${response.statusCode}): ${body['message'] ?? response.body}');
        }
      }
    } catch (e) {
      return SyncResult(false, 'Network Error: ${ApiConfig.formatError(e)}');
    }
  }
}
