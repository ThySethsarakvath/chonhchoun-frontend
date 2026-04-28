import 'package:flutter/material.dart';

enum LogoAlignment { left, center }

/// The blue header present on every auth screen:
/// • ~25 % blue gradient panel
/// • City silhouette image at the bottom of that panel
/// • App logo that overlaps the boundary (half inside, half outside)
class AuthHeader extends StatelessWidget {
  final LogoAlignment logoAlignment;

  const AuthHeader({
    super.key,
    this.logoAlignment = LogoAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.25;
    const logoSize = 72.0;
    const logoOverlap = logoSize / 2; // how far it dips below the panel

    return SizedBox(
      height: panelHeight + logoOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Blue gradient panel ─────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: panelHeight,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E4D73), Color(0xFF2C6B9E)],
                ),
              ),
            ),
          ),

          // ── City silhouette at bottom of blue panel ─────────────────────
          Positioned(
            bottom: logoOverlap,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/footer.png',
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),

          // ── Logo overlapping the boundary ───────────────────────────────
          Positioned(
            bottom: 0,
            left: logoAlignment == LogoAlignment.left ? 28 : null,
            right: logoAlignment == LogoAlignment.left ? null : null,
            // center: handled via Align when alignment == center
            child: logoAlignment == LogoAlignment.center
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: _logo(logoSize),
                  )
                : _logo(logoSize),
          ),
        ],
      ),
    );
  }

  Widget _logo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2C5F8A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}