import 'package:flutter/material.dart';

import '../colors/app_colors.dart';

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
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (onLinkTap != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onLinkTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  linkText,
                  style: const TextStyle(color: AppColors.blue),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
