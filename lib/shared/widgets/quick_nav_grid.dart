import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../theme/app_tokens.dart';

class QuickNavItem {
  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final VoidCallback onTap;

  const QuickNavItem({
    this.icon,
    this.customIcon,
    required this.label,
    required this.onTap,
  });
}

class QuickNavGrid extends StatelessWidget {
  final List<QuickNavItem> items;

  const QuickNavGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.customerContentMaxWidth,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
            boxShadow: AppShadows.floating,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Expanded(child: _NavCell(item: item)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  final QuickNavItem item;

  const _NavCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child:
                        item.customIcon ??
                        Icon(item.icon, color: AppColors.blue, size: 26),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
