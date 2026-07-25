import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/auth/tokens/token_storage.dart';
import '../../shared/services/driver_service.dart';
import '../../shared/models/driver_request.dart';

class DriverProvider extends ChangeNotifier {
  final DriverService _service = DriverService();
  Timer? _pollingTimer;
  static const _pollInterval = Duration(seconds: 3);

  bool _isOnline = false;
  bool _isLoading = false;
  List<DriverRequest> _availableRequests = [];
  List<DriverRequest> _historyRequests = [];
  DriverRequest? _currentDelivery;
  String? _lastError;

  double _balance = 0.0;
  final String _vehicleType = 'MOTORCYCLE';

  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  List<DriverRequest> get availableRequests => _availableRequests;
  List<DriverRequest> get historyRequests => _historyRequests;
  DriverRequest? get currentDelivery => _currentDelivery;
  String? get lastError => _lastError;
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
      await _service.updateDriverStatus(newState, token);
      _isOnline = newState;
      _lastError = null;
      if (_isOnline) {
        await fetchAvailableRequests(silent: true);
        _startPolling();
      } else {
        _stopPolling();
        _availableRequests = [];
      }
    } catch (error) {
      _lastError = error.toString();
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
      _availableRequests = raw.map((m) {
        try {
          return DriverRequest.fromApi(m as Map<String, dynamic>);
        } catch (e) {
          rethrow;
        }
      }).toList();
    } catch (e) {
      _lastError = e.toString();
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
      _historyRequests = raw.map((m) {
        try {
          return DriverRequest.fromApi(m as Map<String, dynamic>);
        } catch (e) {
          rethrow;
        }
      }).toList();

      final active = _historyRequests.where(
        (request) => const {
          'ACCEPTED',
          'ARRIVED_AT_PICKUP',
          'IN_TRANSIT',
          'ARRIVED_AT_DROPOFF',
        }.contains(request.status),
      );
      if (active.isNotEmpty) {
        _currentDelivery = active.first;
        _isOnline = true;
        _startPolling();
      }

      // Calculate balance from history
      double newBalance = 0.0;
      for (final req in _historyRequests) {
        if (req.status == 'DELIVERED') {
          newBalance += (req.rawPrice ?? 0.0) * 0.95;
        }
      }
      _balance = newBalance;
    } catch (e) {
      _lastError = e.toString();
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
      if (_currentDelivery != null) {
        syncCurrentDelivery();
      } else if (_isOnline) {
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
      final response = await _service.acceptPackage(packageId, token);
      _currentDelivery = DriverRequest.fromApi(response);
      _availableRequests.clear();
      _lastError = null;
      _startPolling();
      return true;
    } catch (error) {
      _lastError = error.toString();
      await fetchAvailableRequests(silent: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncCurrentDelivery() async {
    final delivery = _currentDelivery;
    if (delivery?.id == null) return;
    final token = await TokenStorage.getAccessToken();
    if (token == null) return;
    try {
      final response = await _service.syncPackage(delivery!.id!, token);
      final updated = DriverRequest.fromApi(response);
      if (updated.status == 'DELIVERED' ||
          updated.status == 'FAILED' ||
          updated.status == 'CANCELLED') {
        _currentDelivery = null;
        await fetchHistoryRequests(silent: true);
        if (_isOnline) await fetchAvailableRequests(silent: true);
      } else {
        _currentDelivery = updated;
      }
      _lastError = null;
      notifyListeners();
    } catch (error) {
      _lastError = error.toString();
      notifyListeners();
    }
  }

  Future<bool> verifyDeliveryQr(String rawValue) async {
    final delivery = _currentDelivery;
    if (delivery?.id == null) return false;
    final pickupPrefix = 'chonhchoun:pickup:';
    final dropoffPrefix = 'chonhchoun:dropoff:';
    final String purpose;
    final String verificationToken;
    if (rawValue.startsWith(pickupPrefix)) {
      purpose = 'PICKUP';
      verificationToken = rawValue.substring(pickupPrefix.length);
    } else if (rawValue.startsWith(dropoffPrefix)) {
      purpose = 'DROPOFF';
      verificationToken = rawValue.substring(dropoffPrefix.length);
    } else {
      _lastError = 'This is not a Chonhchoun delivery verification QR.';
      notifyListeners();
      return false;
    }

    final token = await TokenStorage.getAccessToken();
    if (token == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _service.verifyDeliveryQr(
        packageId: delivery!.id!,
        purpose: purpose,
        verificationToken: verificationToken,
        token: token,
      );
      final updated = DriverRequest.fromApi(response);
      if (updated.status == 'DELIVERED') {
        _currentDelivery = null;
        await fetchHistoryRequests(silent: true);
      } else {
        _currentDelivery = updated;
      }
      _lastError = null;
      return true;
    } catch (error) {
      _lastError = error.toString();
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
      final success = await _service.updatePackageStatus(
        packageId,
        status,
        token,
      );

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

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

class DriverScope extends InheritedNotifier<DriverProvider> {
  const DriverScope({super.key, required super.notifier, required super.child});

  static DriverProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DriverScope>()!.notifier!;
  }
}
