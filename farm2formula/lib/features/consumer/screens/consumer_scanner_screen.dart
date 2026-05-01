import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ConsumerScannerScreen extends StatefulWidget {
  const ConsumerScannerScreen({super.key});

  @override
  State<ConsumerScannerScreen> createState() => _ConsumerScannerScreenState();
}

class _ConsumerScannerScreenState extends State<ConsumerScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trace Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_hasScanned || capture.barcodes.isEmpty) return;
              final code = capture.barcodes.first.rawValue;
              if (code == null) return;
              
              setState(() => _hasScanned = true);
              controller.stop();
              
              // Navigate to timeline with scanned lot ID
              context.go('/consumer/timeline/$code');
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Camera Error: ${error.errorCode}', style: const TextStyle(color: Colors.white)),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Text(
              'Point your camera at the QR code on the packaging to trace its journey from soil to shelf.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
            ),
          ),
        ],
      ),
    );
  }
}
