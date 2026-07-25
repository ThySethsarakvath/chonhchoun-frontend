import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code_vision/qr_code_vision.dart';

import '../../../shared/widgets/driver_colors.dart';

class DriverVerificationScannerScreen extends StatefulWidget {
  const DriverVerificationScannerScreen({
    required this.onVerify,
    required this.title,
    super.key,
  });

  final Future<bool> Function(String value) onVerify;
  final String title;

  @override
  State<DriverVerificationScannerScreen> createState() =>
      _DriverVerificationScannerScreenState();
}

class _DriverVerificationScannerScreenState
    extends State<DriverVerificationScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  bool get _cameraUnsupported =>
      kIsWeb ||
      io.Platform.isWindows ||
      io.Platform.isMacOS ||
      io.Platform.isLinux;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify(String value) async {
    if (_processing || value.trim().isEmpty) return;
    setState(() => _processing = true);
    await _controller.stop();
    final success = await widget.onVerify(value.trim());
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _processing = false);
    if (!_cameraUnsupported) await _controller.start();
  }

  Future<void> _scanImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _processing = true);
    try {
      final Uint8List bytes = await image.readAsBytes();
      final qr = QrCode()..scanImageBytes(bytes);
      final value = qr.content?.text;
      if (value == null || value.isEmpty) {
        throw Exception('No QR code was found in this image.');
      }
      setState(() => _processing = false);
      await _verify(value);
    } catch (error) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_cameraUnsupported)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Camera scanning is unavailable on desktop. Upload a QR image to test verification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            )
          else
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final value = capture.barcodes.firstOrNull?.rawValue;
                if (value != null) _verify(value);
              },
            ),
          Center(
            child: IgnorePointer(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: DriverColors.success, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: FilledButton.icon(
              onPressed: _processing ? null : _scanImage,
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              label: Text(_processing ? 'Verifying…' : 'Upload QR image'),
            ),
          ),
        ],
      ),
    );
  }
}
