import 'package:flutter/material.dart';

class DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const DotIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4A8DDB)
                : const Color(0xFFBDD0E8),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}