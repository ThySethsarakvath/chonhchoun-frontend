import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/home_models.dart';
import '../services/home_service.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/promo_banner_carousel.dart';
import '../widgets/quick_nav_grid.dart';
import '../widgets/delivery_card.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/section_header.dart';
import '../widgets/app_drawer_wrapper.dart';
import '../../auth/services/user_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/tokens/token_storage.dart';
import '../../../router/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = HomeService();
  final _userService = UserService();
  final _searchCtrl = TextEditingController();

  int _navIndex = 0;

  List<PromoBanner> _banners = [];
  List<DeliveryItem> _recent = [];
  List<DeliveryItem> _history = [];
  UserProfile? _userProfile;
  bool _loading = true;
  static const String _city = 'ភ្នំពេញ';
  static const String _userLocation = 'ផ្ទះ 175, ទឹកថ្លា, សែនសុខ';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      
      if (accessToken == null || accessToken.isEmpty) {
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      final results = await Future.wait([
        _service.fetchBanners(),
        _service.fetchRecentDeliveries(),
        _service.fetchDeliveryHistory(),
        _userService.getMe(accessToken: accessToken).catchError((_) => null),
      ]);
      
      if (mounted) {
        setState(() {
          _banners = results[0] as List<PromoBanner>;
          _recent = results[1] as List<DeliveryItem>;
          _history = results[2] as List<DeliveryItem>;
          _userProfile = results[3] as UserProfile?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<QuickNavItem> get _quickNavItems => [
    QuickNavItem(
      customIcon: Image.asset(
        'assets/images/reciept.png',
        width: 50,
        height: 50,
      ),
      label: 'អាត្រា',
      onTap: () {
        /* TODO: navigate to rate screen */
      },
    ),

    QuickNavItem(
      customIcon: Image.asset('assets/images/truck.png', width: 50, height: 50),
      label: 'តាមដាន',
      onTap: () {
        /* TODO: navigate to tracking screen */
      },
    ),
    QuickNavItem(
      customIcon: Image.asset('assets/images/guys.png', width: 50, height: 50),
      label: 'ទម្លាក់ចុះ',
      onTap: () {
        /* TODO: navigate to drop-off screen */
      },
    ),
    QuickNavItem(
      customIcon: Image.asset(
        'assets/images/listes.png',
        width: 50,
        height: 50,
      ),
      label: 'ប្រវត្តិ',
      onTap: () {
        /* TODO: navigate to history screen */
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bluePanelHeight = screenHeight * 0.41;
    
    // Use avatar URL from user profile if available, otherwise use static path
    final avatarUrl = _userProfile?.avatarUrl ?? 'assets/images/avatar.png';

    return AppDrawerWrapper(
      city: _city,
      avatarUrl: avatarUrl,
      userProfile: _userProfile,
      onProfileTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.profile,
          arguments: ProfileArgs(
            profile: _userProfile,
            source: ProfileSource.drawer,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF3FB),
        extendBody: true,
        bottomNavigationBar: HomeBottomNav(
          currentIndex: _navIndex,
          onTap: (i) {
            if (i == 3) {
              // Settings tab
              Navigator.pushNamed(context, AppRoutes.settings);
            } else {
              setState(() => _navIndex = i);
            }
          },
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2C5F8A)),
              )
            : RefreshIndicator(
                color: const Color(0xFF2C5F8A),
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: bluePanelHeight,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF1E4D73), Color(0xFF2C6B9E)],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Image.asset(
                              'assets/images/footer.png',
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.bottomCenter,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(height: 60),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).padding.top + 8,
                              ),

                              Builder(
                                builder: (drawerContext) => HomeAppBar(
                                  city: _city,
                                  userLocation: _userLocation,
                                  onMenuTap: () => AppDrawerController.of(
                                    drawerContext,
                                  )?.open(),
                                  onProfileTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.profile,
                                      arguments: ProfileArgs(
                                        profile: _userProfile,
                                        source: ProfileSource.home,
                                      ),
                                    );
                                  }, 
                                  avatarUrl: avatarUrl,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Search bar
                              _SearchBar(controller: _searchCtrl),
                              const SizedBox(height: 16),

                              // Promo banners
                              if (_banners.isNotEmpty)
                                PromoBannerCarousel(banners: _banners),

                              const SizedBox(height: 16),
                            ],
                          ),
                          Positioned(
                            bottom: -52,
                            left: 0,
                            right: 0,
                            child: QuickNavGrid(items: _quickNavItems),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'ការដឹកជញ្ជូនថ្មីៗ',
                              onLinkTap: () {
                                /* TODO */
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_recent.isEmpty)
                              _EmptyState(message: 'មិនមានការដឹកជញ្ជូនថ្មីៗទេ')
                            else
                              ...(_recent.map(
                                (item) => DeliveryCard(
                                  item: item,
                                  showTracking: true,
                                  onTap: () {
                                    /* TODO: navigate to detail */
                                  },
                                ),
                              )),

                            const SizedBox(height: 24),
                            SectionHeader(
                              title: 'ការជញ្ជូនកន្លងទៅ',
                              onLinkTap: () {
                                /* TODO */
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_history.isEmpty)
                              _EmptyState(message: 'មិនមានការជញ្ជូនកន្លងទៅទេ')
                            else
                              ...(_history.map(
                                (item) => DeliveryCard(
                                  item: item,
                                  showTracking: false,
                                  onTap: () {
                                    /* TODO: navigate to detail */
                                  },
                                ),
                              )),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: Color(0xFF2D3A4E)),
          decoration: InputDecoration(
            hintText: 'Enter your tracking number',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0BEC5)),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFFB0BEC5),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 13,
              horizontal: 4,
            ),
          ),
          onSubmitted: (val) {
            /* TODO: trigger search */
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8BA4C8)),
        ),
      ),
    );
  }
}
