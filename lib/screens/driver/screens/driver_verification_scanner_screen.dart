import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code_vision/qr_code_vision.dart';

import '../../../shared/theme/app_tokens.dart';
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
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          if (_cameraUnsupported)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.desktop_windows_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Camera scanning is unavailable on desktop',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Upload a QR image below to test and complete verification.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
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
          if (!_cameraUnsupported)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.24)),
              ),
            ),
          if (!_cameraUnsupported)
            Center(
              child: Semantics(
                label: 'Position the QR code inside the scan frame',
                child: IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: DriverColors.success, width: 4),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: DriverColors.success.withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white54,
                        size: 54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!_cameraUnsupported)
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                bottom: false,
                minimum: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'Align the complete QR code inside the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_cameraUnsupported)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          'Scanning happens automatically',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _processing ? null : _scanImage,
                        icon: _processing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.image_outlined),
                        label: Text(
                          _processing
                              ? 'Verifying…'
                              : 'Upload QR image instead',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: DriverColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                      ),
                    ),
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
