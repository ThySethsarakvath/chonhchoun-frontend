import 'package:flutter/material.dart';
import '../../shared/colors/app_colors.dart';
import '../../shared/models/order.dart';
import '../../shared/widgets/app_shell_widgets.dart';
import 'screens/customer_booking_screen.dart';
import 'tabs/customer_home_tab.dart';
import 'tabs/customer_orders_tab.dart';
import 'tabs/customer_profile_tab.dart';

class CustomerWorkspaceScreen extends StatefulWidget {
  const CustomerWorkspaceScreen({super.key});

  @override
  State<CustomerWorkspaceScreen> createState() => _CustomerWorkspaceScreenState();
}

class _CustomerWorkspaceScreenState extends State<CustomerWorkspaceScreen> {
  int _selectedIndex = 0;
  final List<CustomerOrder> _orders = [];

  void _addOrder(CustomerOrder order) {
    setState(() {
      _orders.insert(0, order); // Add to top
    });
  }

  void _openBooking(DeliveryServiceType serviceType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerBookingScreen(
          onOrderCreated: _addOrder,
          serviceType: serviceType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CustomerHomeTab(
            onStartBooking: _openBooking,
            activeOrder: _orders.isNotEmpty ? _orders.first : null,
          ),
          CustomerOrdersTab(orders: _orders),
          const CustomerProfileTab(),
        ],
      ),
      bottomNavigationBar: CustomerBottomBar(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
