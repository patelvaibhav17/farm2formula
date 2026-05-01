import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/logistics_provider.dart';

class ScanBatchScreen extends ConsumerStatefulWidget {
  const ScanBatchScreen({super.key});

  @override
  ConsumerState<ScanBatchScreen> createState() => _ScanBatchScreenState();
}

class _ScanBatchScreenState extends ConsumerState<ScanBatchScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _hasDone = false; // Prevent double-scan

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _hasDone) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    if (!mounted) return;
    await _showConfirmSheet(context, code);
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _showConfirmSheet(BuildContext context, String batchId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ScanConfirmSheet(
        batchId: batchId,
        onAccepted: () {
          setState(() => _hasDone = true);
          ref.invalidate(availableBatchesProvider);
          ref.invalidate(inTransitBatchesProvider);
          Navigator.pop(ctx);
          if (mounted) Navigator.pop(context);
        },
        onCancelled: () {
          Navigator.pop(ctx);
          _controller.start();
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Batch QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Camera Error: ${error.errorCode}'),
                    ],
                  ),
                ),
              );
            },
          ),
          // Scan viewfinder
          Center(
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Bottom label
          Positioned(
            bottom: 48,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('Point at Batch QR Code', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          if (_isProcessing)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Reading batch...')
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanConfirmSheet extends StatefulWidget {
  final String batchId;
  final VoidCallback onAccepted;
  final VoidCallback onCancelled;
  const _ScanConfirmSheet({required this.batchId, required this.onAccepted, required this.onCancelled});

  @override
  State<_ScanConfirmSheet> createState() => _ScanConfirmSheetState();
}

class _ScanConfirmSheetState extends State<_ScanConfirmSheet> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await acceptBatch(widget.batchId, 'TRANSPORTER_1');
      
      // Wait for blockchain consensus to settle before refreshing UI
      await Future.delayed(const Duration(milliseconds: 1000));
      
      widget.onAccepted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Batch accepted! Status → PICKED'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        widget.onCancelled();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Batch Scanned!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            widget.batchId,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text('Accept this batch for transport?', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          if (_loading)
            const CircularProgressIndicator()
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onCancelled,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _accept,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Accept Batch'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

