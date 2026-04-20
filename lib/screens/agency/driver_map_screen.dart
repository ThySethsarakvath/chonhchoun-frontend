import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverMapScreen extends StatelessWidget {
  const DriverMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ITC (Institute of Technology of Cambodia)
    final LatLng itcLocation = LatLng(11.5704, 104.8985);

    // Mock drivers near ITC
    final List<Map<String, dynamic>> drivers = [
      {
        'name': 'Driver A',
        'latitude': 11.5712,
        'longitude': 104.8996,
        'status': 'ONLINE',
      },
      {
        'name': 'Driver B',
        'latitude': 11.5688,
        'longitude': 104.8968,
        'status': 'DELIVERING',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF113F67),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Agency Driver Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF226597),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ChonhChoun Tracking',
                  style: TextStyle(
                    color: Color(0xFFF3F9FB),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Basic map display of driver locations for agency',
                  style: TextStyle(
                    color: Color(0xFF87C0CD),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: itcLocation,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.frontend',
                    ),
                    MarkerLayer(
                      markers: [
                        // ITC marker
                        Marker(
                          point: itcLocation,
                          width: 90,
                          height: 90,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.location_on,
                                color: Color(0xFF113F67),
                                size: 42,
                              ),
                              SizedBox(height: 2),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF113F67),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'ITC',
                                    style: TextStyle(
                                      color: Color(0xFFF3F9FB),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Driver markers
                        ...drivers.map((driver) {
                          return Marker(
                            point: LatLng(
                              driver['latitude'],
                              driver['longitude'],
                            ),
                            width: 70,
                            height: 70,
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: const Color(0xFFF3F9FB),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            driver['name'],
                                            style: const TextStyle(
                                              color: Color(0xFF113F67),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Status: ${driver['status']}',
                                            style: const TextStyle(
                                              color: Color(0xFF226597),
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: const Icon(
                                Icons.local_shipping,
                                color: Color(0xFF226597),
                                size: 36,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF87C0CD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF113F67)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap a truck marker to view driver details.',
                    style: TextStyle(
                      color: Color(0xFF113F67),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}