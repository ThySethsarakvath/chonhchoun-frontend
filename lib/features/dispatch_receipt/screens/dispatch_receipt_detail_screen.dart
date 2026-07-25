import 'dart:async';

import 'package:flutter/material.dart';
import '../models/dispatch_receipt_models.dart';
import '../services/dispatch_receipt_service.dart';
import '../widgets/optimized_dispatch_map.dart';
import 'confirm_stop_screen.dart';

class DispatchReceiptDetailScreen extends StatefulWidget {
  final String receiptId;
  final bool isInbound;

  const DispatchReceiptDetailScreen({
    super.key,
    required this.receiptId,
    required this.isInbound,
  });

  @override
  State<DispatchReceiptDetailScreen> createState() =>
      _DispatchReceiptDetailScreenState();
}

class _DispatchReceiptDetailScreenState
    extends State<DispatchReceiptDetailScreen> {
  final _service = DispatchReceiptService();
  DispatchReceipt? _receipt;
  bool _loading = true;
  bool _arrivalUpdateInProgress = false;
  bool _startingSimulation = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_receipt?.status == DispatchReceiptStatus.inTransit) {
        if (_receipt?.isOptimized == true) {
          _syncSimulation();
        } else {
          _loadReceipt(showLoading: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReceipt({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final receipt = await _service.getReceipt(widget.receiptId);
      if (mounted) setState(() => _receipt = receipt);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted && showLoading) setState(() => _loading = false);
    }
  }

  Future<void> _syncSimulation() async {
    try {
      final receipt = await _service.syncSimulation(widget.receiptId);
      if (mounted) setState(() => _receipt = receipt);
    } catch (_) {
      await _loadReceipt(showLoading: false);
    }
  }

  Future<void> _departReceipt() async {
    try {
      await _service.departReceipt(widget.receiptId);
      _loadReceipt();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cancelReceipt() async {
    try {
      await _service.cancelReceipt(widget.receiptId);
      _loadReceipt();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _simulateArrival(int stopOrder) async {
    try {
      await _service.simulateArrival(widget.receiptId, stopOrder);
      _loadReceipt();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _startSimulation() async {
    setState(() => _startingSimulation = true);
    try {
      final receipt = await _service.startSimulation(widget.receiptId);
      if (mounted) setState(() => _receipt = receipt);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to start simulation: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _startingSimulation = false);
    }
  }

  Future<void> _handleStopReached(int stopOrder) async {
    if (widget.isInbound || _arrivalUpdateInProgress) return;
    final receipt = _receipt;
    if (receipt == null) return;
    final pendingStops =
        receipt.stops
            .where((stop) => stop.status == DispatchReceiptStopStatus.pending)
            .toList()
          ..sort((left, right) => left.stopOrder.compareTo(right.stopOrder));
    if (pendingStops.isEmpty || pendingStops.first.stopOrder != stopOrder) {
      return;
    }

    _arrivalUpdateInProgress = true;
    try {
      final updated = await _service.simulateArrival(
        widget.receiptId,
        stopOrder,
      );
      if (mounted) setState(() => _receipt = updated);
    } catch (_) {
      await _loadReceipt(showLoading: false);
    } finally {
      _arrivalUpdateInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _receipt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receipt Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final r = _receipt!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mapHeight = screenWidth >= 1200
        ? 680.0
        : screenWidth >= 800
        ? 560.0
        : 440.0;

    return Scaffold(
      appBar: AppBar(title: Text(r.receiptNumber)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(r),
          if (r.isOptimized) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: mapHeight,
              child: OptimizedDispatchMap(
                receipt: r,
                onStopReached: widget.isInbound ? null : _handleStopReached,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The animation is a shared time-based simulation, not live GPS.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Stops Timeline',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...r.stops.map((stop) => _buildStopCard(r, stop)),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(r),
    );
  }

  Widget _buildInfoCard(DispatchReceipt r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${r.status.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Driver: ${r.driver.name}'),
            Text('Source: ${r.sourceBranch.name}'),
            if (r.isOptimized) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  Text(
                    'Distance: ${((r.totalDistanceMeters ?? 0) / 1000).toStringAsFixed(1)} km',
                  ),
                  Text(
                    'Estimated: ${((r.estimatedDurationSeconds ?? 0) / 60).round()} min',
                  ),
                  Text('Load: ${r.totalWeightKg.toStringAsFixed(1)} kg'),
                ],
              ),
            ],
            if (r.notes != null) ...[
              const SizedBox(height: 8),
              Text('Notes: ${r.notes}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStopCard(DispatchReceipt r, DispatchReceiptStop stop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stop ${stop.stopOrder}: ${stop.destinationBranch.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(label: Text(stop.status.name)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Packages: ${stop.shipments.length}'),
            if (stop.missingShipments.isNotEmpty)
              Text(
                'Missing: ${stop.missingShipments.length}',
                style: const TextStyle(color: Colors.red),
              ),
            if (stop.damagedShipments.isNotEmpty)
              Text(
                'Damaged: ${stop.damagedShipments.length}',
                style: const TextStyle(color: Colors.orange),
              ),

            // Actions for the stop
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!widget.isInbound &&
                    r.status == DispatchReceiptStatus.inTransit &&
                    stop.status == DispatchReceiptStopStatus.pending &&
                    !r.isOptimized)
                  ElevatedButton(
                    onPressed: () => _simulateArrival(stop.stopOrder),
                    child: const Text('Simulate Arrival'),
                  ),
                if (widget.isInbound &&
                    stop.status == DispatchReceiptStopStatus.arrived)
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ConfirmStopScreen(receiptId: r.id, stop: stop),
                        ),
                      );
                      if (result == true) _loadReceipt();
                    },
                    child: const Text('Confirm Receipt'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomActions(DispatchReceipt r) {
    if (widget.isInbound) return null;

    if (r.status == DispatchReceiptStatus.created) {
      return BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: _cancelReceipt,
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: _departReceipt,
              child: const Text('Depart'),
            ),
          ],
        ),
      );
    }
    if (r.status == DispatchReceiptStatus.inTransit &&
        r.isOptimized &&
        r.simulationStartedAt == null) {
      return BottomAppBar(
        child: FilledButton.icon(
          onPressed: _startingSimulation ? null : _startSimulation,
          icon: _startingSimulation
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(
            _startingSimulation
                ? 'Starting simulation…'
                : 'Start route simulation',
          ),
        ),
      );
    }
    return null;
  }
}
