import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  final LatLng agencyHubLocation = const LatLng(11.5704, 104.8985);

  String selectedFilter = 'ALL';

  final List<Map<String, dynamic>> drivers = [
    {
      'id': 'D001',
      'name': 'Sitha H',
      'latitude': 11.5715,
      'longitude': 104.8998,
      'status': 'ONLINE',
      'vehicleType': 'MOTORBIKE',
      'phone': '095 490 904',
      'packages': 3,
    },
    {
      'id': 'D002',
      'name': 'Rith C',
      'latitude': 11.5689,
      'longitude': 104.8969,
      'status': 'DELIVERING',
      'vehicleType': 'CAR',
      'phone': '095 490 904',
      'packages': 5,
    },
    {
      'id': 'D003',
      'name': 'Vong T',
      'latitude': 11.5728,
      'longitude': 104.9022,
      'status': 'IDLE',
      'vehicleType': 'MOTORBIKE',
      'phone': '095 490 904',
      'packages': 1,
    },
    {
      'id': 'D004',
      'name': 'Ratanak M',
      'latitude': 11.5678,
      'longitude': 104.9010,
      'status': 'ONLINE',
      'vehicleType': 'TRUCK',
      'phone': '095 490 904',
      'packages': 2,
    },
    {
      'id': 'D005',
      'name': 'Vath T',
      'latitude': 11.5697,
      'longitude': 104.8948,
      'status': 'DELIVERING',
      'vehicleType': 'MOTORBIKE',
      'phone': '095 490 904',
      'packages': 4,
    },
  ];

  List<Map<String, dynamic>> get filteredDrivers {
    if (selectedFilter == 'ALL') return drivers;
    return drivers.where((driver) => driver['status'] == selectedFilter).toList();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'ONLINE':
        return Colors.green;
      case 'DELIVERING':
        return Colors.orange;
      case 'IDLE':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'MOTORBIKE':
        return Icons.two_wheeler;
      case 'CAR':
        return Icons.directions_car;
      case 'TRUCK':
        return Icons.local_shipping;
      default:
        return Icons.location_on;
    }
  }

  void showDriverDetails(Map<String, dynamic> driver) {
    final Color statusColor = getStatusColor(driver['status']);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF3F9FB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: statusColor.withOpacity(0.15),
                    child: Icon(
                      getVehicleIcon(driver['vehicleType']),
                      color: statusColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF113F67),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Driver ID: ${driver['id']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF226597),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      driver['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailTile(Icons.phone, 'Phone', driver['phone']),
              _detailTile(Icons.two_wheeler, 'Vehicle', driver['vehicleType']),
              _detailTile(
                Icons.inventory_2_outlined,
                'Assigned Packages',
                '${driver['packages']}',
              ),
              _detailTile(
                Icons.place_outlined,
                'Current Location',
                '${driver['latitude']}, ${driver['longitude']}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF226597)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF113F67),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF226597),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFilterChip(String label) {
    final bool isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF113F67) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF113F67) : const Color(0xFF87C0CD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF113F67),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF113F67),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget buildDriverMarker(Map<String, dynamic> driver) {
    final Color statusColor = getStatusColor(driver['status']);
    final IconData vehicleIcon = getVehicleIcon(driver['vehicleType']);

    return GestureDetector(
      onTap: () => showDriverDetails(driver),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              vehicleIcon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              driver['name'],
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF113F67),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF113F67),
        foregroundColor: Colors.white,
        title: const Text(
          'Agency Driver Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF226597),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ChonhChoun Tracking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Agency hub and active drivers around ITC',
                  style: TextStyle(
                    color: Color(0xFFDBF1F7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              children: [
                buildFilterChip('ALL'),
                buildFilterChip('ONLINE'),
                buildFilterChip('DELIVERING'),
                buildFilterChip('IDLE'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: agencyHubLocation,
                    initialZoom: 15.2,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.frontend',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: agencyHubLocation,
                          width: 100,
                          height: 90,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF113F67),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.14),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.warehouse,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF113F67),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Agency Hub',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...filteredDrivers.map(
                          (driver) => Marker(
                            point: LatLng(driver['latitude'], driver['longitude']),
                            width: 90,
                            height: 78,
                            child: buildDriverMarker(driver),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF87C0CD),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF113F67)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap any driver icon to view full driver details.',
                        style: TextStyle(
                          color: Color(0xFF113F67),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    buildLegendItem(Icons.warehouse, const Color(0xFF113F67), 'Agency Hub'),
                    buildLegendItem(Icons.two_wheeler, Colors.green, 'Online'),
                    buildLegendItem(Icons.directions_car, Colors.orange, 'Delivering'),
                    buildLegendItem(Icons.local_shipping, Colors.grey, 'Idle'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}