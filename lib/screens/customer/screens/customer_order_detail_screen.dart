import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/models/order.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/widgets/app_shell_widgets.dart';
import '../../../shared/data/map_data.dart';
import '../../../shared/utils/route_motion.dart';
import '../../../global/base_url.dart';
import '../../../features/auth/tokens/token_storage.dart';
import '../customer_khmer.dart';

class CustomerOrderDetailScreen extends StatefulWidget {
  const CustomerOrderDetailScreen({
    super.key,
    this.order,
    this.packageId,
    this.allowCancel,
    this.fromQR = false,
  });

  final CustomerOrder? order;
  final String? packageId;
  final bool? allowCancel;

  /// When true the screen was opened by scanning a QR code, so we hide the
  /// QR code section (no need to show the code you just scanned).
  final bool fromQR;

  @override
  State<CustomerOrderDetailScreen> createState() =>
      _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen>
    with SingleTickerProviderStateMixin {
  CustomerOrder? _currentOrderNullable;
  CustomerOrder get _currentOrder => _currentOrderNullable!;
  bool get _isTerminalHistory => {
    OrderStatus.delivered,
    OrderStatus.canceled,
    OrderStatus.failed,
  }.contains(_currentOrder.status);
  bool get _recipientTrackingUnlocked => {
    OrderStatus.inTransit,
    OrderStatus.arrivedAtDropoff,
  }.contains(_currentOrder.status);
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  bool _isLoadingPackage = false;
  Timer? _pollTimer;
  final SmoothRouteProgress _progressSmoother = SmoothRouteProgress();
  late final AnimationController _frameController;
  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _currentOrderNullable = widget.order;
      _fetchRoute();
    } else if (widget.packageId != null) {
      _fetchPackageAndRoute();
    }
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _silentRefresh(),
    );
    _frameController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_onAnimationFrame)
          ..repeat();
  }

  void _onAnimationFrame() {
    if (_currentOrderNullable == null) return;
    if (_currentOrder.status == OrderStatus.accepted ||
        _currentOrder.status == OrderStatus.inTransit) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _frameController.dispose();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    final id = widget.packageId ?? _currentOrderNullable?.id;
    if (id == null || !mounted) return;
    try {
      final token = await TokenStorage.getAccessToken();
      final url = Uri.parse('$baseUrl/packages/$id/simulation/sync');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final previousStatus = _currentOrderNullable?.status;
        setState(() {
          _currentOrderNullable = CustomerOrder.fromJson(data);
          _routePoints = _currentOrder.activeRoutePoints;
        });
        if (previousStatus != _currentOrder.status) _fitLiveMap();
      }
    } catch (_) {}
  }

  Future<void> _fetchPackageAndRoute() async {
    setState(() => _isLoadingPackage = true);
    try {
      final token = await TokenStorage.getAccessToken();
      final url = Uri.parse('$baseUrl/packages/${widget.packageId}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentOrderNullable = CustomerOrder.fromJson(data);
          _isLoadingPackage = false;
        });
        _fetchRoute();
      } else {
        throw Exception('រកមិនឃើញកញ្ចប់ទំនិញ');
      }
    } catch (e) {
      setState(() => _isLoadingPackage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('មិនអាចផ្ទុកព័ត៌មានតាមដានបានទេ។')),
        );
      }
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentOrderNullable == null) return;
    final serverRoute = _currentOrder.activeRoutePoints;
    if (serverRoute.length >= 2) {
      setState(() {
        _routePoints = serverRoute;
        _isLoadingRoute = false;
      });
      _fitLiveMap();
      return;
    }
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${_currentOrder.pickup.longitude},${_currentOrder.pickup.latitude};${_currentOrder.dropoff.longitude},${_currentOrder.dropoff.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];
        setState(() {
          _routePoints = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
          _isLoadingRoute = false;
        });
        _fitLiveMap();
      } else {
        _useFallbackRoute();
      }
    } catch (e) {
      _useFallbackRoute();
    }
  }

  void _useFallbackRoute() {
    if (_currentOrderNullable == null) return;
    setState(() {
      _routePoints = [_currentOrder.pickup, _currentOrder.dropoff];
      _isLoadingRoute = false;
    });
  }

  void _fitLiveMap() {
    if (!_mapReady || _routePoints.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([
            ..._routePoints,
            _currentOrder.pickup,
            _currentOrder.dropoff,
          ]),
          padding: const EdgeInsets.all(42),
        ),
      );
    });
  }

  void _shareTrackingLink() {
    final token = _currentOrderNullable?.recipientTrackingToken;
    if (token == null || token.isEmpty) return;
    final link = 'chonhchoun:recipient:$token';
    Share.share(
      'តាមដានការដឹកជញ្ជូនរហ័ស ChonhChoun នេះក្នុងកម្មវិធី៖\n$link',
      subject: 'ការតាមដានការដឹកជញ្ជូន ChonhChoun',
    );
  }

  void _copyTrackingLink() {
    final token = _currentOrderNullable?.recipientTrackingToken;
    if (token == null || token.isEmpty) return;
    final link = 'chonhchoun:recipient:$token';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('បានចម្លងតំណតាមដានទៅក្ដារតម្បៀតខ្ទាស់')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPackage || _currentOrderNullable == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text(
            "កំពុងផ្ទុកការដឹកជញ្ជូន...",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          "សេចក្ដីសង្ខេបការដឹកជញ្ជូន",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
        actions: _recipientTrackingUnlocked
            ? [
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'ចែករំលែកតំណតាមដាន',
                  onPressed: _shareTrackingLink,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusHeader(),
            if (!_isTerminalHistory) ...[
              const SizedBox(height: 16),
              _buildLiveMap(),
            ],
            const SizedBox(height: 16),
            _buildJourneyTimeline(),
            const SizedBox(height: 16),
            if (_recipientTrackingUnlocked) _buildShareCard(),
            if (!widget.fromQR &&
                (widget.allowCancel ?? true) &&
                _currentOrder.status == OrderStatus.arrivedAtPickup) ...[
              const SizedBox(height: 16),
              _buildQRCode(),
            ],
            const SizedBox(height: 16),
            _buildPackageDetails(),
            if (_currentOrder.serviceType == DeliveryServiceType.express) ...[
              const SizedBox(height: 16),
              _buildDropoffDetails(),
            ],
            if (_currentOrder.driverName != null) ...[
              const SizedBox(height: 16),
              _buildDriverDetailsCard(),
            ],
            const SizedBox(height: 16),
            _buildBillingInfo(),
            if (_currentOrder.status == OrderStatus.searching &&
                (widget.allowCancel ?? true)) ...[
              const SizedBox(height: 24),
              _buildCancelButton(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final bool isCanceled = _currentOrder.status == OrderStatus.canceled;
    return AppSurfaceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isCanceled ? AppColors.danger : AppColors.blue)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCanceled
                  ? Icons.cancel_outlined
                  : (_currentOrder.serviceType == DeliveryServiceType.warehouse
                        ? Icons.warehouse
                        : Icons.delivery_dining),
              color: isCanceled ? AppColors.danger : AppColors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ស្ថានភាពការដឹកជញ្ជូន",
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                Text(
                  customerOrderStatusKhmer(_currentOrder),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCanceled ? AppColors.danger : AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMap() {
    if (_isLoadingRoute) {
      return Container(
        height: 360,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final driverMotion = sampleRouteMotion(
      _currentOrder.activeRoutePoints,
      _progressSmoother.update(
        phaseKey: _currentOrder.status.name,
        serverProgress: _currentOrder.simulationProgress,
        durationSeconds: _currentOrder.simulationDurationSeconds,
        completed: const {
          OrderStatus.arrivedAtPickup,
          OrderStatus.arrivedAtDropoff,
          OrderStatus.delivered,
        }.contains(_currentOrder.status),
      ),
    );
    final visiblePoints = <LatLng>[
      ..._routePoints,
      _currentOrder.pickup,
      _currentOrder.dropoff,
    ];
    final minLat = visiblePoints
        .map((point) => point.latitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLat = visiblePoints
        .map((point) => point.latitude)
        .reduce((a, b) => a > b ? a : b);
    final minLng = visiblePoints
        .map((point) => point.longitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLng = visiblePoints
        .map((point) => point.longitude)
        .reduce((a, b) => a > b ? a : b);
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final center = LatLng(centerLat, centerLng);

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    double zoomLevel = 14;
    if (maxDiff > 0.05) zoomLevel = 12;
    if (maxDiff > 0.1) zoomLevel = 11;
    if (maxDiff > 0.5) zoomLevel = 9;

    return Container(
      height: 360,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoomLevel,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onMapReady: () {
              _mapReady = true;
              _fitLiveMap();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.urlTemplate,
              userAgentPackageName: MapConfig.userAgent,
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  color: AppColors.blue,
                  strokeWidth: 4,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentOrder.pickup,
                  width: 40,
                  height: 40,
                  child: Icon(
                    _currentOrder.serviceType == DeliveryServiceType.warehouse
                        ? Icons.warehouse
                        : Icons.radio_button_checked,
                    color: AppColors.blue,
                    size: 24,
                  ),
                ),
                Marker(
                  point: _currentOrder.dropoff,
                  width: 40,
                  height: 40,
                  child: Icon(
                    _currentOrder.serviceType == DeliveryServiceType.warehouse
                        ? Icons.warehouse
                        : Icons.location_on,
                    color: AppColors.danger,
                    size: 30,
                  ),
                ),
                if (_currentOrder.simulatedDriverLocation != null)
                  Marker(
                    point:
                        driverMotion?.position ??
                        _currentOrder.simulatedDriverLocation!,
                    width: 54,
                    height: 70,
                    child: Transform.rotate(
                      angle: driverMotion?.bearingRadians ?? 0,
                      child: Image.asset(
                        _currentOrder.vehicleType == VehicleType.tuktuk
                            ? 'assets/images/rickshaw_topview.png'
                            : 'assets/images/motorbike_topview.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Checkpoint timeline — pickup → steps → dropoff
  Widget _buildJourneyTimeline() {
    final steps = _buildCheckpoints();
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ដំណើរការដឹកជញ្ជូន',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            return _buildTimelineRow(step, isLast: isLast);
          }),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final khmerDt = dt.toUtc().add(const Duration(hours: 7));
    final rawHour = khmerDt.hour;
    final isPm = rawHour >= 12;
    final hour12 = rawHour % 12 == 0 ? 12 : rawHour % 12;
    final minute = khmerDt.minute.toString().padLeft(2, '0');
    final period = isPm ? 'ល្ងាច' : 'ព្រឹក';
    return '$hour12:$minute $period';
  }

  List<_CheckpointStep> _buildCheckpoints() {
    final s = _currentOrder.status;
    bool done(OrderStatus threshold) {
      const order = [
        OrderStatus.searching,
        OrderStatus.accepted,
        OrderStatus.arrivedAtPickup,
        OrderStatus.inTransit,
        OrderStatus.arrivedAtDropoff,
        OrderStatus.delivered,
      ];
      final si = order.indexOf(s);
      final ti = order.indexOf(threshold);
      return si >= ti;
    }

    final createdStr = _formatTime(_currentOrder.createdAt);

    String? acceptedTime;
    if (done(OrderStatus.accepted)) {
      acceptedTime = s == OrderStatus.accepted
          ? _formatTime(_currentOrder.updatedAt ?? _currentOrder.createdAt)
          : _formatTime(
              _currentOrder.createdAt.add(const Duration(minutes: 2)),
            );
    }

    String? deliveredTime;
    if (done(OrderStatus.delivered)) {
      deliveredTime = _formatTime(
        _currentOrder.updatedAt ?? _currentOrder.createdAt,
      );
    }

    return [
      _CheckpointStep(
        label: 'ទទួលទំនិញ',
        sublabel: _currentOrder.pickupAddress,
        isCompleted: true,
        isActive: s == OrderStatus.searching,
        icon: Icons.radio_button_checked,
        color: AppColors.blue,
        timeString: createdStr,
      ),
      _CheckpointStep(
        label: 'បានបង្កើតការដឹកជញ្ជូន',
        sublabel: 'កំពុងរង់ចាំអ្នកបើកបរ',
        isCompleted: true,
        isActive: s == OrderStatus.searching,
        icon: Icons.receipt_long_rounded,
        color: AppColors.blue,
        timeString: createdStr,
      ),
      _CheckpointStep(
        label: 'អ្នកបើកបរបានទទួលយក',
        sublabel: _currentOrder.driverName != null
            ? 'អ្នកបើកបរ៖ ${_currentOrder.driverName}'
            : 'អ្នកបើកបរកំពុងធ្វើដំណើរមកកាន់អ្នក',
        isCompleted: done(OrderStatus.accepted),
        isActive: s == OrderStatus.accepted,
        icon: Icons.person_pin_circle_rounded,
        color: const Color(0xFF6C63FF),
        timeString: acceptedTime,
      ),
      _CheckpointStep(
        label: 'អ្នកបើកបរមកដល់ទីតាំងទទួល',
        sublabel: 'បង្ហាញ QR របស់អ្នកផ្ញើ ដើម្បីចាប់ផ្ដើមការដឹកជញ្ជូន',
        isCompleted: done(OrderStatus.arrivedAtPickup),
        isActive: s == OrderStatus.arrivedAtPickup,
        icon: Icons.qr_code_rounded,
        color: const Color(0xFFFF9800),
        timeString: null,
      ),
      _CheckpointStep(
        label: 'កញ្ចប់កំពុងដឹកជញ្ជូន',
        sublabel: 'អ្នកបើកបរកំពុងធ្វើដំណើរតាមផ្លូវដែលបានណែនាំ',
        isCompleted: done(OrderStatus.inTransit),
        isActive: s == OrderStatus.inTransit,
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFFF9800),
        timeString: null,
      ),
      _CheckpointStep(
        label: 'អ្នកបើកបរមកដល់អ្នកទទួល',
        sublabel: 'ត្រូវការការបញ្ជាក់ដោយ QR របស់អ្នកទទួល',
        isCompleted: done(OrderStatus.arrivedAtDropoff),
        isActive: s == OrderStatus.arrivedAtDropoff,
        icon: Icons.qr_code_scanner_rounded,
        color: AppColors.danger,
        timeString: null,
      ),
      _CheckpointStep(
        label: 'ប្រគល់ទំនិញ',
        sublabel: _currentOrder.dropoffAddress,
        isCompleted: done(OrderStatus.delivered),
        isActive: s == OrderStatus.delivered,
        icon: s == OrderStatus.delivered
            ? Icons.check_circle_rounded
            : Icons.location_on,
        color: s == OrderStatus.delivered ? AppColors.blue : AppColors.danger,
        timeString: deliveredTime,
      ),
    ];
  }

  Widget _buildTimelineRow(_CheckpointStep step, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: step.isCompleted
                        ? step.color.withValues(alpha: 0.12)
                        : AppColors.line.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.icon,
                    size: 16,
                    color: step.isCompleted ? step.color : AppColors.muted,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: step.isCompleted
                          ? step.color.withValues(alpha: 0.4)
                          : AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.label,
                          style: TextStyle(
                            fontWeight: step.isActive
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 14,
                            color: step.isCompleted
                                ? AppColors.text
                                : AppColors.muted,
                          ),
                        ),
                      ),
                      if (step.timeString != null) ...[
                        Text(
                          step.timeString!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (step.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: step.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ឥឡូវនេះ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: step.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.sublabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard() {
    final token = _currentOrder.recipientTrackingToken;
    return AppSurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.link_rounded, color: AppColors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ចែករំលែកជាមួយអ្នកទទួល',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      token == null
                          ? 'កំពុងរៀបចំការតាមដានសម្រាប់អ្នកទទួល'
                          : 'ការតាមដាននឹងបើកបន្ទាប់ពីបញ្ជាក់ការទទួលកញ្ចប់',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: AppColors.muted,
                    tooltip: 'ចម្លងតំណ',
                    onPressed: token == null ? null : _copyTrackingLink,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    color: AppColors.blue,
                    tooltip: 'ចែករំលែក',
                    onPressed: token == null ? null : _shareTrackingLink,
                  ),
                ],
              ),
            ],
          ),
          if (token != null) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'អ្នកទទួលអាចស្កេនកូដនេះក្នុងកម្មវិធី ChonhChoun',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            QrImageView(data: 'chonhchoun:recipient:$token', size: 150),
          ],
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    final token = _currentOrder.pickupQrToken;
    if (token == null || _currentOrder.status != OrderStatus.arrivedAtPickup) {
      return const SizedBox.shrink();
    }
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "QR សម្រាប់បញ្ជាក់ការទទួលកញ្ចប់",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "បង្ហាញកូដនេះដល់អ្នកបើកបរ ដើម្បីចាប់ផ្ដើមការដឹកជញ្ជូន។",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Center(
            child: QrImageView(
              data: 'chonhchoun:pickup:$token',
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDetails() {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ព័ត៌មានកញ្ចប់ទំនិញ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 24),
          _buildInfoItem("ឈ្មោះទំនិញ", _currentOrder.itemName),
          _buildInfoItem(
            "ព័ត៌មានលម្អិត",
            "${customerItemTypeKhmer(_currentOrder.itemType)} • ${_currentOrder.quantity} កញ្ចប់ • "
                "ទំហំ ${_currentOrder.size.name} • ${_currentOrder.weight} គីឡូក្រាម",
          ),
          _buildInfoItem(
            "សេវាកម្ម",
            _currentOrder.serviceType == DeliveryServiceType.warehouse
                ? customerServiceKhmer(_currentOrder.serviceType)
                : customerVehicleKhmer(_currentOrder.vehicleType),
          ),
          if (_currentOrder.itemHandling)
            _buildInfoItem("សេវាបន្ថែម", "ថែរក្សាទំនិញដោយប្រុងប្រយ័ត្ន"),
        ],
      ),
    );
  }

  Widget _buildDropoffDetails() {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ព័ត៌មានទីតាំងប្រគល់",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 24),
          _buildInfoItem(
            "ឈ្មោះអ្នកទទួល",
            _currentOrder.dropoffContactName ?? "មិនមាន",
          ),
          _buildInfoItem(
            "លេខទូរសព្ទ",
            _currentOrder.dropoffContactNumber ?? "មិនមាន",
          ),
          _buildInfoItem(
            "កំណត់សម្គាល់ជូនអ្នកបើកបរ",
            _currentOrder.noteToDriver ?? "គ្មានកំណត់សម្គាល់",
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDetailsCard() {
    final isOnline = _currentOrder.driverOnline ?? false;
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "អ្នកបើកបរដែលបានកំណត់",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnline ? Colors.green : Colors.grey).withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOnline ? "អនឡាញ" : "ក្រៅបណ្ដាញ",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoItem(
            "ឈ្មោះអ្នកបើកបរ",
            _currentOrder.driverName ?? "មិនមាន",
          ),
          _buildInfoItem("លេខទូរសព្ទ", _currentOrder.driverPhone ?? "មិនមាន"),
        ],
      ),
    );
  }

  Widget _buildBillingInfo() {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ព័ត៌មានការបង់ប្រាក់",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 24),
          _buildInfoItem(
            "វិធីបង់ប្រាក់",
            _currentOrder.serviceType == DeliveryServiceType.warehouse
                ? (_currentOrder.paymentMethod == PaymentMethod.cash
                      ? "អ្នកផ្ញើបង់"
                      : "អ្នកទទួលបង់")
                : (_currentOrder.paymentMethod == PaymentMethod.cash
                      ? "បង់ជាសាច់ប្រាក់ពេលទទួល"
                      : "បង់ប្រាក់តាមអនឡាញ"),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ចំនួនទឹកប្រាក់សរុប",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "\$${_currentOrder.price.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.blue,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: _showCancelDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.danger,
        minimumSize: const Size(double.infinity, 56),
        side: const BorderSide(color: AppColors.danger, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.close_rounded, size: 20),
          SizedBox(width: 10),
          Text(
            "បោះបង់ការដឹកជញ្ជូន",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    final List<String> reasons = [
      "ប្ដូរចិត្ត",
      "ជ្រើសរើសទីតាំងខុស",
      "ទំនិញមិនទាន់រួចរាល់",
      "តម្លៃថ្លៃពេក",
      "បានរកឃើញអ្នកផ្ដល់សេវាផ្សេង",
      "ផ្សេងៗ",
    ];
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
              "បោះបង់ការដឹកជញ្ជូន",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "សូមជ្រើសរើសមូលហេតុនៃការបោះបង់",
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            ...reasons.map(
              (reason) => ListTile(
                title: Text(
                  reason,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                leading: const Icon(
                  Icons.radio_button_off,
                  size: 20,
                  color: AppColors.muted,
                ),
                onTap: () async {
                  final token = await TokenStorage.getAccessToken();
                  final url = Uri.parse(
                    '$baseUrl/packages/${_currentOrder.id}/cancel',
                  );
                  try {
                    final response = await http.patch(
                      url,
                      headers: {
                        'Content-Type': 'application/json',
                        if (token != null) 'Authorization': 'Bearer $token',
                      },
                    );
                    if (response.statusCode == 200) {
                      setState(
                        () => _currentOrder.status = OrderStatus.canceled,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("បានបោះបង់ការដឹកជញ្ជូន"),
                          ),
                        );
                      }
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("មិនអាចបោះបង់ការដឹកជញ្ជូនបានទេ។"),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "មានបញ្ហាពេលបោះបង់ការដឹកជញ្ជូន។ សូមព្យាយាមម្ដងទៀត។",
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CheckpointStep {
  final String label;
  final String sublabel;
  final bool isCompleted;
  final bool isActive;
  final IconData icon;
  final Color color;
  final String? timeString;

  const _CheckpointStep({
    required this.label,
    required this.sublabel,
    required this.isCompleted,
    required this.isActive,
    required this.icon,
    required this.color,
    this.timeString,
  });
}
