import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class PickupMapPicker extends StatefulWidget {
  const PickupMapPicker({super.key, required this.initialLocation, this.initialAddress, required this.warehouseLocation});

  final LatLng initialLocation;
  final String? initialAddress;
  final LatLng warehouseLocation;

  @override
  State<PickupMapPicker> createState() => _PickupMapPickerState();
}

class _PickupMapPickerState extends State<PickupMapPicker> {
  late LatLng _selected;
  String? _address;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation;
    _address = widget.initialAddress;
    if (_address == null) _reverseGeocode(_selected);
  }

  Future<void> _reverseGeocode(LatLng p) async {
    setState(() {
      _loadingAddress = true;
    });

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${p.latitude}&lon=${p.longitude}');
      final res = await http.get(url, headers: {'User-Agent': 'chonhchoun-app'});
      if (res.statusCode == 200) {
        final js = json.decode(res.body) as Map<String, dynamic>;
        setState(() {
          _address = (js['display_name'] as String?) ?? '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
        });
      } else {
        setState(() {
          _address = '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      setState(() {
        _address = '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
      });
    } finally {
      setState(() {
        _loadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Pick-Up Location'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop({'latlng': _selected, 'address': _address});
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: _selected,
              zoom: 15,
              onTap: (tapPos, latlng) async {
                setState(() => _selected = latlng);
                await _reverseGeocode(latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.warehouseLocation,
                    width: 48,
                    height: 48,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                  ),
                  Marker(
                    point: _selected,
                    width: 48,
                    height: 48,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selected pick-up', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _loadingAddress
                        ? const SizedBox(height: 20, child: Center(child: CircularProgressIndicator()))
                        : Text(_address ?? '${_selected.latitude}, ${_selected.longitude}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop({'latlng': _selected, 'address': _address}),
                          child: const Text('Save'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
