import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../screens/customer/widgets/customer_colors.dart';

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({
    super.key,
    this.imageUrl,
    this.radius = 42,
  });

  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatarDiameter = radius * 2;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      height: avatarDiameter,
      width: avatarDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _fallbackAvatar(),
                errorWidget: (_, __, ___) => _fallbackAvatar(),
              )
            : _fallbackAvatar(),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: radius,
        color: CustomerColors.blue,
      ),
    );
  }
}
