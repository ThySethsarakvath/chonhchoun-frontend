import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../theme/app_tokens.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    _NavItem(icon: Icons.home_rounded, label: 'ទំព័រដើម'),
    _NavItem(icon: Icons.local_shipping_outlined, label: 'ការដឹកជញ្ជូន'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'ការឆ្លើយឆ្លង'),
    _NavItem(icon: Icons.settings_outlined, label: 'កំណត់'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 92 + bottomInset,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 68 + bottomInset,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  border: Border(
                    top: BorderSide(color: Color(0xFFECF0F4)),
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: Row(
                    children: [
                      _buildTab(context, 0),
                      _buildTab(context, 1),
                      const SizedBox(width: 72),
                      _buildTab(context, 2),
                      _buildTab(context, 3),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Semantics(
                button: true,
                label: 'Scan QR code',
                child: Tooltip(
                  message: 'Scan QR code',
                  child: Material(
                    color: AppColors.blueDark,
                    elevation: 8,
                    shadowColor: AppColors.blueDark.withValues(alpha: 0.32),
                    shape: const CircleBorder(
                      side: BorderSide(
                        color: AppColors.surfaceContainer,
                        width: 4,
                      ),
                    ),
                    child: InkResponse(
                      onTap: () => onTap(4),
                      radius: 32,
                      child: const SizedBox(
                        width: 60,
                        height: 60,
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    final selected = currentIndex == index;
    final item = _tabs[index];
    final color = selected ? AppColors.blue : AppColors.muted;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(index),
            child: SizedBox(
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.standard,
                    curve: AppMotion.standardCurve,
                    width: selected ? 24 : 0,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: AppMotion.fast,
                    curve: AppMotion.standardCurve,
                    child: Icon(item.icon, size: 22, color: color),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
