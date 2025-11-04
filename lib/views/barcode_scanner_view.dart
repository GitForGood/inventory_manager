import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:inventory_manager/services/open_food_facts_service.dart';
import 'package:inventory_manager/widgets/batch_form_view.dart';

/// View for scanning barcodes using device camera
class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: [BarcodeFormat.ean8, BarcodeFormat.ean13, BarcodeFormat.upcA, BarcodeFormat.upcE],
  );

  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    // Prevent multiple scans of the same barcode
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Skip if we just scanned this code
    if (code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    // Vibrate or provide feedback (optional)
    HapticFeedback.vibrate();

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching product information...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      // Fetch product data from Open Food Facts
      final product = await OpenFoodFactsService.getProductByBarcode(code);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to batch form with product data
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BatchFormView(
              barcode: code,
              productData: product,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error and navigate to manual entry
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch product data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );

        // Navigate to batch form without product data
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BatchFormView(
              barcode: code,
              productData: null,
            ),
          ),
        );
      }
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // Overlay with scanning guide
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Position barcode within frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // Manual entry button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const BatchFormView(
                        barcode: null,
                        productData: null,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.keyboard),
                label: const Text('Enter Manually'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay with scanning frame
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaWidth = size.width * 0.7;
    final double scanAreaHeight = size.height * 0.3;
    final double left = (size.width - scanAreaWidth) / 2;
    final double top = (size.height - scanAreaHeight) / 2;

    // Draw semi-transparent overlay
    final paint = Paint()..color = Colors.black54;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, scanAreaHeight), paint);
    canvas.drawRect(Rect.fromLTWH(left + scanAreaWidth, top, left, scanAreaHeight), paint);
    canvas.drawRect(
      Rect.fromLTWH(0, top + scanAreaHeight, size.width, size.height - top - scanAreaHeight),
      paint,
    );

    // Draw scanning frame corners
    final framePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), framePaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), framePaint);

    // Top-right corner
    canvas.drawLine(
      Offset(left + scanAreaWidth, top),
      Offset(left + scanAreaWidth - cornerLength, top),
      framePaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaWidth, top),
      Offset(left + scanAreaWidth, top + cornerLength),
      framePaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanAreaHeight),
      Offset(left + cornerLength, top + scanAreaHeight),
      framePaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaHeight),
      Offset(left, top + scanAreaHeight - cornerLength),
      framePaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanAreaWidth, top + scanAreaHeight),
      Offset(left + scanAreaWidth - cornerLength, top + scanAreaHeight),
      framePaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaWidth, top + scanAreaHeight),
      Offset(left + scanAreaWidth, top + scanAreaHeight - cornerLength),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
