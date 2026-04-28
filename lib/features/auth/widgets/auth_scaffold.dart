import 'package:flutter/material.dart';
import 'auth_header.dart';

/// Base scaffold used by every auth screen.
/// Provides the blue header, white card body, and scroll safety.
class AuthScaffold extends StatelessWidget {
  final LogoAlignment logoAlignment;
  final Widget body;

  const AuthScaffold({
    super.key,
    this.logoAlignment = LogoAlignment.center,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthHeader(logoAlignment: logoAlignment),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: body,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Shows a modal error dialog with a single "OK" button.
Future<void> showErrorDialog(BuildContext context, String message) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22),
          SizedBox(width: 8),
          Text('មានបញ្ហា', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('យល់ព្រម', style: TextStyle(color: Color(0xFF4A8DDB), fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

/// Shows a success snackbar.
void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ),
  );
}