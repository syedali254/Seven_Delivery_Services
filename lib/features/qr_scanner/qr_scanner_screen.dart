import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/order_service.dart';
import '../../core/models/order_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final OrderService _orderService = OrderService();
  bool _isProcessing = false;
  final TextEditingController _manualController = TextEditingController();

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    _processOrderId(code);
  }

  Future<void> _processOrderId(String rawCode) async {
    setState(() => _isProcessing = true);
    
    String finalId = rawCode.trim();

    try {
      // 1. SMART JSON PARSING
      if (rawCode.trim().startsWith('{')) {
        try {
          final Map<String, dynamic> data = jsonDecode(rawCode);
          // Look for "order_id" or "id"
          finalId = (data['order_id'] ?? data['id'] ?? rawCode).toString();
        } catch (e) {
          // If JSON parse fails, use rawCode
        }
      }

      // 2. GHOST-BUSTER (Only clean the extracted ID)
      finalId = finalId.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '').trim();
      
      await _orderService.updateOrderStatus(finalId, OrderStatus.inTransit);
      
      if (mounted) {
        _showSuccess(finalId);
      }
    } catch (e) {
      if (mounted) {
        _showError('VERIFICATION FAILED.\nScanned: "$rawCode"\nExtracted ID: "$finalId"\nError: $e');
      }
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text('Manual Entry', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _manualController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Enter Order ID', hintStyle: TextStyle(color: AppTheme.greyColor), filled: false),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final id = _manualController.text;
              Navigator.pop(context);
              _processOrderId(id);
            },
            child: const Text('VERIFY'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.successColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 56),
            const SizedBox(height: 16),
            const Text('Order Verified', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(id, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            const Text('Status updated to In Transit', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.errorColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text('Verification Failed', style: TextStyle(color: Colors.white)),
        content: Text('Could not verify this order. Please try again or enter the ID manually.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
            controller: MobileScannerController(facing: CameraFacing.back),
          ),
          Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryColor, width: 4), borderRadius: BorderRadius.circular(20)))),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassCard(child: Column(children: [Text(_isProcessing ? 'Processing...' : 'Align QR Code', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), const Text('Point camera at the shipment QR code', style: TextStyle(color: AppTheme.greyColor, fontSize: 11))])),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _showManualEntryDialog,
                  icon: const Icon(Icons.keyboard, color: Colors.white),
                  label: const Text('Enter ID Manually', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(backgroundColor: Colors.white10, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
