import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../../core/network/api_config.dart';
import '../../laboratory/providers/lab_provider.dart';

class CreateLotScreen extends ConsumerStatefulWidget {
  const CreateLotScreen({super.key});

  @override
  ConsumerState<CreateLotScreen> createState() => _CreateLotScreenState();
}

class _CreateLotScreenState extends ConsumerState<CreateLotScreen> {
  final _formKey = GlobalKey<FormState>();
  late final String _lotId = 'LOT-${const Uuid().v4().substring(0, 8).toUpperCase()}';
  final _productTypeController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');

  final Set<String> _selectedBatchIds = {};
  bool _isSubmitting = false;

  Future<void> _submitLot(List<Map<String, dynamic>> verifiedBatches) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBatchIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select at least one verified batch'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/manufacturing/create-lot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lotId': _lotId,
          'parentBatchIds': _selectedBatchIds.toList(),
          'productType': _productTypeController.text,
          'manufacturerId': 'MFR_USER_01',
          'quantity': int.parse(_quantityController.text),
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh verified batches and lots providers
        ref.invalidate(verifiedBatchesProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Product Lot minted on Blockchain!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
        
        // Consensus delay to ensure blockchain ledger is settled before refresh
        await Future.delayed(const Duration(milliseconds: 1000));
        
        if (mounted) Navigator.pop(context);
      } else {
        throw 'Server error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifiedAsync = ref.watch(verifiedBatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Finished Lot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(verifiedBatchesProvider),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Auto-generated Lot ID
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Auto-Generated Lot ID', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(_lotId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _productTypeController,
              decoration: const InputDecoration(
                labelText: 'Product Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                hintText: 'e.g. Ashwagandha Extract Tablets',
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Total Quantity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                suffixText: 'units',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // ── Verified Batch Picker ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Verified Batches', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (_selectedBatchIds.isNotEmpty)
                  Text('${_selectedBatchIds.length} selected',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),

            verifiedAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    const Text('Could not load verified batches', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(e.toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(verifiedBatchesProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (batches) {
                if (batches.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.hourglass_empty, color: Colors.orange, size: 40),
                        SizedBox(height: 8),
                        Text('No verified batches available', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Batches must pass QA testing before manufacturing.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }
                return Column(
                  children: batches.map((batch) {
                    final batchId = batch['batchId'] ?? batch['id'] ?? 'Unknown';
                    final herbName = batch['herbName'] ?? 'Unknown';
                    final isSelected = _selectedBatchIds.contains(batchId);
                    return Card(
                      elevation: isSelected ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedBatchIds.add(batchId);
                            } else {
                              _selectedBatchIds.remove(batchId);
                            }
                          });
                        },
                        title: Text(herbName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${batchId.length > 16 ? batchId.substring(0, 16) : batchId}...'),
                        secondary: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: const Icon(Icons.verified, color: Colors.teal, size: 20),
                        ),
                        activeColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => verifiedAsync.whenData((batches) => _submitLot(batches)),
              icon: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.precision_manufacturing),
              label: Text(_isSubmitting ? 'Committing to Blockchain...' : 'Mint Product Lot'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
