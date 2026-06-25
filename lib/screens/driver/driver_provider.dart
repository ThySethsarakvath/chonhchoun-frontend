import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/auth/tokens/token_storage.dart';
import '../../shared/services/driver_service.dart';
import '../../shared/models/driver_request.dart';

class DriverProvider extends ChangeNotifier {
  final DriverService _service = DriverService();
  Timer? _pollingTimer;
  static const _pollInterval = Duration(seconds: 10);
  
  bool _isOnline = false;
  bool _isLoading = false;
  List<DriverRequest> _availableRequests = [];
  List<DriverRequest> _historyRequests = [];
  DriverRequest? _currentDelivery;
  Position? _currentPosition;

  double _balance = 0.0;
  final String _vehicleType = 'MOTORCYCLE';

  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  List<DriverRequest> get availableRequests => _availableRequests;
  List<DriverRequest> get historyRequests => _historyRequests;
  DriverRequest? get currentDelivery => _currentDelivery;
  Position? get currentPosition => _currentPosition;
  double get balance => _balance;
  String get vehicleType => _vehicleType;

  Future<void> init() async {
    await fetchHistoryRequests(silent: true);
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
          _startPolling();
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
          _stopPolling();
          _availableRequests = [];
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableRequests({bool silent = false}) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return;
    
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      final raw = await _service.fetchAvailablePackages(token);
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
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchHistoryRequests({bool silent = false}) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return;
    
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      final raw = await _service.fetchDriverPackages(token);
      _historyRequests = raw
          .map((m) {
            try {
              return DriverRequest.fromApi(m as Map<String, dynamic>);
            } catch (e) {
              print("DEV-LOG: Error parsing history request: $e, map: $m");
              rethrow;
            }
          })
          .toList();

      // Calculate balance from history
      double newBalance = 0.0;
      for (final req in _historyRequests) {
        if (req.status == 'DELIVERED') {
          newBalance += (req.rawPrice ?? 0.0) * 0.95;
        }
      }
      _balance = newBalance;
    } catch (e) {
      print("DEV-LOG: fetchHistoryRequests failed: $e");
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(_pollInterval, (_) {
      if (_isOnline) {
        fetchAvailableRequests(silent: true);
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
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

  Future<String?> uploadFile(XFile file) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return null;
    return _service.uploadFile(file, token);
  }

  Future<bool> updateDeliveryStatus(String status, {String? podImage}) async {
    if (_currentDelivery == null) return false;
    
    final token = await TokenStorage.getAccessToken();
    if (token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final packageId = _currentDelivery!.id!;
      final success = await _service.updatePackageStatus(packageId, status, token, podImage: podImage);

      if (success) {
        if (status == 'DELIVERED') {
          // Add 95% to balance locally (optimistic update)
          _balance += (_currentDelivery!.rawPrice ?? 0.0) * 0.95;
          _currentDelivery = null;
          await fetchAvailableRequests();
          await fetchHistoryRequests(silent: true);
        } else if (status == 'FAILED' || status == 'CANCELLED') {
          _currentDelivery = null;
          await fetchHistoryRequests(silent: true);
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

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
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
