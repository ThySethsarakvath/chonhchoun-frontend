import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/models/order.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/widgets/app_map_widgets.dart';
import 'customer_item_info_screen.dart';

class CustomerBookingScreen extends StatefulWidget {
  const CustomerBookingScreen({
    super.key,
    required this.onOrderCreated,
    required this.serviceType,
  });

  final Function(CustomerOrder) onOrderCreated;
  final DeliveryServiceType serviceType;

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  LatLng? _pickupLocation;
  String? _pickupName;
  LatLng? _dropoffLocation;
  String? _dropoffName;
  bool _isSelectingPickup = true;
  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();

  static const List<Map<String, dynamic>> _warehouses = [
    // Phnom Penh Hubs
    {"name": "PP Central Warehouse (ITC)", "lat": 11.5710, "lng": 104.8990},
    {"name": "Sen Sok Warehouse", "lat": 11.5834, "lng": 104.8805},
    {"name": "Chbar Ampov Warehouse", "lat": 11.5312, "lng": 104.9455},
    
    // Provincial Warehouses
    {"name": "Siem Reap Warehouse", "lat": 13.3640, "lng": 103.8603},
    {"name": "Battambang Warehouse", "lat": 13.0957, "lng": 103.2022},
    {"name": "Sihanoukville Warehouse", "lat": 10.6275, "lng": 103.5221},
    {"name": "Kampong Cham Warehouse", "lat": 11.9934, "lng": 105.4645},
    {"name": "Kampong Speu Warehouse", "lat": 11.4542, "lng": 104.5213},
    {"name": "Kampong Chhnang Warehouse", "lat": 12.1384, "lng": 104.3394},
    {"name": "Kampong Thom Warehouse", "lat": 12.7121, "lng": 104.8887},
    {"name": "Kampot Warehouse", "lat": 10.5942, "lng": 104.1648},
    {"name": "Kep Warehouse", "lat": 10.4825, "lng": 104.3167},
    {"name": "Koh Kong Warehouse", "lat": 11.6153, "lng": 102.9838},
    {"name": "Kratie Warehouse", "lat": 12.4883, "lng": 106.0167},
    {"name": "Mondulkiri Warehouse", "lat": 12.4561, "lng": 107.1881},
    {"name": "Oddar Meanchey Warehouse", "lat": 14.1817, "lng": 103.5176},
    {"name": "Pailin Warehouse", "lat": 12.8489, "lng": 102.6092},
    {"name": "Preah Vihear Warehouse", "lat": 13.8073, "lng": 104.9804},
    {"name": "Prey Veng Warehouse", "lat": 11.4883, "lng": 105.3253},
    {"name": "Pursat Warehouse", "lat": 12.5383, "lng": 103.9192},
    {"name": "Ratanakiri Warehouse", "lat": 13.7350, "lng": 106.9872},
    {"name": "Stung Treng Warehouse", "lat": 13.5259, "lng": 105.9683},
    {"name": "Svay Rieng Warehouse", "lat": 11.0878, "lng": 105.7994},
    {"name": "Takeo Warehouse", "lat": 10.9908, "lng": 104.7847},
    {"name": "Tboung Khmum Warehouse", "lat": 11.8891, "lng": 105.8760},
    {"name": "Banteay Meanchey Warehouse", "lat": 13.5859, "lng": 102.9737},
    {"name": "Kandal Warehouse", "lat": 11.4842, "lng": 104.9472},
  ];

  String _formatLocation(LatLng? loc, String? name) {
    if (name != null) return name;
    if (loc == null) return widget.serviceType == DeliveryServiceType.express ? "Center pin on location" : "Select warehouse";
    return "${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}";
  }

  void _confirmCenterLocation() {
    if (widget.serviceType == DeliveryServiceType.warehouse) {
      _showWarehousePicker();
      return;
    }
    
    final point = _mapController.camera.center;
    setState(() {
      if (_isSelectingPickup) {
        _pickupLocation = point;
        _pickupName = null;
        if (_dropoffLocation == null) {
          _isSelectingPickup = false;
        }
      } else {
        _dropoffLocation = point;
        _dropoffName = null;
      }
    });
    
    if (_pickupLocation != null && _dropoffLocation != null) {
      _fetchRoute();
    }
  }

  void _showWarehousePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSelectingPickup ? "Select Drop-off Warehouse" : "Select Destination Warehouse",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Choose one of our Chonhchoun warehouses", style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _warehouses.length,
                itemBuilder: (context, index) {
                  final w = _warehouses[index];
                  return ListTile(
                    leading: const Icon(Icons.warehouse_outlined, color: AppColors.blue),
                    title: Text(w['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      final point = LatLng(w['lat'], w['lng']);
                      setState(() {
                        if (_isSelectingPickup) {
                          _pickupLocation = point;
                          _pickupName = w['name'];
                          _isSelectingPickup = false;
                        } else {
                          _dropoffLocation = point;
                          _dropoffName = w['name'];
                        }
                      });
                      _mapController.move(point, 15);
                      Navigator.pop(context);
                      if (_pickupLocation != null && _dropoffLocation != null) {
                        _fetchRoute();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _handleWarehouseMarkerTap(LatLng loc) {
    final warehouse = _warehouses.firstWhere((w) => LatLng(w['lat'], w['lng']) == loc);
    setState(() {
      if (_isSelectingPickup) {
        _pickupLocation = loc;
        _pickupName = warehouse['name'];
        _isSelectingPickup = false;
      } else {
        _dropoffLocation = loc;
        _dropoffName = warehouse['name'];
      }
    });
    if (_pickupLocation != null && _dropoffLocation != null) {
      _fetchRoute();
    }
  }

  Future<void> _fetchRoute() async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/${_pickupLocation!.longitude},${_pickupLocation!.latitude};${_dropoffLocation!.longitude},${_dropoffLocation!.latitude}?overview=full&geometries=geojson';
      
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body);
        final List coords = data['routes'][0]['geometry']['coordinates'];
        
        setState(() {
          _routePoints = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        });
      }
    } catch (e) {
      debugPrint("Routing error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.text),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Text(
            "Book a Delivery",
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CustomerMapPicker(
            mapController: _mapController,
            pickupLocation: _pickupLocation,
            dropoffLocation: _dropoffLocation,
            routePoints: _routePoints,
            warehouseLocations: widget.serviceType == DeliveryServiceType.warehouse
                ? _warehouses.map((w) => LatLng(w['lat'], w['lng'])).toList()
                : null,
            onWarehouseTap: _handleWarehouseMarkerTap,
          ),

          // Center Pin Selector (Only for Express)
          if (widget.serviceType == DeliveryServiceType.express)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35), // Offset to align pin tip
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isSelectingPickup ? "Pickup Point" : "Drop-off Point",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.location_on,
                        size: 45,
                        color: _isSelectingPickup ? AppColors.blue : AppColors.danger,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Selection Guide
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 20,
            right: 20,
            child: LocationInputCard(
              pickupText: _formatLocation(_pickupLocation, _pickupName),
              dropoffText: _formatLocation(_dropoffLocation, _dropoffName),
              isSelectingPickup: _isSelectingPickup,
              onSwitchMode: () => setState(() => _isSelectingPickup = !_isSelectingPickup),
            ),
          ),

          // Bottom Action Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Set Location Button
                if (_isSelectingPickup || _dropoffLocation == null || (_isSelectingPickup == false && _dropoffLocation != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _confirmCenterLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSelectingPickup ? AppColors.blue : AppColors.danger,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          _isSelectingPickup 
                            ? (_pickupLocation == null 
                                ? (widget.serviceType == DeliveryServiceType.express ? "Set Pickup Location" : "Select Pickup Warehouse")
                                : "Update Selection")
                            : (_dropoffLocation == null 
                                ? (widget.serviceType == DeliveryServiceType.express ? "Set Drop-off Location" : "Select Drop-off Warehouse")
                                : "Update Selection"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_pickupLocation != null && _dropoffLocation != null)
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.gradientPrimary,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerItemInfoScreen(
                              pickup: _pickupLocation!,
                              dropoff: _dropoffLocation!,
                              pickupAddress: _pickupName ?? _formatLocation(_pickupLocation, null),
                              dropoffAddress: _dropoffName ?? _formatLocation(_dropoffLocation, null),
                              serviceType: widget.serviceType,
                              onOrderCreated: widget.onOrderCreated,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Confirm Selection",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  onPressed: () {
                    if (_pickupLocation != null) {
                      _mapController.move(_pickupLocation!, 15);
                    }
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: AppColors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
