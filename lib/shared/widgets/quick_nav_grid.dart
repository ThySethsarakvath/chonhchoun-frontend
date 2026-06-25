import 'package:flutter/material.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C5F8A).withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) => _NavCell(item: item)).toList(),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  final QuickNavItem item;

  const _NavCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child:
                  item.customIcon ??
                  Icon(item.icon, color: const Color(0xFF2C5F8A), size: 26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3A4E),
            ),
          ),
        ],
      ),
    );
  }
}
