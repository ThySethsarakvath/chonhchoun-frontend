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
import '../../../shared/widgets/app_feedback_widgets.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/models/order.dart';
import '../../../screens/customer/screens/customer_booking_screen.dart';
import '../../../screens/customer/screens/qr_scanner_screen.dart';
import '../../../screens/customer/screens/customer_order_detail_screen.dart';
import '../../auth/services/user_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/tokens/token_storage.dart';
import '../../branch_logistics/models/branch_logistics_models.dart';
import '../../branch_logistics/services/branch_logistics_service.dart';
import '../../../router/app_router.dart';
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
  final BranchLogisticsService _branchLogisticsService =
      BranchLogisticsService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<PromoBanner> _banners = [];
  List<DeliveryItem> _recent = [];
  List<DeliveryItem> _history = [];
  UserProfile? _userProfile;
  List<BranchLogisticsShipment> _branchLogisticsShipments = [];
  bool _loading = true;
  int _navIndex = 0;
  Timer? _pollTimer;

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
    // Poll every 10 seconds for live status updates
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _silentRefresh(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty || !mounted) return;
      final results = await Future.wait([
        _service.fetchRecentDeliveries(accessToken),
        _service.fetchDeliveryHistory(accessToken),
      ]);
      if (mounted) {
        setState(() {
          _recent = List<DeliveryItem>.from(results[0] as List);
          _history = List<DeliveryItem>.from(results[1] as List);
        });
      }
    } catch (_) {}
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
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _city = 'ភ្នំពេញ';
          _userLocation = 'មិនអាចរកទីតាំងបាន';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode using Nominatim (OpenStreetMap) â€“ free, no API key needed
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&accept-language=km',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'ChonhchounApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final city =
              address['city'] ??
              address['town'] ??
              address['state'] ??
              'ភ្នំពេញ';
          final road = address['road'] ?? '';
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? '';
          final district = address['city_district'] ?? address['county'] ?? '';

          // Build a readable address line from available parts
          final parts = [
            road,
            suburb,
            district,
          ].where((s) => s.isNotEmpty).toList();
          final locationStr = parts.isNotEmpty
              ? parts.join(', ')
              : 'ទីតាំងបច្ចុប្បន្ន';

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

  Future<DeliveryItem?> _addOrder(CustomerOrder order) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return null;

      final newItem = await _service.createPackage(order, token);

      setState(() {
        _recent = [newItem, ..._recent];
        _history = [newItem, ..._history];
        _navIndex = 1; // Switch to Shipping tab
      });
      return newItem;
    } catch (e) {
      debugPrint("Booking Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("ការកក់មិនបានជោគជ័យ: $e")));
      }
      return null;
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
        _userService
            .getMe(accessToken: accessToken)
            .then<UserProfile?>((v) => v)
            .catchError((_) => null),
        _branchLogisticsService.listCustomerShipments().catchError(
          (_) => const <BranchLogisticsShipment>[],
        ),
      ]);

      if (mounted) {
        setState(() {
          _banners = results[0] as List<PromoBanner>;
          _recent = List<DeliveryItem>.from(results[1] as List);
          _history = List<DeliveryItem>.from(results[2] as List);
          _userProfile = results[3] as UserProfile?;
          _branchLogisticsShipments =
              results[4] as List<BranchLogisticsShipment>;
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bluePanelHeight = (screenHeight * 0.42).clamp(330.0, 400.0);
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
        backgroundColor: AppColors.surface,
        extendBody: true,
        bottomNavigationBar: HomeBottomNav(
          currentIndex: _navIndex,
          onTap: (i) {
            if (i == 4) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );
            } else if (i == 3) {
              Navigator.pushNamed(context, AppRoutes.settings);
            } else {
              setState(() => _navIndex = i);
            }
          },
        ),
        body: _loading
            ? const _HomeLoadingState()
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
    final recentPreview = _recent.take(1);
    final historyPreview = _history.take(5);
    return RefreshIndicator(
      color: AppColors.blue,
      backgroundColor: AppColors.surfaceContainer,
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
                      colors: AppColors.gradientPrimary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.34,
                    child: Image.asset(
                      'assets/images/footer.png',
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (_, _, _) => const SizedBox(height: 60),
                    ),
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.customerContentMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    72,
                    AppSpacing.lg,
                    112,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  SectionHeader(
                    title: 'ការដឹកជញ្ជូនថ្មីៗ',
                    onLinkTap: () => _openDeliveryList(
                      title: 'ការដឹកជញ្ជូនថ្មីៗ',
                      items: _recent,
                      showTracking: true,
                      compactAddresses: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_recent.isEmpty)
                    const _EmptyState(message: 'មិនមានការដឹកជញ្ជូនថ្មីៗទេ')
                  else
                    ...(recentPreview.map(
                      (item) => DeliveryCard(
                        item: item,
                        showTracking: true,
                        compactAddresses: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerOrderDetailScreen(packageId: item.id),
                            ),
                          );
                        },
                      ),
                    )),
                  const SizedBox(height: 24),
                  _buildBranchLogisticsSection(),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'ការជញ្ជូនកន្លងទៅ',
                    onLinkTap: () => _openDeliveryList(
                      title: 'ការជញ្ជូនកន្លងទៅ',
                      items: _history,
                      showTracking: true,
                      compactAddresses: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    const _EmptyState(message: 'មិនមានការជញ្ជូនកន្លងទៅទេ')
                  else
                    ...(historyPreview.map(
                      (item) => DeliveryCard(
                        item: item,
                        showTracking: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerOrderDetailScreen(packageId: item.id),
                            ),
                          );
                        },
                      ),
                    )),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
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
                    compactAddresses: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerOrderDetailScreen(
                            packageId: _history[index].id,
                          ),
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
        child: Text(
          'សូមចូលគណនីជាមុនសិន',
          style: TextStyle(color: Color(0xFF8BA4C8)),
        ),
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

  Widget _buildBranchLogisticsSection() {
    final sortedShipments = [..._branchLogisticsShipments]
      ..sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    final visibleShipments = sortedShipments.take(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'My Branch Logistics Tickets',
          onLinkTap: () => _openBranchTickets(sortedShipments),
        ),
        const SizedBox(height: 12),
        if (_branchLogisticsShipments.isEmpty)
          const _EmptyState(message: 'No branch logistics ticket yet')
        else
          ...visibleShipments.map((shipment) {
            final status = _customerShipmentStatusLabel(shipment.status);
            final stockId = _stockIdLabel(shipment.notes);
            final route =
                '${shipment.senderBranch?.name ?? '-'} -> ${shipment.receiverBranch?.name ?? '-'}';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shipment.ticketNumber,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shipment.itemDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Package ID: $stockId',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    route,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _openDeliveryList({
    required String title,
    required List<DeliveryItem> items,
    required bool showTracking,
    bool compactAddresses = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CustomerDeliveryListScreen(
          title: title,
          items: items,
          showTracking: showTracking,
          compactAddresses: compactAddresses,
        ),
      ),
    );
  }

  void _openBranchTickets(List<BranchLogisticsShipment> shipments) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFEEF3FB),
          appBar: AppBar(
            title: const Text(
              'My Branch Logistics Tickets',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF203247),
          ),
          body: shipments.isEmpty
              ? const _EmptyState(message: 'No branch logistics ticket yet')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  itemCount: shipments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final shipment = shipments[index];
                    return _CustomerBranchTicketCard(
                      shipment: shipment,
                      statusLabel: _customerShipmentStatusLabel(
                        shipment.status,
                      ),
                      stockId: _stockIdLabel(shipment.notes),
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _customerShipmentStatusLabel(String status) {
    switch (status) {
      case 'CREATED':
        return 'Waiting for Driver';
      case 'ASSIGNED':
        return 'Assigned to Driver';
      case 'RECEIVED_AT_SENDER_WAREHOUSE':
        return 'Collected from Branch';
      case 'IN_TRANSIT':
        return 'Delivering';
      case 'RECEIVED_AT_RECEIVER_WAREHOUSE':
        return 'Arrived at Branch';
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _stockIdLabel(String? notes) {
    final match = RegExp(
      r'Stock ID:\s*([A-Z0-9\-]+)',
      caseSensitive: false,
    ).firstMatch(notes ?? '');
    return match?.group(1) ?? '-';
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.customerContentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: DecoratedBox(
            decoration: const BoxDecoration(boxShadow: AppShadows.card),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                  );
                }
              },
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Enter your tracking number',
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: Icon(Icons.qr_code_scanner_rounded, size: 20),
              ),
            ),
          ),
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
    return AppEmptyState(message: message);
  }
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.customerContentMaxWidth,
          ),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: const [
              Row(
                children: [
                  AppSkeleton(height: 48, width: 48),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: AppSkeleton(height: 20)),
                  SizedBox(width: AppSpacing.md),
                  AppSkeleton(height: 48, width: 48, borderRadius: 24),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              AppSkeleton(height: 52),
              SizedBox(height: AppSpacing.lg),
              AppSkeleton(height: 128, borderRadius: AppRadius.lg),
              SizedBox(height: AppSpacing.xl),
              AppSkeleton(height: 108, borderRadius: AppRadius.xl),
              SizedBox(height: AppSpacing.section),
              AppSkeleton(height: 20, width: 180),
              SizedBox(height: AppSpacing.md),
              AppSkeleton(height: 168, borderRadius: AppRadius.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerDeliveryListScreen extends StatelessWidget {
  const _CustomerDeliveryListScreen({
    required this.title,
    required this.items,
    required this.showTracking,
    this.compactAddresses = false,
  });

  final String title;
  final List<DeliveryItem> items;
  final bool showTracking;
  final bool compactAddresses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF203247),
      ),
      body: items.isEmpty
          ? const _EmptyState(message: 'No delivery found')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final item = items[index];
                return DeliveryCard(
                  item: item,
                  showTracking: showTracking,
                  compactAddresses: compactAddresses,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerOrderDetailScreen(packageId: item.id),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _CustomerBranchTicketCard extends StatelessWidget {
  const _CustomerBranchTicketCard({
    required this.shipment,
    required this.statusLabel,
    required this.stockId,
  });

  final BranchLogisticsShipment shipment;
  final String statusLabel;
  final String stockId;

  @override
  Widget build(BuildContext context) {
    final route =
        '${shipment.senderBranch?.name ?? '-'} → ${shipment.receiverBranch?.name ?? '-'}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shipment.ticketNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            shipment.itemDescription,
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          Text(
            'Package ID: $stockId',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            route,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DriverRequestCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DriverRequestCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D7AF3), Color(0xFF155EEF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF155EEF).withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ចង់ក្លាយជាអ្នកបើកបរ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ផ្ញើសំណើទៅសាខា ដើម្បីឲ្យក្រុមការងារពិនិត្យ និងអនុម័តគណនីរបស់អ្នកជាភ្នាក់ងារដឹកជញ្ជូន។',
                  style: TextStyle(
                    color: Color(0xFFDCEBFF),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF155EEF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'បំពេញសំណើ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/driver_agent_request.png',
              width: 86,
              height: 86,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
