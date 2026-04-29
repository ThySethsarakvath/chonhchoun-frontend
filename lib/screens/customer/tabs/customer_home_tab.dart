import 'dart:async';
import 'package:flutter/material.dart';
import '../../driver/driver_workspace_screen.dart';
import '../../driver/widgets/driver_shell_widgets.dart';
import '../models/customer_order.dart';
import '../screens/customer_order_detail_screen.dart';
import '../widgets/customer_colors.dart';
import '../widgets/customer_shell_widgets.dart';

class CustomerHomeTab extends StatelessWidget {
  const CustomerHomeTab({
    super.key,
    required this.onStartBooking,
    this.activeOrder,
  });

  final VoidCallback onStartBooking;
  final CustomerOrder? activeOrder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        CustomerHeroSection(
          subtitle: 'Welcome Back',
          name: 'រតនៈ',
          content: activeOrder != null ? _buildTrackingCard(context) : const PromoRotatingBanner(),
        ),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildSectionHeader("Available Services"),
                const SizedBox(height: 12),
                _buildServiceCard(
                  icon: Icons.electric_bolt_rounded,
                  title: "Chonh Express",
                  subtitle: "Fastest delivery under 2 hours",
                  price: "From \$2.50",
                ),
                const SizedBox(height: 12),
                _buildServiceCard(
                  icon: Icons.local_shipping_rounded,
                  title: "Chonh Regular",
                  subtitle: "Scheduled or next day delivery",
                  price: "From \$1.50",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CustomerOrderDetailScreen(order: activeOrder!)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Direct Tracking',
                  style: TextStyle(color: CustomerColors.text, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const AnimatedLiveBadge(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activeOrder!.itemName,
              style: const TextStyle(color: CustomerColors.text, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              activeOrder!.statusText,
              style: const TextStyle(color: CustomerColors.blue, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.2,
              backgroundColor: CustomerColors.line,
              valueColor: const AlwaysStoppedAnimation<Color>(CustomerColors.blue),
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return DriverSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where would you like to send your items?',
            style: TextStyle(color: CustomerColors.text, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onStartBooking,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 54,
              decoration: BoxDecoration(color: CustomerColors.surface, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  SizedBox(width: 16),
                  Icon(Icons.radio_button_checked_rounded, color: CustomerColors.blue, size: 18),
                  SizedBox(width: 10),
                  Text('Where to?', style: TextStyle(color: CustomerColors.muted, fontSize: 15)),
                  Spacer(),
                  Icon(Icons.chevron_right_rounded, color: CustomerColors.muted),
                  SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: CustomerColors.text, fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('View all', style: TextStyle(color: CustomerColors.blue, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
  }) {
    return DriverSurfaceCard(
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(color: CustomerColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: CustomerColors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: CustomerColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: CustomerColors.muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: CustomerColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(price, style: const TextStyle(color: CustomerColors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class AnimatedLiveBadge extends StatefulWidget {
  const AnimatedLiveBadge({super.key});

  @override
  State<AnimatedLiveBadge> createState() => _AnimatedLiveBadgeState();
}

class _AnimatedLiveBadgeState extends State<AnimatedLiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: CustomerColors.danger.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: CustomerColors.danger.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'LIVE',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class PromoRotatingBanner extends StatefulWidget {
  const PromoRotatingBanner({super.key});

  @override
  State<PromoRotatingBanner> createState() => _PromoRotatingBannerState();
}

class _PromoRotatingBannerState extends State<PromoRotatingBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _promos = [
    {
      'title': '50% OFF Delivery',
      'subtitle': 'First 3 orders this week!',
      'code': 'NEWCHONH',
      'color': '0xFFE3F2FD',
    },
    {
      'title': 'Express Service',
      'subtitle': 'Delivered in under 30 mins',
      'code': 'FASTCHONH',
      'color': '0xFFF1F8E9',
    },
    {
      'title': 'Refer a Friend',
      'subtitle': 'Get \$5 for every signup',
      'code': 'SHARENOW',
      'color': '0xFFFFF3E0',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _promos.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(int.parse(promo['color']!)),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            promo['title']!,
                            style: const TextStyle(
                              color: CustomerColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            promo['subtitle']!,
                            style: const TextStyle(
                              color: CustomerColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: CustomerColors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Code: ${promo['code']}',
                              style: const TextStyle(
                                color: CustomerColors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.stars_rounded, size: 60, color: CustomerColors.blueDark),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            right: 20,
            child: Row(
              children: List.generate(_promos.length, (index) {
                return Container(
                  height: 6,
                  width: _currentPage == index ? 20 : 6,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == index ? CustomerColors.blue : CustomerColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
