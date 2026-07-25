import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'pickup_map_picker.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/home_models.dart';
import '../../../shared/widgets/app_shell_widgets.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/services/home_service.dart';
import '../../../features/auth/tokens/token_storage.dart';
import 'express_driver_matching_screen.dart';

class CustomerItemInfoScreen extends StatefulWidget {
  const CustomerItemInfoScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.serviceType,
    required this.onOrderCreated,
    required this.userLocation,
  });

  final LatLng pickup;
  final LatLng dropoff;
  final String pickupAddress;
  final String dropoffAddress;
  final DeliveryServiceType serviceType;
  final Future<DeliveryItem?> Function(CustomerOrder) onOrderCreated;
  final LatLng userLocation;

  @override
  State<CustomerItemInfoScreen> createState() => _CustomerItemInfoScreenState();
}

class _CustomerItemInfoScreenState extends State<CustomerItemInfoScreen> {
  // State
  ItemSize _selectedSize = ItemSize.S;
  ItemType _selectedType = ItemType.document;
  VehicleType _selectedVehicle = VehicleType.bike;
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  bool _itemHandling = false;
  bool _driverPickup = false;
  final TextEditingController _weightController = TextEditingController(
    text: "1",
  );
  final TextEditingController _quantityController = TextEditingController(
    text: "1",
  );
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _customPickupAddress;
  LatLng? _customPickupLatLng;
  final HomeService _homeService = HomeService();
  ExpressDeliveryQuote? _quote;
  bool _quoteLoading = false;
  bool _isSubmitting = false;
  String? _quoteError;

  @override
  void initState() {
    super.initState();
    if (widget.serviceType == DeliveryServiceType.express) {
      _refreshQuote();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _quantityController.dispose();
    _itemNameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _refreshQuote() async {
    setState(() {
      _quoteLoading = true;
      _quoteError = null;
      _quote = null;
    });
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Please sign in again.');
      final quote = await _homeService.quoteExpress(
        pickup: widget.pickup,
        dropoff: widget.dropoff,
        vehicleType: _selectedVehicle,
        token: token,
      );
      if (!mounted) return;
      setState(() => _quote = quote);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _quoteError = error.toString().replaceFirst(
          RegExp(r'^Exception:\s*'),
          '',
        ),
      );
    } finally {
      if (mounted) setState(() => _quoteLoading = false);
    }
  }

  double _calculateDistanceFee(double distanceInKm) {
    if (distanceInKm <= 1.0) {
      return 3000.0; // minimum 3000 riels for any distance below 1km
    } else {
      return 3000.0 +
          (distanceInKm - 1.0) *
              2000.0; // added 0.5$ (2000 riels) per km after > 1km
    }
  }

  double get _pickupDistance {
    final origin = _customPickupLatLng ?? widget.userLocation;
    return Geolocator.distanceBetween(
          origin.latitude,
          origin.longitude,
          widget.pickup.latitude,
          widget.pickup.longitude,
        ) /
        1000.0;
  }

  double get _pickupPrice {
    return _calculateDistanceFee(_pickupDistance);
  }

  double get _totalPrice {
    double base = 0.0;
    if (widget.serviceType == DeliveryServiceType.express) {
      if (_quote != null) return _quote!.amountKhr.toDouble();
      final dist =
          Geolocator.distanceBetween(
            widget.pickup.latitude,
            widget.pickup.longitude,
            widget.dropoff.latitude,
            widget.dropoff.longitude,
          ) /
          1000.0;
      base = _calculateDistanceFee(dist);
    } else {
      base =
          4000.0; // flat rate for $1 (4000 riels) delivery for warehouse-to-warehouse
      if (_driverPickup) {
        base += _pickupPrice;
      }
    }

    if (widget.serviceType != DeliveryServiceType.express &&
        _selectedVehicle == VehicleType.tuktuk) {
      base += 2000.0;
    }
    if (_itemHandling && widget.serviceType != DeliveryServiceType.express) {
      base += 2000.0;
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text("Complete booking"),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.customerContentMaxWidth,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                _buildRouteCard(),
                const SizedBox(height: AppSpacing.md),
                _buildItemSpecsCard(),
                if (widget.serviceType == DeliveryServiceType.express) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildVehicleCard(),
                  const SizedBox(height: AppSpacing.md),
                  _buildDropoffContactCard(),
                ],
                const SizedBox(height: AppSpacing.md),
                _buildAddonsCard(),
                const SizedBox(height: AppSpacing.md),
                _buildPaymentCard(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomSummary(),
    );
  }

  Widget _buildRouteCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppSurfaceCard(
        child: Column(
          children: [
            _LocationRow(
              icon: Icons.radio_button_checked,
              color: AppColors.blue,
              label: "Pick up point",
              value: widget.pickupAddress,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(width: 2, height: 16, color: AppColors.line),
              ),
            ),
            _LocationRow(
              icon: Icons.location_on,
              color: AppColors.danger,
              label: "Drop off point",
              value: widget.dropoffAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSpecsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Item Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _itemNameController,
              decoration: InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Package quantity *",
                prefixIcon: const Icon(Icons.numbers_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Size *",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _SizeChip(
                            "S",
                            isSelected: _selectedSize == ItemSize.S,
                            onTap: () =>
                                setState(() => _selectedSize = ItemSize.S),
                          ),
                          const SizedBox(width: 8),
                          _SizeChip(
                            "M",
                            isSelected: _selectedSize == ItemSize.M,
                            onTap: () =>
                                setState(() => _selectedSize = ItemSize.M),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Weight (kg) *",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Item Type *",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TypeChip(
                  "Document",
                  Icons.description,
                  _selectedType == ItemType.document,
                  () => setState(() => _selectedType = ItemType.document),
                ),
                _TypeChip(
                  "Food",
                  Icons.restaurant,
                  _selectedType == ItemType.food,
                  () => setState(() => _selectedType = ItemType.food),
                ),
                _TypeChip(
                  "Clothing",
                  Icons.checkroom,
                  _selectedType == ItemType.clothing,
                  () => setState(() => _selectedType = ItemType.clothing),
                ),
                _TypeChip(
                  "Electronics",
                  Icons.memory,
                  _selectedType == ItemType.electronics,
                  () => setState(() => _selectedType = ItemType.electronics),
                ),
                _TypeChip(
                  "Others",
                  Icons.more_horiz,
                  _selectedType == ItemType.others,
                  () => setState(() => _selectedType = ItemType.others),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // RESTORED PHOTO UPLOAD
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: _DottedPainter(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 20,
                      color: AppColors.blue,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Add photo (optional)",
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Vehicle",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _VehicleTile(
              icon: Icons.motorcycle,
              title: "Motorbike · up to 20 kg",
              price: _selectedVehicle == VehicleType.bike && _quote != null
                  ? "${_quote!.amountKhr}៛"
                  : "Road-distance price",
              isSelected: _selectedVehicle == VehicleType.bike,
              onTap: () {
                setState(() => _selectedVehicle = VehicleType.bike);
                _refreshQuote();
              },
            ),
            const SizedBox(height: 8),
            _VehicleTile(
              icon: Icons.electric_rickshaw,
              title: "Rickshaw · up to 150 kg",
              price: _selectedVehicle == VehicleType.tuktuk && _quote != null
                  ? "${_quote!.amountKhr}៛"
                  : "Road-distance price",
              isSelected: _selectedVehicle == VehicleType.tuktuk,
              onTap: () {
                setState(() => _selectedVehicle = VehicleType.tuktuk);
                _refreshQuote();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add-ons",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _itemHandling = !_itemHandling),
              child: Row(
                children: [
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: _itemHandling
                          ? AppColors.blue
                          : Colors.transparent,
                      border: Border.all(
                        color: _itemHandling ? AppColors.blue : AppColors.line,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _itemHandling
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Extra Item Handling",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Careful handling for fragile items",
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "+2,000៛",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.serviceType == DeliveryServiceType.warehouse) ...[
              const Divider(height: 24),
              InkWell(
                onTap: () => setState(() => _driverPickup = !_driverPickup),
                child: Row(
                  children: [
                    Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        color: _driverPickup
                            ? AppColors.blue
                            : Colors.transparent,
                        border: Border.all(
                          color: _driverPickup
                              ? AppColors.blue
                              : AppColors.line,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _driverPickup
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Driver Pick-Up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _customPickupAddress != null
                                ? "Pick up from: ${_customPickupAddress!}"
                                : "Pick up from your location to warehouse (${_pickupDistance.toStringAsFixed(1)} km)",
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _showChangePickupDialog,
                                child: const Text(
                                  "Change Pick-Up Location",
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_customPickupAddress != null)
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _customPickupAddress = null,
                                  ),
                                  child: const Text(
                                    "Use Current Location",
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "+${_pickupPrice.toInt()}៛",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Payment & Offers",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaymentBtn(
                  widget.serviceType == DeliveryServiceType.express
                      ? "Cash"
                      : "Sender Pay",
                  _selectedPayment == PaymentMethod.cash,
                  () => setState(() => _selectedPayment = PaymentMethod.cash),
                ),
                const SizedBox(width: 8),
                _PaymentBtn(
                  widget.serviceType == DeliveryServiceType.express
                      ? "Online"
                      : "Receiver Pay",
                  _selectedPayment == PaymentMethod.online,
                  () => setState(() => _selectedPayment = PaymentMethod.online),
                ),
              ],
            ),
            const Divider(height: 32),
            InkWell(
              onTap: () => _showPromoDialog(),
              child: const Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Text(
                    "Apply Promo Code",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPromoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Promo Code"),
        content: const TextField(
          decoration: InputDecoration(hintText: "Enter code here"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  void _showChangePickupDialog() {
    // Open map picker and await result
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PickupMapPicker(
          initialLocation: _customPickupLatLng ?? widget.userLocation,
          initialAddress: _customPickupAddress ?? widget.pickupAddress,
          warehouseLocation: widget.pickup,
        ),
      ),
    ).then((res) {
      if (res != null) {
        setState(() {
          final latlng = res['latlng'] as LatLng?;
          final addr = res['address'] as String?;
          _customPickupLatLng = latlng ?? _customPickupLatLng;
          _customPickupAddress = addr ?? _customPickupAddress;
        });
      }
    });
  }

  Widget _buildBottomSummary() {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.customerContentMaxWidth,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Payable",
                      style: TextStyle(fontSize: 16, color: AppColors.muted),
                    ),
                    Text(
                      "${_totalPrice.toInt()}៛",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blueDark,
                      ),
                    ),
                  ],
                ),
                if (widget.serviceType == DeliveryServiceType.express) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _quoteLoading
                          ? "Calculating road-distance price…"
                          : _quoteError ??
                                (_quote == null
                                    ? "Estimated price"
                                    : "${_quote!.distanceKm.toStringAsFixed(1)} km • "
                                          "${(_quote!.durationSeconds / 60).ceil()} min estimated"),
                      style: TextStyle(
                        color: _quoteError == null
                            ? AppColors.muted
                            : AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isSubmitting || _quoteLoading
                      ? null
                      : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _quoteError != null
                              ? "Retry Price Calculation"
                              : "Confirm & Book Now",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_quoteError != null) {
      await _refreshQuote();
      return;
    }
    final itemName = _itemNameController.text.trim();
    final contactName = _contactNameController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();
    final weight = double.tryParse(_weightController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());
    if (itemName.isEmpty ||
        weight == null ||
        weight <= 0 ||
        quantity == null ||
        quantity <= 0 ||
        (widget.serviceType == DeliveryServiceType.express &&
            (contactName.isEmpty || contactPhone.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Enter the item name, valid weight, and recipient contact details.",
          ),
        ),
      );
      return;
    }
    final maxWeight = _selectedVehicle == VehicleType.bike ? 20.0 : 150.0;
    final maxQuantity = _selectedVehicle == VehicleType.bike ? 5 : 30;
    if (weight > maxWeight || quantity > maxQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${_selectedVehicle == VehicleType.bike ? 'Motorbike' : 'Rickshaw'} "
            "supports up to ${maxWeight.toInt()} kg and $maxQuantity packages.",
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final order = CustomerOrder(
        id: "ORDER-${DateTime.now().millisecondsSinceEpoch}",
        pickup: _driverPickup
            ? (_customPickupLatLng ?? widget.userLocation)
            : widget.pickup,
        dropoff: widget.dropoff,
        pickupAddress: widget.pickupAddress,
        dropoffAddress: widget.dropoffAddress,
        itemName: itemName,
        size: _selectedSize,
        weight: weight,
        itemType: _selectedType,
        vehicleType: _selectedVehicle,
        paymentMethod: _selectedPayment,
        serviceType: widget.serviceType,
        itemHandling: _itemHandling,
        driverPickup: _driverPickup,
        status: OrderStatus.searching,
        createdAt: DateTime.now(),
        price: _totalPrice,
        quantity: quantity,
        dropoffContactName: contactName,
        dropoffContactNumber: contactPhone,
        noteToDriver: _noteController.text.trim(),
      );
      final created = await widget.onOrderCreated(order);
      if (created != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ExpressDriverMatchingScreen(packageId: created.id),
          ),
          (route) => route.isFirst,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildDropoffContactCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Drop-off Contact Info",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactNameController,
              decoration: InputDecoration(
                labelText: "Contact Name",
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Contact Number",
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Note to Driver (e.g. Call me when arrive)",
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip(this.label, {required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.blue : AppColors.line,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip(this.label, this.icon, this.isSelected, this.onTap);
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.text,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (v) => onTap(),
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : AppColors.blue,
      ),
      selectedColor: AppColors.blue,
      backgroundColor: Colors.white,
      padding: EdgeInsets.zero,
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.icon,
    required this.title,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String title, price;
  final bool isSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $price',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.blue.withValues(alpha: 0.07)
                : AppColors.surfaceContainerLow,
            border: Border.all(
              color: isSelected ? AppColors.blue : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.softBlue
                      : AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.blue : AppColors.muted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? AppColors.blue
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.blue : AppColors.line,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentBtn extends StatelessWidget {
  const _PaymentBtn(this.label, this.isSelected, this.onTap);
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? AppColors.blue
              : AppColors.surfaceContainerLow,
          foregroundColor: isSelected ? Colors.white : AppColors.text,
          elevation: 0,
          side: BorderSide(color: isSelected ? AppColors.blue : AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _DottedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );
    const double dashWidth = 5, dashSpace = 4;
    for (final contour in path.computeMetrics()) {
      double distance = 0;
      while (distance < contour.length) {
        final double nextDistance = distance + dashWidth;
        canvas.drawPath(contour.extractPath(distance, nextDistance), paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
