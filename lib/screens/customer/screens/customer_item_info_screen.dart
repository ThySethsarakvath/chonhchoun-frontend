import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../shared/colors/app_colors.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/app_shell_widgets.dart';

class CustomerItemInfoScreen extends StatefulWidget {
  const CustomerItemInfoScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.serviceType,
    required this.onOrderCreated,
  });

  final LatLng pickup;
  final LatLng dropoff;
  final String pickupAddress;
  final String dropoffAddress;
  final DeliveryServiceType serviceType;
  final Function(CustomerOrder) onOrderCreated;

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
  final TextEditingController _weightController = TextEditingController(text: "1");
  final TextEditingController _itemNameController = TextEditingController();

  double get _totalPrice {
    double base = widget.serviceType == DeliveryServiceType.express ? 8200.0 : 3500.0;
    if (_selectedVehicle == VehicleType.tuktuk) {
      base += 2000.0;
    }
    if (_itemHandling) {
      base += 2000.0;
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text("Complete Booking", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildRouteCard(),
            const SizedBox(height: 16),
            _buildItemSpecsCard(),
            if (widget.serviceType == DeliveryServiceType.express) ...[
              const SizedBox(height: 16),
              _buildVehicleCard(),
            ],
            const SizedBox(height: 16),
            _buildAddonsCard(),
            const SizedBox(height: 16),
            _buildPaymentCard(),
            const SizedBox(height: 24),
          ],
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
            const Text("Item Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _itemNameController,
              decoration: InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Size *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _SizeChip("S", isSelected: _selectedSize == ItemSize.S, onTap: () => setState(() => _selectedSize = ItemSize.S)),
                          const SizedBox(width: 8),
                          _SizeChip("M", isSelected: _selectedSize == ItemSize.M, onTap: () => setState(() => _selectedSize = ItemSize.M)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Weight (kg) *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Item Type *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TypeChip("Document", Icons.description, _selectedType == ItemType.document, () => setState(() => _selectedType = ItemType.document)),
                _TypeChip("Food", Icons.restaurant, _selectedType == ItemType.food, () => setState(() => _selectedType = ItemType.food)),
                _TypeChip("Clothing", Icons.checkroom, _selectedType == ItemType.clothing, () => setState(() => _selectedType = ItemType.clothing)),
                _TypeChip("Electronics", Icons.memory, _selectedType == ItemType.electronics, () => setState(() => _selectedType = ItemType.electronics)),
                _TypeChip("Others", Icons.more_horiz, _selectedType == ItemType.others, () => setState(() => _selectedType = ItemType.others)),
              ],
            ),
            const SizedBox(height: 24),
            // RESTORED PHOTO UPLOAD
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: CustomPaint(
                painter: _DottedPainter(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.blue),
                    SizedBox(width: 12),
                    Text("Add photo (optional)", style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500)),
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
            const Text("Select Vehicle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _VehicleTile(
              icon: Icons.motorcycle,
              title: "Bike",
              price: "8,200៛",
              isSelected: _selectedVehicle == VehicleType.bike,
              onTap: () => setState(() => _selectedVehicle = VehicleType.bike),
            ),
            const SizedBox(height: 8),
            _VehicleTile(
              icon: Icons.electric_rickshaw,
              title: "Tuktuk",
              price: "10,200៛",
              isSelected: _selectedVehicle == VehicleType.tuktuk,
              onTap: () => setState(() => _selectedVehicle = VehicleType.tuktuk),
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
            const Text("Add-ons", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _itemHandling = !_itemHandling),
              child: Row(
                children: [
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: _itemHandling ? AppColors.blue : Colors.transparent,
                      border: Border.all(color: _itemHandling ? AppColors.blue : AppColors.line),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _itemHandling ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Extra Item Handling", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("Careful handling for fragile items", style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Text("+2,000៛", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue)),
                ],
              ),
            ),
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
            const Text("Payment & Offers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaymentBtn(
                  widget.serviceType == DeliveryServiceType.express ? "Cash" : "Sender Pay", 
                  _selectedPayment == PaymentMethod.cash, 
                  () => setState(() => _selectedPayment = PaymentMethod.cash)
                ),
                const SizedBox(width: 8),
                _PaymentBtn(
                  widget.serviceType == DeliveryServiceType.express ? "Online" : "Receiver Pay", 
                  _selectedPayment == PaymentMethod.online, 
                  () => setState(() => _selectedPayment = PaymentMethod.online)
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
                  Text("Apply Promo Code", style: TextStyle(fontWeight: FontWeight.w500)),
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
        content: const TextField(decoration: InputDecoration(hintText: "Enter code here")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Apply")),
        ],
      ),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Payable", style: TextStyle(fontSize: 16, color: AppColors.muted)),
              Text("${_totalPrice.toInt()}៛", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.blueDark)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              try {
                final order = CustomerOrder(
                  id: "ORDER-${DateTime.now().millisecondsSinceEpoch}",
                  pickup: widget.pickup,
                  dropoff: widget.dropoff,
                  pickupAddress: widget.pickupAddress,
                  dropoffAddress: widget.dropoffAddress,
                  itemName: _itemNameController.text.trim().isEmpty ? "កញ្ចប់អីវ៉ាន់" : _itemNameController.text.trim(),
                  size: _selectedSize,
                  weight: double.tryParse(_weightController.text) ?? 1.0,
                  itemType: _selectedType,
                  vehicleType: _selectedVehicle,
                  paymentMethod: _selectedPayment,
                  serviceType: widget.serviceType,
                  itemHandling: _itemHandling,
                  status: OrderStatus.searching,
                  createdAt: DateTime.now(),
                  price: _totalPrice,
                );
                
                widget.onOrderCreated(order);
                
                // Navigate back to the very first screen (Home)
                Navigator.of(context).popUntil((route) => route.isFirst);
              } catch (e) {
                debugPrint("Booking Error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error creating order: $e")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text("Confirm & Book Now", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.icon, required this.color, required this.label, required this.value});
  final IconData icon;
  final Color color;
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
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
        height: 36, width: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue : Colors.white,
          border: Border.all(color: isSelected ? AppColors.blue : AppColors.line),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.text, fontWeight: FontWeight.bold)),
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
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.text, fontSize: 12)),
      selected: isSelected,
      onSelected: (v) => onTap(),
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.blue),
      selectedColor: AppColors.blue,
      backgroundColor: Colors.white,
      padding: EdgeInsets.zero,
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.icon, required this.title, required this.price, required this.isSelected, required this.onTap});
  final IconData icon;
  final String title, price;
  final bool isSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue.withValues(alpha: 0.05) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.blue : AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.blue : AppColors.muted),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
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
          backgroundColor: isSelected ? AppColors.blue : Colors.white,
          foregroundColor: isSelected ? Colors.white : AppColors.text,
          elevation: 0,
          side: BorderSide(color: isSelected ? AppColors.blue : AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label),
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
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));
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
