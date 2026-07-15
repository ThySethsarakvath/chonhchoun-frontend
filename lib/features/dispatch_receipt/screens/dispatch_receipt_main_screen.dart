import 'package:flutter/material.dart';
import '../models/dispatch_receipt_models.dart';
import '../services/dispatch_receipt_service.dart';
import 'create_dispatch_receipt_screen.dart';
import 'dispatch_receipt_detail_screen.dart';

class DispatchReceiptMainScreen extends StatefulWidget {
  const DispatchReceiptMainScreen({super.key});

  @override
  State<DispatchReceiptMainScreen> createState() =>
      _DispatchReceiptMainScreenState();
}

class _DispatchReceiptMainScreenState extends State<DispatchReceiptMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = DispatchReceiptService();

  List<DispatchReceipt> _outboundReceipts = [];
  List<DispatchReceipt> _inboundReceipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.listOutboundReceipts(),
        _service.listInboundReceipts(),
      ]);
      if (!mounted) return;
      setState(() {
        _outboundReceipts = results[0];
        _inboundReceipts = results[1];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading receipts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(DispatchReceipt receipt, bool isInbound) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DispatchReceiptDetailScreen(
          receiptId: receipt.id,
          isInbound: isInbound,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isOutbound = _tabController.index == 0;
    final activeReceipts = isOutbound ? _outboundReceipts : _inboundReceipts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dispatch Receipts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateDispatchReceiptScreen(),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Receipt'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorSize: TabBarIndicatorSize.tab,
            onTap: (index) => setState(() {}),
            tabs: const [
              Tab(text: 'Outbound'),
              Tab(text: 'Inbound'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (activeReceipts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('No receipts found.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeReceipts.length,
            itemBuilder: (context, index) {
              final r = activeReceipts[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(r.receiptNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Status: ${r.status.name.toUpperCase()}'),
                      const SizedBox(height: 4),
                      Text('Driver: ${r.driver.name}'),
                      const SizedBox(height: 4),
                      Text('Stops: ${r.stops.length}'),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _openDetail(r, !isOutbound),
                ),
              );
            },
          ),
      ],
    );
  }
}
