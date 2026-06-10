import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../shared/models/home_models.dart';
import '../../../shared/services/home_service.dart';
import '../../../shared/widgets/home_app_bar.dart';
import '../../../shared/widgets/promo_banner_carousel.dart';
import '../../../shared/widgets/quick_nav_grid.dart';
import '../../../shared/widgets/delivery_card.dart';
import '../../../shared/widgets/home_bottom_nav.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/app_drawer_wrapper.dart';
import '../../../shared/models/order.dart';
import '../../../screens/customer/screens/customer_booking_screen.dart';
import '../../../screens/customer/screens/qr_scanner_screen.dart';
import '../../../screens/customer/screens/customer_order_detail_screen.dart';
import '../../auth/services/user_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/tokens/token_storage.dart';
import '../../../router/app_router.dart';
import '../../chatbot/screens/chatbot_screen.dart';
import '../../chat/screens/conversations_screen.dart';
import '../../chat/services/conversation_service.dart';
import '../../chat/models/conversation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _service = HomeService();
  final UserService _userService = UserService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<PromoBanner> _banners = [];
  List<DeliveryItem> _recent = [];
  List<DeliveryItem> _history = [];
  UserProfile? _userProfile;
  bool _loading = true;
  int _navIndex = 0;

  String _city = 'កំពុងស្វែងរក...';
  String _userLocation = 'កំពុងរកទីតាំង...';

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
    _fetchLiveLocation();
  }

  Future<void> _fetchLiveLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _city = 'ភ្នំពេញ';
          _userLocation = 'មិនអាចរកទីតាំងបាន';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        setState(() {
          _city = 'ភ្នំពេញ';
          _userLocation = 'មិនអាចរកទីតាំងបាន';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode using Nominatim (OpenStreetMap) – free, no API key needed
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&accept-language=km',
      );
      final response = await http.get(url, headers: {'User-Agent': 'ChonhchounApp/1.0'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final city = address['city'] ?? address['town'] ?? address['state'] ?? 'ភ្នំពេញ';
          final road = address['road'] ?? '';
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? '';
          final district = address['city_district'] ?? address['county'] ?? '';

          // Build a readable address line from available parts
          final parts = [road, suburb, district].where((s) => s.isNotEmpty).toList();
          final locationStr = parts.isNotEmpty ? parts.join(', ') : 'ទីតាំងបច្ចុប្បន្ន';

          if (mounted) {
            setState(() {
              _city = city;
              _userLocation = locationStr;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching live location: $e');
      if (mounted) {
        setState(() {
          _city = 'ភ្នំពេញ';
          _userLocation = 'មិនអាចរកទីតាំងបាន';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addOrder(CustomerOrder order) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final newItem = await _service.createPackage(order, token);

      setState(() {
        _recent = [newItem, ..._recent];
        _history = [newItem, ..._history];
        _navIndex = 1; // Switch to Shipping tab
      });
    } catch (e) {
      debugPrint("Booking Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("ការកក់មិនបានជោគជ័យ: $e")));
      }
    }
  }

  void _openBooking(DeliveryServiceType serviceType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerBookingScreen(
          onOrderCreated: _addOrder,
          serviceType: serviceType,
        ),
      ),
    );
  }

  void _showServiceSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ជ្រើសរើសប្រភេទសេវាកម្ម',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203247),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ជ្រើសរើសសេវាកម្មដែលអ្នកចង់ប្រើប្រាស់',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildServiceOption(
              icon: Icons.electric_bolt_rounded,
              title: 'Chonhchoun Express',
              subtitle: 'ដឹកជញ្ជូនរហ័សទាន់ចិត្ត (ក្រោម ២ ម៉ោង)',
              onTap: () {
                Navigator.pop(context);
                _openBooking(DeliveryServiceType.express);
              },
            ),
            const SizedBox(height: 12),
            _buildServiceOption(
              icon: Icons.warehouse_rounded,
              title: 'Warehouse to Warehouse',
              subtitle: 'ផ្ញើពីឃ្លាំងមួយទៅឃ្លាំងមួយទៀត (តម្លៃធូរថ្លៃ)',
              onTap: () {
                Navigator.pop(context);
                _openBooking(DeliveryServiceType.warehouse);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C5F8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2C5F8A)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF203247),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final results = await Future.wait([
        _service.fetchBanners(),
        _service.fetchRecentDeliveries(accessToken),
        _service.fetchDeliveryHistory(accessToken),
        _userService.getMe(accessToken: accessToken).catchError((_) => null),
      ]);

      if (mounted) {
        setState(() {
          _banners = results[0] as List<PromoBanner>;
          _recent = List<DeliveryItem>.from(results[1] as List);
          _history = List<DeliveryItem>.from(results[2] as List);
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
      onTap: () {},
    ),
    QuickNavItem(
      customIcon: Image.asset('assets/images/truck.png', width: 50, height: 50),
      label: 'តាមដាន',
      onTap: () => setState(() => _navIndex = 1),
    ),
    QuickNavItem(
      customIcon: Image.asset('assets/images/guys.png', width: 50, height: 50),
      label: 'បញ្ជាដឹក',
      onTap: _showServiceSelectionSheet,
    ),
    QuickNavItem(
      customIcon: Image.asset(
        'assets/images/listes.png',
        width: 50,
        height: 50,
      ),
      label: 'ប្រវត្តិ',
      onTap: () => setState(() => _navIndex = 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bluePanelHeight = screenHeight * 0.41;
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
        // Chatbot is only available to customer accounts.
        floatingActionButton: _userProfile?.role == 'customer'
            ? _ChatbotFab(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatbotScreen(userId: _userProfile?.id),
                    ),
                  );
                },
              )
            : null,
        bottomNavigationBar: HomeBottomNav(
          currentIndex: _navIndex,
          onTap: (i) {
            if (i == 4) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QRScannerScreen()));
            } else if (i == 3) {
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
            : IndexedStack(
                index: _navIndex,
                children: [
                  _buildHomeView(bluePanelHeight, avatarUrl),
                  _buildShippingView(),
                  _buildMessagesView(),
                ],
              ),
      ),
    );
  }

  Widget _buildHomeView(double bluePanelHeight, String avatarUrl) {
    return RefreshIndicator(
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
                    errorBuilder: (_, _, _) => const SizedBox(height: 60),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 8),
                    Builder(
                      builder: (drawerContext) => HomeAppBar(
                        city: _city,
                        userLocation: _userLocation,
                        onMenuTap: () =>
                            AppDrawerController.of(drawerContext)?.open(),
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
                    _SearchBar(controller: _searchCtrl),
                    const SizedBox(height: 16),
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
                    onLinkTap: () => setState(() => _navIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  if (_recent.isEmpty)
                    const _EmptyState(message: 'មិនមានការដឹកជញ្ជូនថ្មីៗទេ')
                  else
                    ...(_recent.map(
                      (item) => DeliveryCard(
                        item: item,
                        showTracking: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerOrderDetailScreen(packageId: item.id),
                            ),
                          );
                        },
                      ),
                    )),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'ការជញ្ជូនកន្លងទៅ',
                    onLinkTap: () => setState(() => _navIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    const _EmptyState(message: 'មិនមានការជញ្ជូនកន្លងទៅទេ')
                  else
                    ...(_history.map(
                      (item) => DeliveryCard(
                        item: item,
                        showTracking: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerOrderDetailScreen(packageId: item.id),
                            ),
                          );
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
    );
  }

  Widget _buildShippingView() {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      appBar: AppBar(
        title: const Text(
          'ការដឹកជញ្ជូន',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF203247),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _history.isEmpty
          ? const _EmptyState(message: 'មិនទាន់មានការដឹកជញ្ជូននៅឡើយទេ')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DeliveryCard(
                    item: _history[index],
                    showTracking: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerOrderDetailScreen(packageId: _history[index].id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMessagesView() {
    final profile = _userProfile;
    if (profile == null) {
      return const Center(
        child: Text('សូមចូលគណនីជាមុនសិន',
            style: TextStyle(color: Color(0xFF8BA4C8))),
      );
    }
    return ConversationsScreen(
      currentUserId: profile.id,
      loader: () async {
        final token = await TokenStorage.getAccessToken();
        if (token == null) return <Conversation>[];
        return ConversationService().customerConversations(token);
      },
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
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              // Same flow as scanning
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const QRScannerScreen(),
              ));
              // Since the QRScannerScreen relies on camera, we would actually just call
              // the API directly, but for simplicity, we navigate there. 
              // Wait, let's just show a snackbar for now.
            }
          },
          style: const TextStyle(fontSize: 13, color: Color(0xFF2D3A4E)),
          decoration: const InputDecoration(
            hintText: 'Enter your tracking number',
            hintStyle: TextStyle(fontSize: 13, color: Color(0xFFB0BEC5)),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Color(0xFFB0BEC5),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          ),
        ),
      ),
    );
  }
}

class _ChatbotFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatbotFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C6B9E), Color(0xFF1E4D73)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A5F).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.support_agent_rounded,
          color: Colors.white,
          size: 28,
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
