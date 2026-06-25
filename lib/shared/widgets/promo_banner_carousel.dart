import 'dart:async';
import 'package:flutter/material.dart';
import '../models/home_models.dart';

class PromoBannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;

  const PromoBannerCarousel({super.key, required this.banners});

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  static const int _multiplier = 1000;

  late final PageController _ctrl;
  late int _realIndex;
  Timer? _timer;

  static const _colors = [
    Color(0xFF2C5F8A),
    Color(0xFF1A7A4A),
    Color(0xFFD4780A),
  ];

  int get _count => widget.banners.length;
  int get _initialPage => (_multiplier ~/ 2) * _count;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.65,
    );
    _realIndex = 0;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 118,
          child: PageView.builder(
            controller: _ctrl,
            // "Infinite" page count
            itemCount: _count * _multiplier,
            onPageChanged: (page) {
              setState(() => _realIndex = page % _count);
            },
            itemBuilder: (_, page) {
              final i = page % _count;
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) {
                  double scale = 0.88;
                  if (_ctrl.position.haveDimensions) {
                    final diff = (_ctrl.page! - page).abs();
                    // Center card = 1.0, side cards = 0.88
                    scale = (1.0 - (diff * 0.10)).clamp(0.90, 1.0);
                  }
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: _BannerCard(
                  banner: widget.banners[i],
                  color: _colors[i % _colors.length],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_count, (i) {
            final active = i == _realIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBanner banner;
  final Color color;

  const _BannerCard({required this.banner, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.65)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              right: -20, top: -20,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              right: 10, bottom: -10,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            // Right icon
            Positioned(
              right: 14, top: 0, bottom: 0,
              child: Center(
                child: Icon(
                  Icons.location_on_rounded,
                  size: 46,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            // Text
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 70, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}