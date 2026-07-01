import 'package:flutter/material.dart';

import '../../../features/branch_logistics/models/branch_logistics_models.dart';
import '../../../features/branch_logistics/services/branch_logistics_service.dart';
import '../widgets/driver_colors.dart';

class DriverBranchLogisticsTab extends StatefulWidget {
  const DriverBranchLogisticsTab({super.key});

  @override
  State<DriverBranchLogisticsTab> createState() =>
      _DriverBranchLogisticsTabState();
}

class _DriverBranchLogisticsTabState extends State<DriverBranchLogisticsTab> {
  final BranchLogisticsService _service = BranchLogisticsService();

  List<BranchLogisticsShipment> _shipments = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final shipments = await _service.listDriverAssignedShipments();
      if (!mounted) return;
      setState(() {
        _shipments = shipments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _updateGroupStatus(
    List<BranchLogisticsShipment> shipments,
    String action,
    String successLabel,
  ) async {
    try {
      for (final shipment in shipments) {
        await _service.updateDriverShipmentStatus(
          shipmentId: shipment.id,
          action: action,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successLabel for ${shipments.length} package ticket(s).'),
        ),
      );
      await _loadShipments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: DriverColors.blue),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: DriverColors.muted),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadShipments,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_shipments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadShipments,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Icon(
              Icons.local_shipping_outlined,
              size: 56,
              color: DriverColors.muted,
            ),
            SizedBox(height: 12),
            Text(
              'No assigned branch logistics task yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DriverColors.text,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShipments,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Assigned Branch Logistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: DriverColors.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'See each truck trip, then update all loaded packages together from collect to arrive.',
            style: TextStyle(color: DriverColors.muted),
          ),
          const SizedBox(height: 18),
          ..._buildTripGroups().map(_tripGroupCard),
        ],
      ),
    );
  }

  List<_DriverTripGroup> _buildTripGroups() {
    final grouped = <String, List<BranchLogisticsShipment>>{};
    for (final shipment in _shipments) {
      final vehicleId = shipment.assignedVehicle?.id ?? 'no-vehicle';
      final destinationId = shipment.receiverBranch?.id ?? 'no-destination';
      final status = shipment.status;
      final key = '$vehicleId|$destinationId|$status';
      grouped.putIfAbsent(key, () => <BranchLogisticsShipment>[]).add(shipment);
    }

    return grouped.entries.map((entry) {
      final shipments = entry.value;
      shipments.sort((a, b) => a.ticketNumber.compareTo(b.ticketNumber));
      return _DriverTripGroup(
        shipments: shipments,
      );
    }).toList(growable: false);
  }

  Widget _tripGroupCard(_DriverTripGroup group) {
    final shipments = group.shipments;
    final lead = shipments.first;
    final totalPieces = shipments.fold<int>(0, (sum, item) => sum + _packageCount(item));
    final totalWeight = shipments.fold<double>(0, (sum, item) => sum + (item.weightKg ?? 0));
    final action = _groupActionForStatus(lead.status);
    final stockIds = shipments
        .map((shipment) => _stockIdLabel(shipment.notes))
        .where((stockId) => stockId != '-')
        .toSet()
        .toList(growable: false);
    final ownerNote = _tripOwnerNote(lead.notes);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lead.assignedVehicle?.code ?? 'Assigned Vehicle'} | ${lead.receiverBranch?.name ?? '-'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DriverColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shipments.length} ticket(s) | $totalPieces pieces | ${_weightLabel(totalWeight)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: DriverColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(_statusLabel(lead.status)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _groupHelperText(lead.status),
            style: const TextStyle(
              fontSize: 13,
              color: DriverColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          _detailLine('Route', '${lead.senderBranch?.name ?? '-'} -> ${lead.receiverBranch?.name ?? '-'}'),
          _detailLine('Vehicle', lead.assignedVehicle?.code ?? '-'),
          _detailLine('Assigned time', _dateLabel(lead.assignedAt)),
          _detailLine('Package IDs', stockIds.isEmpty ? '-' : stockIds.join(', ')),
          _detailLine('Load', '$totalPieces pieces | ${_weightLabel(totalWeight)}'),
          if (ownerNote != null && ownerNote.isNotEmpty)
            _detailLine('Owner note', ownerNote),
          if (action != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => _updateGroupStatus(
                shipments,
                action.apiAction,
                action.successLabel,
              ),
              child: Text('${action.buttonLabel} All (${shipments.length})'),
            ),
          ],
          const SizedBox(height: 14),
          ...shipments.map((shipment) => _shipmentRow(shipment)),
        ],
      ),
    );
  }

  Widget _shipmentRow(BranchLogisticsShipment shipment) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shipment.ticketNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DriverColors.text,
                  ),
                ),
              ),
              Text(
                _statusLabel(shipment.status),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DriverColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            shipment.itemDescription,
            style: const TextStyle(
              fontSize: 13,
              color: DriverColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          _detailLine('Package ID', _stockIdLabel(shipment.notes)),
          _detailLine(
            'Package',
            _packageCountLabel(shipment.notes),
          ),
          _detailLine(
            'Weight',
            _weightLabel(shipment.weightKg ?? 0),
          ),
        ],
      ),
    );
  }

  _DriverGroupAction? _groupActionForStatus(String status) {
    switch (status) {
      case 'ASSIGNED':
      case 'CREATED':
        return const _DriverGroupAction(
          apiAction: 'collect',
          successLabel: 'Collected from branch',
          buttonLabel: 'Collect from Branch',
        );
      case 'RECEIVED_AT_SENDER_WAREHOUSE':
        return const _DriverGroupAction(
          apiAction: 'deliver',
          successLabel: 'Delivering started',
          buttonLabel: 'Deliver Halfway',
        );
      case 'IN_TRANSIT':
        return const _DriverGroupAction(
          apiAction: 'arrive',
          successLabel: 'Arrived at branch',
          buttonLabel: 'Arrived at Branch',
        );
      default:
        return null;
    }
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DriverColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: DriverColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1D4ED8),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'CREATED':
        return 'Waiting for Driver';
      case 'ASSIGNED':
        return 'Assigned to Driver';
      case 'RECEIVED_AT_SENDER_WAREHOUSE':
        return 'Collected from Branch';
      case 'IN_TRANSIT':
        return 'Delivering';
      case 'RECEIVED_AT_RECEIVER_WAREHOUSE':
        return 'Arrived at Branch';
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }

  String _stockIdLabel(String? notes) {
    final match = RegExp(r'Stock ID:\s*([A-Z0-9\-]+)', caseSensitive: false)
        .firstMatch(notes ?? '');
    return match?.group(1) ?? '-';
  }

  String _packageCountLabel(String? notes) {
    final match = RegExp(r'Package stock:\s*(\d+)', caseSensitive: false)
        .firstMatch(notes ?? '');
    if (match == null) return '-';
    return '${match.group(1)} pieces';
  }

  String? _tripOwnerNote(String? notes) {
    final match = RegExp(r'Owner note:\s*(.+)', caseSensitive: false)
        .firstMatch(notes ?? '');
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  int _packageCount(BranchLogisticsShipment shipment) {
    final match = RegExp(r'Package stock:\s*(\d+)', caseSensitive: false)
        .firstMatch(shipment.notes ?? '');
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  String _groupHelperText(String status) {
    switch (status) {
      case 'ASSIGNED':
      case 'CREATED':
        return 'All packages below are already in the same assigned trip. Tap once when you collect the whole group from the branch.';
      case 'RECEIVED_AT_SENDER_WAREHOUSE':
        return 'The whole trip is collected. Tap once when this same vehicle leaves for branch delivery.';
      case 'IN_TRANSIT':
        return 'The whole trip is on the way. Tap once when this vehicle arrives at the destination branch.';
      case 'RECEIVED_AT_RECEIVER_WAREHOUSE':
        return 'This trip already reached the branch and is waiting for pickup handling.';
      case 'READY_FOR_PICKUP':
        return 'This trip is ready for pickup.';
      default:
        return 'Review your assigned branch logistics tickets here.';
    }
  }

  String _weightLabel(double value) {
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} kg';
  }

  String _dateLabel(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _DriverTripGroup {
  final List<BranchLogisticsShipment> shipments;

  const _DriverTripGroup({
    required this.shipments,
  });
}

class _DriverGroupAction {
  final String apiAction;
  final String successLabel;
  final String buttonLabel;

  const _DriverGroupAction({
    required this.apiAction,
    required this.successLabel,
    required this.buttonLabel,
  });
}
