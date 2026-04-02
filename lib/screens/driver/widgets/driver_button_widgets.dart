import 'package:flutter/material.dart';

import 'driver_colors.dart';

class DriverPrimaryButton extends StatelessWidget {
  const DriverPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.borderRadius = 16,
  });

  final String label;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: DriverColors.blue,
        foregroundColor: Colors.white,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class DriverSoftButton extends StatelessWidget {
  const DriverSoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.borderRadius = 16,
  });

  final String label;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: DriverColors.softBlue.withValues(alpha: 0.42),
        foregroundColor: DriverColors.blue,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class DriverOutlineButton extends StatelessWidget {
  const DriverOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 18),
    this.borderRadius = 18,
  });

  final String label;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: DriverColors.blue,
        side: BorderSide(color: DriverColors.blue.withValues(alpha: 0.25)),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class DriverDecisionBar extends StatelessWidget {
  const DriverDecisionBar({
    super.key,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: DriverSoftButton(
                label: secondaryLabel,
                onPressed: onSecondaryPressed,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DriverPrimaryButton(
                label: primaryLabel,
                onPressed: onPrimaryPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
