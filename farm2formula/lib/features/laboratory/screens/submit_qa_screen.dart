import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import '../../../core/network/api_config.dart';
import '../providers/lab_provider.dart';

class SubmitQAScreen extends ConsumerStatefulWidget {
  final String batchId;
  const SubmitQAScreen({super.key, required this.batchId});

  @override
  ConsumerState<SubmitQAScreen> createState() => _SubmitQAScreenState();
}

class _SubmitQAScreenState extends ConsumerState<SubmitQAScreen> {
  final _formKey = GlobalKey<FormState>();
  // Heavy metals (PPM)
  final _leadController     = TextEditingController(text: '2.5');
  final _arsenicController  = TextEditingController(text: '0.8');
  final _mercuryController  = TextEditingController(text: '0.05');
  final _cadmiumController  = TextEditingController(text: '0.1');
  final _pesticideController = TextEditingController(text: 'Negative');

  File? _selectedCertificate;
  bool _isUploading = false;
  String? _uploadedCid;

  // AYUSH Limits for live validation hints
  static const _limits = {
    'lead': 10.0, 'arsenic': 3.0, 'mercury': 1.0, 'cadmium': 0.3,
  };

  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (result != null) {
      setState(() => _selectedCertificate = File(result.files.single.path!));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      // 1. Upload Certificate to IPFS via API
      if (_selectedCertificate != null) {
        var request = http.MultipartRequest(
          'POST', Uri.parse('${ApiConfig.baseUrl}/laboratory/upload'));
        request.files.add(await http.MultipartFile.fromPath(
          'certificate',
          _selectedCertificate!.path,
          contentType: MediaType('application', 'pdf'),
        ));
        final uploadRes = await request.send();
        final uploadData = await http.Response.fromStream(uploadRes);
        _uploadedCid = jsonDecode(uploadData.body)['cid'];
      }

      // 2. Submit QA Results to Fabric
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/laboratory/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'batchId': widget.batchId,
          'testerId': 'LAB_USER_01',
          'results': {
            'lead':    double.tryParse(_leadController.text) ?? 0,
            'arsenic': double.tryParse(_arsenicController.text) ?? 0,
            'mercury': double.tryParse(_mercuryController.text) ?? 0,
            'cadmium': double.tryParse(_cadmiumController.text) ?? 0,
            'pesticides': _pesticideController.text,
          },
          'certificateCID': _uploadedCid ?? 'N/A',
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // ✅ Invalidate lab provider so dashboard refreshes
        ref.invalidate(pendingLabBatchesProvider);
        ref.invalidate(verifiedBatchesProvider);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ QA Data Committed to Blockchain Ledger'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
        
        // Small delay to ensure Blockchain consensus is visible to refresh
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context);
      } else {
        throw 'Server error: ${response.statusCode} – ${response.body}';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Color _limitColor(String key, String text) {
    final val = double.tryParse(text) ?? 0;
    final limit = _limits[key] ?? 999;
    return val > limit ? Colors.red : Colors.green;
  }

  Widget _buildHeavyMetalField(String key, String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: 'ppm',
          helperText: 'AYUSH limit: ${_limits[key]} ppm',
          helperStyle: TextStyle(color: _limitColor(key, ctrl.text)),
          suffixIcon: Icon(
            double.tryParse(ctrl.text) != null && (double.tryParse(ctrl.text) ?? 999) <= (_limits[key] ?? 999)
                ? Icons.check_circle
                : Icons.warning_amber,
            color: _limitColor(key, ctrl.text),
            size: 20,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QA Test: ${widget.batchId.length > 12 ? widget.batchId.substring(0, 12) : widget.batchId}...')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.biotech, color: Colors.purple, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AYUSH Compliance Testing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Batch: ${widget.batchId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Heavy Metals ──
            const Text('Heavy Metals Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('AYUSH / WHO permissible limits', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            _buildHeavyMetalField('lead',    '🔩 Lead (Pb)',     _leadController),
            _buildHeavyMetalField('arsenic', '⚗️ Arsenic (As)',  _arsenicController),
            _buildHeavyMetalField('mercury', '🌡️ Mercury (Hg)',  _mercuryController),
            _buildHeavyMetalField('cadmium', '🧪 Cadmium (Cd)',  _cadmiumController),

            const SizedBox(height: 8),
            TextFormField(
              controller: _pesticideController,
              decoration: const InputDecoration(
                labelText: '🌿 Pesticide Screening Result',
                helperText: 'Enter Negative or Positive',
              ),
            ),
            const SizedBox(height: 32),

            // ── Certificate Upload ──
            const Text('Certificate of Analysis (CoA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickCertificate,
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedCertificate != null ? Colors.green : Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedCertificate != null ? Colors.green.shade50 : Colors.grey.shade50,
                ),
                child: Center(
                  child: _selectedCertificate == null
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.upload_file, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('Upload Signed PDF / Image', style: TextStyle(color: Colors.grey)),
                        ])
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedCertificate!.path.split('/').last,
                              style: const TextStyle(color: Colors.green),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                ),
              ),
            ),
            const SizedBox(height: 48),

            ElevatedButton.icon(
              onPressed: _isUploading ? null : _submit,
              icon: _isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.verified_outlined),
              label: Text(_isUploading ? 'Committing to Blockchain...' : 'Submit & Commit to Ledger'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
