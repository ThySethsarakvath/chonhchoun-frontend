import 'package:flutter/material.dart';
import '../models/dispatch_receipt_models.dart';
import '../services/dispatch_receipt_service.dart';
import '../widgets/auto_plan_progress_dialog.dart';
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
  bool _refreshing = false;
  bool _autoPlanning = false;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading receipts: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshData() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to refresh receipts: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
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

  Future<void> _runAutoPlan() async {
    var durationSeconds = 120;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Optimize branch dispatch'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The planner will group all unassigned shipments by destination, select available company truck drivers, and create the fewest practical multi-stop receipts.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: durationSeconds,
                  decoration: const InputDecoration(
                    labelText: 'Map simulation duration',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 60, child: Text('1 minute')),
                    DropdownMenuItem(value: 120, child: Text('2 minutes')),
                    DropdownMenuItem(value: 180, child: Text('3 minutes')),
                    DropdownMenuItem(value: 300, child: Text('5 minutes')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => durationSeconds = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Create optimized receipts'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _autoPlanning = true);
    try {
      final result = await showDialog<AutoPlanDispatchResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AutoPlanProgressDialog(
          operation: () =>
              _service.autoPlan(simulationDurationSeconds: durationSeconds),
        ),
      );
      if (result == null || !mounted) return;
      await _loadData();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(
                result.unassignedShipments == 0
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                color: result.unassignedShipments == 0
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 10),
              const Text('Dispatch plan created'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${result.assignedShipments} shipments assigned'),
              Text(
                '${result.trucksUsed} of '
                '${result.availableTruckDrivers} available trucks used',
              ),
              if (result.unassignedShipments > 0)
                Text(
                  '${result.unassignedShipments} shipments remain unassigned',
                  style: const TextStyle(color: Colors.orange),
                ),
              const SizedBox(height: 12),
              ...result.receipts.map(
                (receipt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.route_rounded),
                  title: Text(receipt.receiptNumber),
                  subtitle: Text(
                    '${receipt.driver.name} • ${receipt.stops.length} stops',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _autoPlanning = false);
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
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 12,
          spacing: 12,
          children: [
            const Text(
              'Dispatch Receipts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _refreshing ? null : _refreshData,
                  icon: _refreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_refreshing ? 'Refreshing…' : 'Refresh'),
                ),
                OutlinedButton.icon(
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
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Manual receipt'),
                ),
                FilledButton.icon(
                  onPressed: _autoPlanning ? null : _runAutoPlan,
                  icon: _autoPlanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _autoPlanning ? 'Optimizing…' : 'Auto plan dispatch',
                  ),
                ),
              ],
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
                  title: Text(
                    r.receiptNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
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
