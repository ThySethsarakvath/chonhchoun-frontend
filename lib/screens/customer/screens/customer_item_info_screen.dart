import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'pickup_map_picker.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/home_models.dart';
import '../../../shared/widgets/app_shell_widgets.dart';
import '../../../shared/widgets/app_map_widgets.dart';
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
    this.initialVehicle = VehicleType.bike,
    this.routePoints = const [],
  });

  final LatLng pickup;
  final LatLng dropoff;
  final String pickupAddress;
  final String dropoffAddress;
  final DeliveryServiceType serviceType;
  final Future<DeliveryItem?> Function(CustomerOrder) onOrderCreated;
  final LatLng userLocation;
  final VehicleType initialVehicle;
  final List<LatLng> routePoints;

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
  bool _isReviewing = false;
  final MapController _reviewMapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.initialVehicle;
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
      if (token == null) throw Exception('សូមចូលគណនីម្ដងទៀត។');
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
        () => _quoteError = 'មិនអាចគណនាតម្លៃដឹកជញ្ជូនបានទេ។ សូមព្យាយាមម្ដងទៀត។',
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
    if (_isReviewing) return _buildReviewScreen();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: widget.serviceType == DeliveryServiceType.express
            ? 78
            : kToolbarHeight,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Center(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.blueDark,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ព័ត៌មានកញ្ចប់ទំនិញ',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              widget.serviceType == DeliveryServiceType.express
                  ? 'ការដឹកជញ្ជូនដោយ${_selectedVehicle == VehicleType.bike ? 'ម៉ូតូ' : 'ម៉ូតូកង់បី'}'
                  : 'សូមបញ្ចូលព័ត៌មានទំនិញដែលអ្នកចង់ផ្ញើ',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          if (widget.serviceType == DeliveryServiceType.express)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    _selectedVehicle == VehicleType.bike
                        ? 'assets/images/motorbike_topview.png'
                        : 'assets/images/rickshaw_topview.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      _selectedVehicle == VehicleType.bike
                          ? Icons.two_wheeler_rounded
                          : Icons.electric_rickshaw_rounded,
                      color: AppColors.blue,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.customerContentMaxWidth,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
            ),
            child: widget.serviceType == DeliveryServiceType.express
                ? _buildExpressPackageForm()
                : Column(
                    children: [
                      _buildRouteCard(),
                      const SizedBox(height: AppSpacing.md),
                      _buildItemSpecsCard(),
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
      bottomNavigationBar: widget.serviceType == DeliveryServiceType.express
          ? _buildExpressBottomAction()
          : _buildBottomSummary(
              onPressed: _openReview,
              buttonLabel: 'ពិនិត្យការដឹកជញ្ជូន',
            ),
    );
  }

  Widget _buildExpressPackageForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ព័ត៌មានអំពីកញ្ចប់ទំនិញ',
            style: TextStyle(
              color: AppColors.blueDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'ព័ត៌មានទាំងនេះជួយឱ្យអ្នកបើកបរត្រៀមខ្លួនសម្រាប់ការដឹកជញ្ជូន។',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFieldLabel('ឈ្មោះទំនិញ', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: _itemNameController,
            textInputAction: TextInputAction.next,
            decoration: _compactInputDecoration(
              hintText: 'តើអ្នកកំពុងផ្ញើអ្វី?',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFieldLabel('ចំនួនកញ្ចប់', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: _compactInputDecoration(hintText: '1'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('ទំហំកញ្ចប់', required: true),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<ItemSize>(
                      initialValue: _selectedSize,
                      isExpanded: true,
                      decoration: _compactInputDecoration(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.muted,
                      ),
                      items: const [
                        DropdownMenuItem(value: ItemSize.S, child: Text('តូច')),
                        DropdownMenuItem(
                          value: ItemSize.M,
                          child: Text('មធ្យម'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSize = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('ទម្ងន់ (គីឡូក្រាម)', required: true),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: _compactInputDecoration(hintText: '1'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFieldLabel('ប្រភេទទំនិញ', required: true),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _TypeChip(
                'ឯកសារ',
                Icons.description_outlined,
                _selectedType == ItemType.document,
                () => setState(() => _selectedType = ItemType.document),
              ),
              _TypeChip(
                'អាហារ',
                Icons.restaurant_outlined,
                _selectedType == ItemType.food,
                () => setState(() => _selectedType = ItemType.food),
              ),
              _TypeChip(
                'សម្លៀកបំពាក់',
                Icons.checkroom_outlined,
                _selectedType == ItemType.clothing,
                () => setState(() => _selectedType = ItemType.clothing),
              ),
              _TypeChip(
                'គ្រឿងអេឡិចត្រូនិក',
                Icons.memory_outlined,
                _selectedType == ItemType.electronics,
                () => setState(() => _selectedType = ItemType.electronics),
              ),
              _TypeChip(
                'ផ្សេងៗ',
                Icons.more_horiz_rounded,
                _selectedType == ItemType.others,
                () => setState(() => _selectedType = ItemType.others),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'ព័ត៌មានអ្នកទទួល',
            style: TextStyle(
              color: AppColors.blueDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'តើអ្នកបើកបរត្រូវទាក់ទងនរណានៅទីតាំងគោលដៅ?',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFieldLabel('ឈ្មោះអ្នកទទួល', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: _contactNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _compactInputDecoration(
              hintText: 'បញ្ចូលឈ្មោះអ្នកទទួល',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFieldLabel('លេខទូរសព្ទអ្នកទទួល', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: _contactPhoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: _compactInputDecoration(hintText: 'ឧ. 010 123 456'),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFieldLabel('កំណត់សម្គាល់ជូនអ្នកបើកបរ'),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: _compactInputDecoration(
              hintText: 'ការណែនាំសម្រាប់ការដឹកជញ្ជូន (ជាជម្រើស)',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildPhotoPlaceholder(),
          const SizedBox(height: AppSpacing.xl),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'ជម្រើសការដឹកជញ្ជូន',
            style: TextStyle(
              color: AppColors.blueDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: SwitchListTile.adaptive(
              value: _itemHandling,
              onChanged: (value) => setState(() => _itemHandling = value),
              activeTrackColor: AppColors.blue,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              title: const Text(
                'ថែរក្សាទំនិញជាពិសេស',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'ស្នើឱ្យអ្នកបើកបរថែរក្សាកញ្ចប់នេះដោយប្រុងប្រយ័ត្ន។',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFieldLabel('វិធីបង់ប្រាក់', required: true),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _PaymentBtn(
                'សាច់ប្រាក់',
                _selectedPayment == PaymentMethod.cash,
                () => setState(() => _selectedPayment = PaymentMethod.cash),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PaymentBtn(
                'អនឡាញ',
                _selectedPayment == PaymentMethod.online,
                () => setState(() => _selectedPayment = PaymentMethod.online),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.danger),
            ),
        ],
      ),
      style: const TextStyle(
        color: AppColors.blueDark,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  InputDecoration _compactInputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return SizedBox(
      width: double.infinity,
      height: 76,
      child: CustomPaint(
        painter: _DottedPainter(),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 22, color: AppColors.blue),
            SizedBox(height: 4),
            Text(
              'បន្ថែមរូបថតកញ្ចប់',
              style: TextStyle(
                color: AppColors.blueDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'ជាជម្រើស',
              style: TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressBottomAction() {
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
                  blurRadius: 12,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: _quoteLoading ? null : _openReview,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.softBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: _quoteLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.blue,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Text(
                      _quoteError != null ? 'គណនាតម្លៃម្ដងទៀត' : 'បន្ត',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
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
              label: "ទីតាំងទទួលទំនិញ",
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
              label: "ទីតាំងប្រគល់ទំនិញ",
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
              "ព័ត៌មានទំនិញ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _itemNameController,
              decoration: InputDecoration(
                labelText: "ឈ្មោះទំនិញ",
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
                labelText: "ចំនួនកញ្ចប់ *",
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
                        "ទំហំ *",
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
                        "ទម្ងន់ (គីឡូក្រាម) *",
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
              "ប្រភេទទំនិញ *",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TypeChip(
                  "ឯកសារ",
                  Icons.description,
                  _selectedType == ItemType.document,
                  () => setState(() => _selectedType = ItemType.document),
                ),
                _TypeChip(
                  "អាហារ",
                  Icons.restaurant,
                  _selectedType == ItemType.food,
                  () => setState(() => _selectedType = ItemType.food),
                ),
                _TypeChip(
                  "សម្លៀកបំពាក់",
                  Icons.checkroom,
                  _selectedType == ItemType.clothing,
                  () => setState(() => _selectedType = ItemType.clothing),
                ),
                _TypeChip(
                  "គ្រឿងអេឡិចត្រូនិក",
                  Icons.memory,
                  _selectedType == ItemType.electronics,
                  () => setState(() => _selectedType = ItemType.electronics),
                ),
                _TypeChip(
                  "ផ្សេងៗ",
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
                      "បន្ថែមរូបថត (ជាជម្រើស)",
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

  Widget _buildAddonsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "សេវាបន្ថែម",
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
                          "ថែរក្សាទំនិញជាពិសេស",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "ថែរក្សាទំនិញងាយបែកដោយប្រុងប្រយ័ត្ន",
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
                            "ឱ្យអ្នកបើកបរមកទទួល",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _customPickupAddress != null
                                ? "ទទួលពី៖ ${_customPickupAddress!}"
                                : "ទទួលពីទីតាំងរបស់អ្នកទៅឃ្លាំង (${_pickupDistance.toStringAsFixed(1)} គីឡូម៉ែត្រ)",
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
                                  "កែប្រែទីតាំងទទួលទំនិញ",
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
                                    "ប្រើទីតាំងបច្ចុប្បន្ន",
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
              "ការបង់ប្រាក់ និងប្រូម៉ូសិន",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaymentBtn(
                  widget.serviceType == DeliveryServiceType.express
                      ? "សាច់ប្រាក់"
                      : "អ្នកផ្ញើបង់",
                  _selectedPayment == PaymentMethod.cash,
                  () => setState(() => _selectedPayment = PaymentMethod.cash),
                ),
                const SizedBox(width: 8),
                _PaymentBtn(
                  widget.serviceType == DeliveryServiceType.express
                      ? "អនឡាញ"
                      : "អ្នកទទួលបង់",
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
                    "ប្រើកូដប្រូម៉ូសិន",
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
        title: const Text("កូដប្រូម៉ូសិន"),
        content: const TextField(
          decoration: InputDecoration(hintText: "បញ្ចូលកូដនៅទីនេះ"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("បោះបង់"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ប្រើកូដ"),
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

  Widget _buildReviewScreen() {
    final pickupPoint = _driverPickup
        ? (_customPickupLatLng ?? widget.userLocation)
        : widget.pickup;
    final pickupAddress = _driverPickup
        ? (_customPickupAddress ?? widget.pickupAddress)
        : widget.pickupAddress;
    final isBike = _selectedVehicle == VehicleType.bike;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final minSize = (390 / screenHeight).clamp(0.44, 0.68).toDouble();
    final initialSize = (minSize + 0.08).clamp(0.52, 0.74).toDouble();
    final maxSize = (initialSize + 0.14).clamp(0.68, 0.88).toDouble();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: AppColors.blue,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 72,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: InkWell(
                              onTap: () => setState(() => _isReviewing = false),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.blueDark,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ពិនិត្យការដឹកជញ្ជូន',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'ពិនិត្យព័ត៌មានទាំងអស់មុនពេលបញ្ជាក់',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(
                                isBike
                                    ? 'assets/images/motorbike_topview.png'
                                    : 'assets/images/rickshaw_topview.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Icon(
                                  isBike
                                      ? Icons.two_wheeler_rounded
                                      : Icons.electric_rickshaw_rounded,
                                  color: AppColors.blue,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CustomerMapPicker(
                  mapController: _reviewMapController,
                  pickupLocation: pickupPoint,
                  dropoffLocation: widget.dropoff,
                  routePoints: widget.routePoints,
                  onMapReady: _fitReviewRoute,
                ),
              ),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: initialSize,
            minChildSize: minSize,
            maxChildSize: maxSize,
            snap: true,
            snapSizes: [minSize, initialSize, maxSize],
            builder: (context, scrollController) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.customerContentMaxWidth,
                  ),
                  child: Material(
                    color: Colors.white,
                    elevation: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CustomScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.sm,
                              AppSpacing.lg,
                              MediaQuery.paddingOf(context).bottom +
                                  AppSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppColors.line,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'សេចក្ដីសង្ខេបការដឹកជញ្ជូន',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _isReviewing = false),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: const Text('កែប្រែ'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _ReviewRouteRow(
                                  icon: Icons.location_on_rounded,
                                  color: AppColors.danger,
                                  label: 'ទីតាំងទទួលទំនិញ',
                                  value: pickupAddress,
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 9),
                                  child: SizedBox(
                                    height: 10,
                                    child: VerticalDivider(
                                      width: 2,
                                      thickness: 1.5,
                                      color: AppColors.line,
                                    ),
                                  ),
                                ),
                                _ReviewRouteRow(
                                  icon: Icons.trip_origin_rounded,
                                  color: AppColors.success,
                                  label: 'ទីតាំងប្រគល់ទំនិញ',
                                  value: widget.dropoffAddress,
                                ),
                                const Divider(height: AppSpacing.lg),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _ReviewInfoCell(
                                        label: 'អ្នកទទួល',
                                        value: _contactNameController.text
                                            .trim(),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: _ReviewInfoCell(
                                        label: 'លេខទូរសព្ទ',
                                        value: _contactPhoneController.text
                                            .trim(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _ReviewInfoCell(
                                        label: 'កញ្ចប់ទំនិញ',
                                        value: _itemNameController.text.trim(),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: _ReviewInfoCell(
                                        label: 'ចំនួន និងទម្ងន់',
                                        value:
                                            '${_quantityController.text.trim()} កញ្ចប់ · '
                                            '${_weightController.text.trim()} គីឡូក្រាម',
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'តម្លៃប៉ាន់ស្មាន',
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            '${_totalPrice.toInt()}៛',
                                            style: const TextStyle(
                                              color: AppColors.blueDark,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.softBlue,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        '${isBike ? 'ម៉ូតូ' : 'ម៉ូតូកង់បី'} · '
                                        '${_selectedPayment == PaymentMethod.cash ? 'សាច់ប្រាក់' : 'អនឡាញ'}',
                                        style: const TextStyle(
                                          color: AppColors.blueDark,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                FilledButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _submitBooking,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    backgroundColor: AppColors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'បញ្ជាក់ និងស្វែងរកអ្នកបើកបរ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary({
    required VoidCallback onPressed,
    required String buttonLabel,
  }) {
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
                      "ចំនួនទឹកប្រាក់សរុប",
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
                          ? "កំពុងគណនាតម្លៃតាមចម្ងាយផ្លូវ…"
                          : _quoteError ??
                                (_quote == null
                                    ? "តម្លៃប៉ាន់ស្មាន"
                                    : "${_quote!.distanceKm.toStringAsFixed(1)} គីឡូម៉ែត្រ • "
                                          "ប្រហែល ${(_quote!.durationSeconds / 60).ceil()} នាទី"),
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
                  onPressed: _isSubmitting || _quoteLoading ? null : onPressed,
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
                              ? "គណនាតម្លៃម្ដងទៀត"
                              : buttonLabel,
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

  Future<void> _openReview() async {
    if (_quoteError != null) {
      await _refreshQuote();
      return;
    }
    if (!_validateInputs()) return;
    setState(() => _isReviewing = true);
  }

  void _fitReviewRoute() {
    if (widget.routePoints.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reviewMapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([
            ...widget.routePoints,
            widget.pickup,
            widget.dropoff,
          ]),
          padding: const EdgeInsets.fromLTRB(36, 110, 36, 360),
        ),
      );
    });
  }

  bool _validateInputs() {
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
            "សូមបញ្ចូលឈ្មោះទំនិញ ទម្ងន់ត្រឹមត្រូវ និងព័ត៌មានទំនាក់ទំនងអ្នកទទួល។",
          ),
        ),
      );
      return false;
    }
    final maxWeight = _selectedVehicle == VehicleType.bike ? 20.0 : 150.0;
    final maxQuantity = _selectedVehicle == VehicleType.bike ? 5 : 30;
    if (weight > maxWeight || quantity > maxQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${_selectedVehicle == VehicleType.bike ? 'ម៉ូតូ' : 'ម៉ូតូកង់បី'} "
            "អាចដឹកបានរហូតដល់ ${maxWeight.toInt()} គីឡូក្រាម និង $maxQuantity កញ្ចប់។",
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _submitBooking() async {
    if (!_validateInputs()) {
      setState(() => _isReviewing = false);
      return;
    }

    final itemName = _itemNameController.text.trim();
    final contactName = _contactNameController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();
    final weight = double.parse(_weightController.text.trim());
    final quantity = int.parse(_quantityController.text.trim());

    setState(() => _isSubmitting = true);
    try {
      final order = CustomerOrder(
        id: "ORDER-${DateTime.now().millisecondsSinceEpoch}",
        pickup: _driverPickup
            ? (_customPickupLatLng ?? widget.userLocation)
            : widget.pickup,
        dropoff: widget.dropoff,
        pickupAddress: _driverPickup
            ? (_customPickupAddress ?? widget.pickupAddress)
            : widget.pickupAddress,
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
}

class _ReviewRouteRow extends StatelessWidget {
  const _ReviewRouteRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewInfoCell extends StatelessWidget {
  const _ReviewInfoCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? 'មិនបានបញ្ចូល' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
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
      showCheckmark: false,
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
