import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../agencies_management/models/branch_model.dart';

class AdminAgentScreen extends StatelessWidget {
  final List<Branch> branches;
  
  // Replace this with your actual key from https://cloud.maptiler.com/account/keys/
  static const String mapTilerKey = 'k0zSDACY9KkW3e9NetrQ';

  const AdminAgentScreen({super.key, required this.branches});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('តាមដានប្រតិបត្តិការ (MapTiler Desktop)', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(11.5564, 104.9282), // Phnom Penh Center
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            // MapTiler Raster XYZ URL Template
            urlTemplate: 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$mapTilerKey',
            userAgentPackageName: 'com.chonhchoun.delivery',
            // Optional: MapTiler supports HiDPI (Retina) tiles
            tileDisplay: const TileDisplay.fadeIn(),
          ),
          MarkerLayer(
            markers: branches
                .where((b) => b.lat != null && b.lng != null)
                .map((branch) => Marker(
                      point: LatLng(branch.lat!, branch.lng!),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: branch.isActive ? Colors.blue : Colors.red,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}