import 'package:flutter/material.dart';

class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = [
    _NavItem(icon: Icons.home_rounded,              label: 'ទំព័រដើម'),
    _NavItem(icon: Icons.local_shipping_outlined,   label: 'ការដឹកជញ្ជូន'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'ការឆ្លើយឆ្លង'),
    _NavItem(icon: Icons.settings_outlined,         label: 'កំណត់'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 96, // 32 head-room + 64 bar
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 64,
                child: CustomPaint(
                  painter: _NotchBarPainter(),
                  child: Row(
                    children: [
                      // Left two tabs
                      _buildTab(0),
                      _buildTab(1),
                      // Center gap for QR
                      const SizedBox(width: 72),
                      // Right two tabs
                      _buildTab(2),
                      _buildTab(3),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => onTap(4), // logical index 4 = QR
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E3A5F),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A5F).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          height: MediaQuery.of(context).padding.bottom,
        ),
      ],
    );
  }

  Widget _buildTab(int index) {
    final selected = currentIndex == index;
    final item = _tabs[index];

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active top indicator bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: selected ? 20 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C5F8A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              item.icon,
              size: 22,
              color: selected ? const Color(0xFF2C5F8A) : const Color(0xFFB0BEC5),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? const Color(0xFF2C5F8A) : const Color(0xFFB0BEC5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _NotchBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const notchHalfWidth = 35.0; // half the width of the concave section
    const notchDepth     = 20.0; // how far DOWN the lowest point of the arc is
    const cornerRadius   =  4.0; // subtle rounding at the shoulder

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final cx = size.width / 2;
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(cx - notchHalfWidth - cornerRadius, 0);

    path.quadraticBezierTo(
      cx - notchHalfWidth, 0,
      cx - notchHalfWidth + cornerRadius, notchDepth * 0.4,
    );
    path.cubicTo(
      cx - notchHalfWidth + cornerRadius * 2, notchDepth,
      cx + notchHalfWidth - cornerRadius * 2, notchDepth,
      cx + notchHalfWidth - cornerRadius,     notchDepth * 0.4,
    );
    path.quadraticBezierTo(
      cx + notchHalfWidth, 0,
      cx + notchHalfWidth + cornerRadius, 0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}