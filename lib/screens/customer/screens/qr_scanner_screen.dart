import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:qr_code_vision/qr_code_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/models/home_models.dart';
import '../../../global/base_url.dart';
import '../../../features/auth/tokens/token_storage.dart';
import 'customer_order_detail_screen.dart';
import 'recipient_express_tracking_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  late AnimationController _animationController;
  bool _isProcessing = false;

  bool get _isUnsupportedPlatform => kIsWeb
      ? true
      : (io.Platform.isWindows || io.Platform.isMacOS || io.Platform.isLinux);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _fetchTrackingInfo(String id) async {
    const recipientPrefix = 'chonhchoun:recipient:';
    if (id.startsWith(recipientPrefix)) {
      final recipientToken = id.substring(recipientPrefix.length).trim();
      if (recipientToken.isNotEmpty && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RecipientExpressTrackingScreen(token: recipientToken),
          ),
        );
      }
      return;
    }
    if (id.startsWith('chonhchoun:pickup:') ||
        id.startsWith('chonhchoun:dropoff:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This verification QR must be scanned by the driver.'),
        ),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final token = await TokenStorage.getAccessToken();
      final url = Uri.parse('$baseUrl/packages/$id');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final item = DeliveryItem.fromJson(data);

        if (mounted) {
          // Replace the scanner route with Delivery Summary so back returns
          // to the screen before the scanner (e.g., Home).
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerOrderDetailScreen(
                packageId: item.id,
                allowCancel: false,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package not found or invalid QR code.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error finding package: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickAndScanImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isProcessing = true);
    try {
      final Uint8List bytes = await image.readAsBytes();

      String? qrText;

      final qrCode = QrCode();
      qrCode.scanImageBytes(bytes);
      if (qrCode.content != null) {
        qrText = qrCode.content!.text;
      }

      // Fallback to mobile_scanner analyzeImage if pure Dart failed (e.g., on Android/iOS)
      if (qrText == null && !_isUnsupportedPlatform) {
        try {
          final dynamic result = await _scannerController.analyzeImage(
            image.path,
          );
          if (result is BarcodeCapture && result.barcodes.isNotEmpty) {
            qrText = result.barcodes.first.rawValue;
          }
        } catch (_) {
          // Native analyzeImage is unsupported on Windows, silenty ignore and use fallback warning
        }
      }

      if (qrText != null && qrText.isNotEmpty) {
        _fetchTrackingInfo(qrText);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No QR code found in selected image.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to read image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // The dialog-based interim screen is no longer used; QR scanning navigates
  // straight to the Delivery Summary. The method is retained in case we need
  // it for alternate flows in the future.

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      _fetchTrackingInfo(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Package QR'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
      ),
      body: Stack(
        children: [
          if (_isUnsupportedPlatform)
            Container(
              color: const Color(0xFFEEF3FB),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.no_photography_rounded,
                          size: 64,
                          color: Color(0xFF8BA4C8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'កាមេរ៉ាមិនគាំទ្រលើ Windows ទេ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF203247),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Camera scanning is not supported on Windows. Please use the button below to upload a QR code image!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _pickAndScanImage,
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text(
                          'Upload QR Code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            MobileScanner(controller: _scannerController, onDetect: _onDetect),
          // Custom scanner overlay with laser line
          if (!_isUnsupportedPlatform)
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double height = constraints.maxHeight;
                final double scanArea = 260.0;
                final double left = (width - scanArea) / 2;
                final double top = (height - scanArea) / 2;

                return Stack(
                  children: [
                    // Dark mask around scan area
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.6),
                        BlendMode.srcOut,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: scanArea,
                              height: scanArea,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Border outline for scan area
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: scanArea,
                        height: scanArea,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    // Animated laser line
                    Positioned(
                      left: left + 10,
                      top: top + 10,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              _animationController.value * (scanArea - 24),
                            ),
                            child: Container(
                              width: scanArea - 20,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.cyan.withOpacity(0.1),
                                    Colors.cyan,
                                    Colors.cyan.withOpacity(0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyan.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isUnsupportedPlatform) ...[
                  // Info/Indicator
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Align QR in Frame',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Gallery Upload Button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                      ),
                      iconSize: 26,
                      padding: const EdgeInsets.all(14),
                      onPressed: _pickAndScanImage,
                      tooltip: 'Upload QR Image',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
