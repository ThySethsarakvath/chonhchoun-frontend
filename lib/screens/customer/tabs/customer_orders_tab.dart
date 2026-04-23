import 'package:flutter/material.dart';
import '../models/customer_order.dart';
import '../widgets/customer_colors.dart';
import '../../driver/widgets/driver_shell_widgets.dart';
import '../screens/customer_order_detail_screen.dart';

class CustomerOrdersTab extends StatelessWidget {
  const CustomerOrdersTab({super.key, required this.orders});

  final List<CustomerOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerColors.surface,
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: CustomerColors.text,
        elevation: 0,
        centerTitle: true,
      ),
      body: orders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerOrderDetailScreen(order: order),
                      ),
                    );
                  },
                  child: _buildOrderCard(order),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: CustomerColors.muted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            "No orders yet",
            style: TextStyle(fontSize: 18, color: CustomerColors.muted, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(CustomerOrder order) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DriverSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.itemName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CustomerColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusText,
                    style: const TextStyle(color: CustomerColors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildLocationRow(Icons.circle_outlined, CustomerColors.blue, "Pickup Location"),
            _buildConnector(),
            _buildLocationRow(Icons.location_on, CustomerColors.danger, "Drop-off Location"),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Created on ${order.createdAt.toString().split(' ')[0]}",
                  style: const TextStyle(color: CustomerColors.muted, fontSize: 12),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: CustomerColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: CustomerColors.text, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 2,
          height: 10,
          color: CustomerColors.line,
        ),
      ),
    );
  }
}
