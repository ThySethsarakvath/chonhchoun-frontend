import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../shared/models/order.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/widgets/app_shell_widgets.dart';
import '../../../shared/data/map_data.dart';

class CustomerOrderDetailScreen extends StatefulWidget {
  const CustomerOrderDetailScreen({super.key, required this.order});

  final CustomerOrder order;

  @override
  State<CustomerOrderDetailScreen> createState() => _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> {
  late CustomerOrder _currentOrder;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/${_currentOrder.pickup.longitude},${_currentOrder.pickup.latitude};${_currentOrder.dropoff.longitude},${_currentOrder.dropoff.latitude}?overview=full&geometries=geojson';
      
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
      debugPrint("Routing error: $e");
      _useFallbackRoute();
    }
  }

  void _useFallbackRoute() {
    setState(() {
      _routePoints = [_currentOrder.pickup, _currentOrder.dropoff];
      _isLoadingRoute = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text("Delivery Summary", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 16),
            _buildLiveMap(),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildPackageDetails(),
            if (_currentOrder.serviceType == DeliveryServiceType.express) ...[
              const SizedBox(height: 16),
              _buildDropoffDetails(),
            ],
            const SizedBox(height: 16),
            _buildBillingInfo(),
            if (_currentOrder.status != OrderStatus.canceled && _currentOrder.status != OrderStatus.delivered) ...[
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
                : (_currentOrder.serviceType == DeliveryServiceType.warehouse ? Icons.warehouse : Icons.delivery_dining),
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

    // Dynamic Zoom calculation (approximate)
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
                    _currentOrder.serviceType == DeliveryServiceType.warehouse ? Icons.warehouse : Icons.radio_button_checked, 
                    color: AppColors.blue, 
                    size: 24
                  ),
                ),
                Marker(
                  point: _currentOrder.dropoff,
                  width: 40,
                  height: 40,
                  child: Icon(
                    _currentOrder.serviceType == DeliveryServiceType.warehouse ? Icons.warehouse : Icons.location_on, 
                    color: AppColors.danger, 
                    size: 30
                  ),
                ),
              ],
            ),
          ],
        ),
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
          Text("Cancel Delivery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            const Text("Cancel Delivery", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Please select a reason for cancellation", style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            ...reasons.map((reason) => ListTile(
              title: Text(reason, style: const TextStyle(fontWeight: FontWeight.w500)),
              leading: const Icon(Icons.radio_button_off, size: 20, color: AppColors.muted),
              onTap: () {
                setState(() {
                  _currentOrder.status = OrderStatus.canceled;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Order has been canceled")),
                );
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return AppSurfaceCard(
      child: Column(
        children: [
          _buildDetailRow(Icons.circle, AppColors.blue, "Pickup", _currentOrder.pickupAddress),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Align(alignment: Alignment.centerLeft, child: Container(width: 2, height: 20, color: AppColors.line)),
          ),
          _buildDetailRow(Icons.location_on, AppColors.danger, "Drop-off", _currentOrder.dropoffAddress),
        ],
      ),
    );
  }

  Widget _buildPackageDetails() {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Package Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 24),
          _buildInfoItem("Item Name", _currentOrder.itemName),
          _buildInfoItem("Details", "${_currentOrder.typeText} • Size ${_currentOrder.size.name} • ${_currentOrder.weight}kg"),
          _buildInfoItem("Service", _currentOrder.serviceType == DeliveryServiceType.warehouse ? _currentOrder.serviceName : _currentOrder.vehicleText),
          if (_currentOrder.itemHandling)
            _buildInfoItem("Add-ons", "Careful Item Handling"),
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
              : (_currentOrder.paymentMethod == PaymentMethod.cash ? "Cash on Delivery" : "Online Payment")
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${_currentOrder.price.toInt()}៛", style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.blue, fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
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
