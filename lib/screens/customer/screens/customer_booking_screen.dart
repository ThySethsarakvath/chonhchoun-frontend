import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/customer_order.dart';
import '../widgets/customer_colors.dart';
import '../widgets/customer_map_widgets.dart';
import 'customer_item_info_screen.dart';

class CustomerBookingScreen extends StatefulWidget {
  const CustomerBookingScreen({super.key, required this.onOrderCreated});

  final Function(CustomerOrder) onOrderCreated;

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  bool _isSelectingPickup = true;
  final MapController _mapController = MapController();

  String _formatLocation(LatLng? loc) {
    if (loc == null) return "Tap on map to select";
    return "${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}";
  }

  void _handleMapTap(LatLng point) {
    setState(() {
      if (_isSelectingPickup) {
        _pickupLocation = point;
        _isSelectingPickup = false; // Move to drop-off automatically
      } else {
        _dropoffLocation = point;
      }
    });
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
              icon: const Icon(Icons.arrow_back, color: CustomerColors.text),
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
              color: CustomerColors.text,
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
            onMapTap: _handleMapTap,
            pickupLocation: _pickupLocation,
            dropoffLocation: _dropoffLocation,
          ),

          // Map Instruction Overlay
          Align(
            alignment: Alignment.center,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isSelectingPickup
                      ? "Tap to select Pickup point"
                      : "Tap to select Drop-off point",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
              pickupText: _formatLocation(_pickupLocation),
              dropoffText: _formatLocation(_dropoffLocation),
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
                if (_pickupLocation != null && _dropoffLocation != null)
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: CustomerColors.gradientPrimary,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: CustomerColors.blue.withValues(alpha: 0.3),
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
                  child: const Icon(Icons.my_location, color: CustomerColors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
