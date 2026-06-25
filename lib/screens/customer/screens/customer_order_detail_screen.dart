import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
import '../../../global/base_url.dart';
import '../../../features/auth/tokens/token_storage.dart';

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
  State<CustomerOrderDetailScreen> createState() => _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> {
  CustomerOrder? _currentOrderNullable;
  CustomerOrder get _currentOrder => _currentOrderNullable!;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  bool _isLoadingPackage = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _currentOrderNullable = widget.order;
      _fetchRoute();
    } else if (widget.packageId != null) {
      _fetchPackageAndRoute();
    }
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    final id = widget.packageId ?? _currentOrderNullable?.id;
    if (id == null || !mounted) return;
    try {
      final token = await TokenStorage.getAccessToken();
      final cleanBaseUrl = baseUrl.endsWith('/api/v1') 
          ? baseUrl.substring(0, baseUrl.length - 7) 
          : baseUrl;
      final url = token != null
          ? Uri.parse('$baseUrl/packages/$id')
          : Uri.parse('$cleanBaseUrl/packages/track/$id');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _currentOrderNullable = CustomerOrder.fromJson(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPackageAndRoute() async {
    setState(() => _isLoadingPackage = true);
    try {
      final token = await TokenStorage.getAccessToken();
      final cleanBaseUrl = baseUrl.endsWith('/api/v1') 
          ? baseUrl.substring(0, baseUrl.length - 7) 
          : baseUrl;
      final url = token != null
          ? Uri.parse('$baseUrl/packages/${widget.packageId}')
          : Uri.parse('$cleanBaseUrl/packages/track/${widget.packageId}');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentOrderNullable = CustomerOrder.fromJson(data);
          _isLoadingPackage = false;
        });
        _fetchRoute();
      } else {
        throw Exception('Package not found');
      }
    } catch (e) {
      setState(() => _isLoadingPackage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tracking details: $e')),
        );
      }
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentOrderNullable == null) return;
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${_currentOrder.pickup.longitude},${_currentOrder.pickup.latitude};${_currentOrder.dropoff.longitude},${_currentOrder.dropoff.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];
        setState(() {
          _routePoints = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
          _isLoadingRoute = false;
        });
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

  String _buildShareUrl(String trackingId) {
    String baseDomain = 'https://chonhchoun.app';
    if (kIsWeb || Uri.base.scheme.startsWith('http')) {
      final baseStr = Uri.base.toString().split('/#/').first.split('/track').first;
      baseDomain = baseStr.endsWith('/') ? baseStr.substring(0, baseStr.length - 1) : baseStr;
    }
    return '$baseDomain/#/track/$trackingId';
  }

  void _shareTrackingLink() {
    final trackingId = _currentOrderNullable?.id ?? widget.packageId ?? '';
    if (trackingId.isEmpty) return;
    final link = _buildShareUrl(trackingId);
    Share.share(
      'Track my package on Chonhchoun:\n$link',
      subject: 'Chonhchoun Delivery Tracking',
    );
  }

  void _copyTrackingLink() {
    final trackingId = _currentOrderNullable?.id ?? widget.packageId ?? '';
    if (trackingId.isEmpty) return;
    final link = _buildShareUrl(trackingId);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tracking link copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPackage || _currentOrderNullable == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text("Loading Delivery...", style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text("Delivery Summary", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share tracking link',
            onPressed: _shareTrackingLink,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 16),
            _buildLiveMap(),
            const SizedBox(height: 16),
            _buildJourneyTimeline(),
            const SizedBox(height: 16),
            _buildShareCard(),
            if (!widget.fromQR && (widget.allowCancel ?? true)) ...[
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
            if (_currentOrder.status != OrderStatus.canceled &&
                _currentOrder.status != OrderStatus.delivered &&
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
              color: (isCanceled ? AppColors.danger : AppColors.blue).withValues(alpha: 0.1),
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
                const Text("Order Status", style: TextStyle(color: AppColors.muted, fontSize: 12)),
                Text(
                  _currentOrder.statusText,
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
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final centerLat = (_currentOrder.pickup.latitude + _currentOrder.dropoff.latitude) / 2;
    final centerLng = (_currentOrder.pickup.longitude + _currentOrder.dropoff.longitude) / 2;
    final center = LatLng(centerLat, centerLng);

    final latDiff = (_currentOrder.pickup.latitude - _currentOrder.dropoff.latitude).abs();
    final lngDiff = (_currentOrder.pickup.longitude - _currentOrder.dropoff.longitude).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    double zoomLevel = 14;
    if (maxDiff > 0.05) zoomLevel = 12;
    if (maxDiff > 0.1) zoomLevel = 11;
    if (maxDiff > 0.5) zoomLevel = 9;

    return Container(
      height: 220,
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
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoomLevel,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.urlTemplate,
              userAgentPackageName: MapConfig.userAgent,
            ),
            PolylineLayer(
              polylines: [
                Polyline(points: _routePoints, color: AppColors.blue, strokeWidth: 4),
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
            'Delivery Progress',
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
    final period = isPm ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  List<_CheckpointStep> _buildCheckpoints() {
    final s = _currentOrder.status;
    bool done(OrderStatus threshold) {
      const order = [
        OrderStatus.searching,
        OrderStatus.accepted,
        OrderStatus.pickedUp,
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
          : _formatTime(_currentOrder.createdAt.add(const Duration(minutes: 2)));
    }

    String? pickedUpTime;
    if (done(OrderStatus.pickedUp)) {
      pickedUpTime = s == OrderStatus.pickedUp
          ? _formatTime(_currentOrder.updatedAt ?? _currentOrder.createdAt)
          : _formatTime(_currentOrder.createdAt.add(const Duration(minutes: 10)));
    }

    String? deliveredTime;
    if (done(OrderStatus.delivered)) {
      deliveredTime = _formatTime(_currentOrder.updatedAt ?? _currentOrder.createdAt);
    }

    return [
      _CheckpointStep(
        label: 'Pickup',
        sublabel: _currentOrder.pickupAddress,
        isCompleted: true,
        isActive: s == OrderStatus.searching,
        icon: Icons.radio_button_checked,
        color: AppColors.blue,
        timeString: createdStr,
      ),
      _CheckpointStep(
        label: 'Order Placed',
        sublabel: 'Waiting for a driver',
        isCompleted: true,
        isActive: s == OrderStatus.searching,
        icon: Icons.receipt_long_rounded,
        color: AppColors.blue,
        timeString: createdStr,
      ),
      _CheckpointStep(
        label: 'Driver Accepted',
        sublabel: _currentOrder.driverName != null
            ? 'Driver: ${_currentOrder.driverName}'
            : 'A driver is on the way to you',
        isCompleted: done(OrderStatus.accepted),
        isActive: s == OrderStatus.accepted,
        icon: Icons.person_pin_circle_rounded,
        color: const Color(0xFF6C63FF),
        timeString: acceptedTime,
      ),
      _CheckpointStep(
        label: 'Package Picked Up',
        sublabel: 'Package collected from sender',
        isCompleted: done(OrderStatus.pickedUp),
        isActive: s == OrderStatus.pickedUp,
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFFF9800),
        timeString: pickedUpTime,
      ),
      _CheckpointStep(
        label: 'Drop-off',
        sublabel: _currentOrder.dropoffAddress,
        isCompleted: done(OrderStatus.delivered),
        isActive: s == OrderStatus.delivered,
        icon: s == OrderStatus.delivered ? Icons.check_circle_rounded : Icons.location_on,
        color: s == OrderStatus.delivered ? AppColors.blue : AppColors.danger,
        timeString: deliveredTime,
      ),
    ];
  }

  Widget _buildTimelineRow(_CheckpointStep step, {required bool isLast}) {
    final dotColor = step.isCompleted ? step.color : AppColors.line;
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
                      color: step.isCompleted ? step.color.withValues(alpha: 0.4) : AppColors.line,
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
                            fontWeight: step.isActive ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                            color: step.isCompleted ? AppColors.text : AppColors.muted,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: step.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Now',
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
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
    final trackingId = _currentOrderNullable?.id ?? widget.packageId ?? '';
    final fullUrl = _buildShareUrl(trackingId);
    final displayUrl = fullUrl.replaceFirst('https://', '').replaceFirst('http://', '');
    final shortDisplay = displayUrl.length > 40 ? '${displayUrl.substring(0, 40)}...' : displayUrl;

    return AppSurfaceCard(
      child: Row(
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
                const Text('Share Tracking Link',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  shortDisplay,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: AppColors.muted,
                tooltip: 'Copy link',
                onPressed: _copyTrackingLink,
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 18),
                color: AppColors.blue,
                tooltip: 'Share',
                onPressed: _shareTrackingLink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    if (_currentOrder.id.isEmpty) return const SizedBox.shrink();
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("Tracking QR Code",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("Scan to view live status",
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 16),
          Center(
            child: QrImageView(data: _currentOrder.id, version: QrVersions.auto, size: 200.0),
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
          const Text("Package Information",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 24),
          _buildInfoItem("Item Name", _currentOrder.itemName),
          _buildInfoItem("Details",
              "${_currentOrder.typeText} • Size ${_currentOrder.size.name} • ${_currentOrder.weight}kg"),
          _buildInfoItem(
              "Service",
              _currentOrder.serviceType == DeliveryServiceType.warehouse
                  ? _currentOrder.serviceName
                  : _currentOrder.vehicleText),
          if (_currentOrder.itemHandling) _buildInfoItem("Add-ons", "Careful Item Handling"),
        ],
      ),
    );
  }

  Widget _buildDropoffDetails() {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dropoff Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 24),
          _buildInfoItem("Contact Name", _currentOrder.dropoffContactName ?? "N/A"),
          _buildInfoItem("Contact Number", _currentOrder.dropoffContactNumber ?? "N/A"),
          _buildInfoItem("Note to Driver", _currentOrder.noteToDriver ?? "No note"),
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
                child: Text("Assigned Driver",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnline ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOnline ? "Online" : "Offline",
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
          _buildInfoItem("Driver Name", _currentOrder.driverName ?? "N/A"),
          _buildInfoItem("Phone Number", _currentOrder.driverPhone ?? "N/A"),
        ],
      ),
    );
  }

  Widget _buildBillingInfo() {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Billing Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 24),
          _buildInfoItem(
            "Payment Method",
            _currentOrder.serviceType == DeliveryServiceType.warehouse
                ? (_currentOrder.paymentMethod == PaymentMethod.cash ? "Sender Pay" : "Receiver Pay")
                : (_currentOrder.paymentMethod == PaymentMethod.cash
                    ? "Cash on Delivery"
                    : "Online Payment"),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                "\$${_currentOrder.price.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: AppColors.blue, fontSize: 20),
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
          Text("Cancel Delivery",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    final List<String> reasons = [
      "Changed my mind",
      "Selected wrong location",
      "Item not ready",
      "Too expensive",
      "Found another provider",
      "Others"
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
            const Text("Cancel Delivery",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Please select a reason for cancellation",
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            ...reasons.map(
              (reason) => ListTile(
                title: Text(reason, style: const TextStyle(fontWeight: FontWeight.w500)),
                leading: const Icon(Icons.radio_button_off, size: 20, color: AppColors.muted),
                onTap: () async {
                  final token = await TokenStorage.getAccessToken();
                  final url = Uri.parse('$baseUrl/packages/${_currentOrder.id}/cancel');
                  try {
                    final response = await http.patch(url, headers: {
                      'Content-Type': 'application/json',
                      if (token != null) 'Authorization': 'Bearer $token',
                    });
                    if (response.statusCode == 200) {
                      setState(() => _currentOrder.status = OrderStatus.canceled);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Order has been canceled")),
                        );
                      }
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to cancel order: ${response.body}")),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error cancelling order: $e")),
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
