import 'package:flutter/material.dart';
import 'models/customer_order.dart';
import 'screens/customer_booking_screen.dart';
import 'tabs/customer_home_tab.dart';
import 'tabs/customer_orders_tab.dart';
import 'tabs/customer_profile_tab.dart';
import 'widgets/customer_colors.dart';
import 'widgets/customer_shell_widgets.dart';

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

  void _openBooking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerBookingScreen(
          onOrderCreated: _addOrder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerColors.surface,
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
