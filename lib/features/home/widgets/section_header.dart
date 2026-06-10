import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String linkText;
  final VoidCallback? onLinkTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.linkText = 'ចូលមើល',
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2D3D),
          ),
        ),
        GestureDetector(
          onTap: onLinkTap,
          child: Text(
            linkText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A8DDB),
            ),
          ),
        ),
      ],
    );
  }
}