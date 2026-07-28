import 'package:flutter/material.dart';

import '../../admin_management/models/branch_model.dart';
import '../../branch_logistics/models/branch_logistics_models.dart';
import '../../branch_logistics/services/branch_logistics_service.dart';
import '../widgets/branch_owner_content_widgets.dart';

class BranchSalesScreen extends StatefulWidget {
  final Branch? ownedBranch;

  const BranchSalesScreen({
    super.key,
    required this.ownedBranch,
  });

  @override
  State<BranchSalesScreen> createState() => _BranchSalesScreenState();
}

class _BranchSalesScreenState extends State<BranchSalesScreen> {
  final BranchLogisticsService _logisticsService = BranchLogisticsService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _updating = false;
  String? _error;
  _PickupFilter _filter = _PickupFilter.notTaken;
  List<BranchLogisticsShipment> _shipments = const [];

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShipments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final shipments = await _logisticsService.listShipments(direction: 'all');
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

  List<BranchLogisticsShipment> get _branchInboundShipments {
    final branchId = widget.ownedBranch?.id;
    final inbound = branchId == null
        ? _shipments
        : _shipments.where((shipment) => shipment.isInboundFor(branchId));

    final sorted = inbound.toList()
      ..sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    return sorted;
  }

  List<BranchLogisticsShipment> get _filteredShipments {
    final query = _searchController.text.trim().toLowerCase();

    return _branchInboundShipments.where((shipment) {
      final statusMatch = switch (_filter) {
        _PickupFilter.all => true,
        _PickupFilter.awaiting => _isAwaitingBranchHandling(shipment),
        _PickupFilter.notTaken => _isNotTaken(shipment),
        _PickupFilter.taken => _isTaken(shipment),
      };
      if (!statusMatch) return false;

      if (query.isEmpty) return true;

      final haystack = <String>[
        shipment.ticketNumber,
        shipment.sender.name,
        shipment.receiver.name,
        shipment.itemDescription,
        shipment.status,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  int get _notTakenCount =>
      _branchInboundShipments.where(_isNotTaken).length;

  int get _takenTodayCount {
    final now = DateTime.now();
    return _branchInboundShipments.where((shipment) {
      if (!_isTaken(shipment)) return false;
      final date = shipment.paidAt ?? shipment.createdAt;
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  bool _isAwaitingBranchHandling(BranchLogisticsShipment shipment) {
    return shipment.status == 'CREATED' ||
        shipment.status == 'ASSIGNED' ||
        shipment.status == 'RECEIVED_AT_SENDER_WAREHOUSE' ||
        shipment.status == 'IN_TRANSIT';
  }

  bool _isNotTaken(BranchLogisticsShipment shipment) {
    return shipment.status == 'RECEIVED_AT_RECEIVER_WAREHOUSE' ||
        shipment.status == 'READY_FOR_PICKUP';
  }

  bool _isTaken(BranchLogisticsShipment shipment) {
    return shipment.status == 'COMPLETED';
  }

  String _pickupStateLabel(BranchLogisticsShipment shipment) {
    if (_isTaken(shipment)) return 'Taken';
    if (_isNotTaken(shipment)) return 'Not Taken';
    return 'Awaiting Arrival';
  }

  Color _pickupStateColor(BranchLogisticsShipment shipment) {
    if (_isTaken(shipment)) return const Color(0xFF15803D);
    if (_isNotTaken(shipment)) return const Color(0xFFB45309);
    return const Color(0xFF1D4ED8);
  }

  String _statusDetailLabel(BranchLogisticsShipment shipment) {
    switch (shipment.status) {
      case 'CREATED':
        return 'Ticket created';
      case 'ASSIGNED':
        return 'Assigned to branch driver';
      case 'RECEIVED_AT_SENDER_WAREHOUSE':
        return 'Received at sender branch';
      case 'IN_TRANSIT':
        return 'On the way to your branch';
      case 'RECEIVED_AT_RECEIVER_WAREHOUSE':
        return 'At your branch, waiting for pickup prep';
      case 'READY_FOR_PICKUP':
        return 'Waiting for customer pickup';
      case 'COMPLETED':
        return 'Package has been taken';
      default:
        return shipment.status.replaceAll('_', ' ');
    }
  }

  String _stockIdLabel(BranchLogisticsShipment shipment) {
    final notes = shipment.notes ?? '';
    final match =
        RegExp(r'Stock ID:\s*([A-Z0-9\-]+)', caseSensitive: false)
            .firstMatch(notes);
    return match?.group(1) ?? '-';
  }

  String _serviceLevelLabel(BranchLogisticsShipment shipment) {
    return shipment.pricingMode == BranchLogisticsPricingMode.vip
        ? 'VIP Same Day'
        : 'Standard 1-3 Days';
  }

  Future<void> _markShipmentAction(
    BranchLogisticsShipment shipment,
    String action,
    String successLabel,
  ) async {
    setState(() => _updating = true);
    try {
      await _logisticsService.updateShipmentStatus(
        shipmentId: shipment.id,
        action: action,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successLabel for ${shipment.ticketNumber}.')),
      );
      await _loadShipments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  Future<void> _showShipmentDetails(BranchLogisticsShipment shipment) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shipment.ticketNumber),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Pickup state', _pickupStateLabel(shipment)),
              _detailRow('Status', _statusDetailLabel(shipment)),
              _detailRow(
                'Sender',
                '${shipment.sender.name} | ${shipment.sender.phone}',
              ),
              _detailRow(
                'Receiver',
                '${shipment.receiver.name} | ${shipment.receiver.phone}',
              ),
              _detailRow('Stock batch', shipment.itemDescription),
              _detailRow('Package ID', _stockIdLabel(shipment)),
              _detailRow('Service', _serviceLevelLabel(shipment)),
              _detailRow('Weight', _weightLabel(shipment)),
              _detailRow(
                'Assigned driver',
                shipment.assignedDriver?.name ?? 'Auto-assignment pending',
              ),
              _detailRow(
                'Vehicle',
                shipment.assignedVehicle?.code ?? 'No vehicle yet',
              ),
              _detailRow('Created', _dateTimeLabel(shipment.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionHero(
          title: 'Package Pickup Management',
          description:
              'Track incoming branch packages in one simple list, see whether each package has been taken, and update pickup status with one clear next step.',
          icon: Icons.inventory_2_rounded,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            BranchOwnerStatCard(
              label: 'Incoming Packages',
              value: '${_branchInboundShipments.length}',
              icon: Icons.inbox_rounded,
              color: const Color(0xFF1D4ED8),
            ),
            BranchOwnerStatCard(
              label: 'Not Taken',
              value: '$_notTakenCount',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFB45309),
            ),
            BranchOwnerStatCard(
              label: 'Taken Today',
              value: '$_takenTodayCount',
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF15803D),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup List',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Use the filters to focus on packages waiting at this branch, then mark each package ready or taken.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _loading || _updating ? null : _loadShipments,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by ticket, sender, receiver, or package',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _filterChip(_PickupFilter.all, 'All'),
                  _filterChip(_PickupFilter.awaiting, 'Awaiting'),
                  _filterChip(_PickupFilter.notTaken, 'Not Taken'),
                  _filterChip(_PickupFilter.taken, 'Taken'),
                ],
              ),
              const SizedBox(height: 18),
              if (_loading)
                const BranchOwnerLoadingCard(
                  message: 'Loading package pickup list...',
                )
              else if (_error != null)
                BranchOwnerMessageCard(
                  title: 'Unable to load packages',
                  description: _error!,
                  actionLabel: 'Try again',
                  onAction: _loadShipments,
                )
              else if (_filteredShipments.isEmpty)
                BranchOwnerMessageCard(
                  title: 'No packages in this view',
                  description: _filter == _PickupFilter.notTaken
                      ? 'There are no packages currently waiting to be taken from this branch.'
                      : 'Try another filter or search term to find a package.',
                )
              else
                ..._filteredShipments.map(_shipmentCard),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(_PickupFilter filter, String label) {
    final selected = _filter == filter;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E3A5F) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFF1E3A5F)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _shipmentCard(BranchLogisticsShipment shipment) {
    final stateColor = _pickupStateColor(shipment);
    final actionButton = _buildActionButton(shipment);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.ticketNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shipment.itemDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _pickupStateLabel(shipment),
                  style: TextStyle(
                    color: stateColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _infoPill(Icons.local_offer_outlined, _serviceLevelLabel(shipment)),
              _infoPill(Icons.person_outline_rounded, shipment.sender.name),
              _infoPill(
                Icons.inventory_outlined,
                _statusDetailLabel(shipment),
              ),
              _infoPill(Icons.scale_rounded, _weightLabel(shipment)),
              _infoPill(
                Icons.schedule_rounded,
                _dateTimeLabel(shipment.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Package ID: ${_stockIdLabel(shipment)}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Receiver: ${shipment.receiver.name} | ${shipment.receiver.phone}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Assigned driver: ${shipment.assignedDriver?.name ?? 'Pending assignment'}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _showShipmentDetails(shipment),
                child: const Text('View Details'),
              ),
              if (actionButton != null) ...[
                const SizedBox(width: 10),
                actionButton,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildActionButton(BranchLogisticsShipment shipment) {
    if (_updating) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (shipment.status == 'RECEIVED_AT_RECEIVER_WAREHOUSE') {
      return FilledButton(
        onPressed: () => _markShipmentAction(
          shipment,
          'ready',
          'Package marked ready',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFB45309),
        ),
        child: const Text('Mark Ready'),
      );
    }

    if (shipment.status == 'READY_FOR_PICKUP') {
      return FilledButton(
        onPressed: () => _markShipmentAction(
          shipment,
          'complete',
          'Package marked as taken',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF15803D),
        ),
        child: const Text('Mark as Taken'),
      );
    }

    return null;
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _weightLabel(BranchLogisticsShipment shipment) {
    final weight = shipment.weightKg;
    if (weight == null) return 'Weight not set';
    return '${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)} kg';
  }

  String _dateTimeLabel(DateTime? value) {
    if (value == null) return 'Unknown time';

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} ${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }
}

enum _PickupFilter {
  all,
  awaiting,
  notTaken,
  taken,
}
