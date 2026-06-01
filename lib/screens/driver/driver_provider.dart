import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/auth/tokens/token_storage.dart';
import '../../shared/services/driver_service.dart';
import '../../shared/models/driver_request.dart';

class DriverProvider extends ChangeNotifier {
  final DriverService _service = DriverService();
  
  bool _isOnline = false;
  bool _isLoading = false;
  List<DriverRequest> _availableRequests = [];
  DriverRequest? _currentDelivery;
  Position? _currentPosition;

  double _balance = 0.0;
  String _vehicleType = 'MOTORCYCLE';

  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  List<DriverRequest> get availableRequests => _availableRequests;
  DriverRequest? get currentDelivery => _currentDelivery;
  Position? get currentPosition => _currentPosition;
  double get balance => _balance;
  String get vehicleType => _vehicleType;

  Future<void> init() async {
    // Optionally fetch driver profile to set initial balance/vehicle type
    // For now we'll just check if we have any active deliveries if we wanted to
  }

  Future<void> toggleOnline() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final newState = !_isOnline;
      Map<String, double>? locationMap;

      if (newState) {
        // Request location permissions if going online
        final hasPermission = await _handleLocationPermission();
        if (hasPermission) {
          _currentPosition = await Geolocator.getCurrentPosition();
          locationMap = {
            'lat': _currentPosition!.latitude,
            'lng': _currentPosition!.longitude,
          };
          await fetchAvailableRequests();
        } else {
          // Can't go online without location
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      final success = await _service.updateDriverStatus(newState, locationMap, token);
      if (success) {
        _isOnline = newState;
        if (!_isOnline) {
          _availableRequests = [];
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableRequests() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final raw = await _service.fetchAvailablePackages(token);
      print("DEV-LOG: fetchAvailablePackages raw length: ${raw.length}");
      print("DEV-LOG: fetchAvailablePackages raw data: $raw");
      _availableRequests = raw
          .map((m) {
            try {
              return DriverRequest.fromApi(m as Map<String, dynamic>);
            } catch (e) {
              print("DEV-LOG: Error parsing request: $e, map: $m");
              rethrow;
            }
          })
          .toList();
    } catch (e) {
      print("DEV-LOG: fetchAvailableRequests failed: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptRequest(String packageId) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.acceptPackage(packageId, token);
      if (success) {
        final idx = _availableRequests.indexWhere((r) => r.id == packageId);
        if (idx != -1) {
          _currentDelivery = _availableRequests[idx].copyWithStatus('ACCEPTED');
          _availableRequests.removeAt(idx);
        }
        return true;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDeliveryStatus(String status) async {
    if (_currentDelivery == null) return false;
    
    final token = await TokenStorage.getAccessToken();
    if (token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final packageId = _currentDelivery!.id!;
      final success = await _service.updatePackageStatus(packageId, status, token);

      if (success) {
        if (status == 'DELIVERED') {
          // Add 95% to balance locally (optimistic update)
          _balance += (_currentDelivery!.rawPrice ?? 0.0) * 0.95;
          _currentDelivery = null;
          await fetchAvailableRequests();
        } else if (status == 'FAILED' || status == 'CANCELLED') {
          _currentDelivery = null;
        } else {
          _currentDelivery = _currentDelivery!.copyWithStatus(status);
        }
        return true;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }
}

class DriverScope extends InheritedNotifier<DriverProvider> {
  const DriverScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static DriverProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DriverScope>()!.notifier!;
  }
}
