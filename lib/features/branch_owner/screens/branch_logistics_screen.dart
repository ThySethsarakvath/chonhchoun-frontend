import 'package:flutter/material.dart';

import '../../admin_management/models/branch_model.dart';
import '../../admin_management/services/branch_service.dart';
import '../../branch_logistics/models/branch_logistics_models.dart';
import '../../branch_logistics/services/branch_logistics_service.dart';
import '../widgets/branch_owner_content_widgets.dart';

class BranchLogisticsScreen extends StatefulWidget {
  final Branch? ownedBranch;

  const BranchLogisticsScreen({
    super.key,
    required this.ownedBranch,
  });

  @override
  State<BranchLogisticsScreen> createState() => _BranchLogisticsScreenState();
}

class _BranchLogisticsScreenState extends State<BranchLogisticsScreen> {
  final BranchLogisticsService _logisticsService = BranchLogisticsService();
  final BranchService _branchService = BranchService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _itemDescriptionController =
      TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _extraFeeController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  BranchLogisticsPricingMode _pricingMode = BranchLogisticsPricingMode.standard;
  String _directionFilter = 'all';
  String? _selectedReceiverBranchId;
  List<Branch> _branches = const [];
  List<BranchLogisticsShipment> _shipments = const [];
  BranchLogisticsPriceQuote? _quote;

  @override
  void initState() {
    super.initState();
    _senderNameController.text =
        widget.ownedBranch?.ownerName ?? widget.ownedBranch?.name ?? '';
    _senderPhoneController.text =
        widget.ownedBranch?.phone ?? widget.ownedBranch?.ownerPhone ?? '';
    _loadData();
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _itemDescriptionController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _extraFeeController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _branchService.getMapBranches(),
        _logisticsService.listShipments(direction: _directionFilter),
      ]);

      final branches = results[0] as List<Branch>;
      final shipments = results[1] as List<BranchLogisticsShipment>;
      final ownedBranchId = widget.ownedBranch?.id;
      final availableBranches = ownedBranchId == null
          ? branches
          : branches.where((branch) => branch.id != ownedBranchId).toList();

      if (!mounted) return;
      setState(() {
        _branches = availableBranches;
        _shipments = shipments;
        _selectedReceiverBranchId ??=
            availableBranches.isNotEmpty ? availableBranches.first.id : null;
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

  Future<void> _calculatePrice() async {
    if (!_formKey.currentState!.validate() || _selectedReceiverBranchId == null) {
      return;
    }
    final weight = _toDouble(_weightController.text);
    if (weight == null || weight <= 0) {
      _showError('Please enter a valid package weight.');
      return;
    }
    if (weight > 200) {
      _showError('This ticket flow supports packages up to 200 kg only.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final quote = await _logisticsService.calculatePrice(
        receiverBranchId: _selectedReceiverBranchId!,
        senderName: _senderNameController.text,
        senderPhone: _senderPhoneController.text,
        receiverName: _receiverNameController.text,
        receiverPhone: _receiverPhoneController.text,
        itemDescription: _itemDescriptionController.text,
        pricingMode: _pricingMode,
        weightKg: _toDouble(_weightController.text),
        lengthCm: _toDouble(_lengthController.text),
        widthCm: _toDouble(_widthController.text),
        heightCm: _toDouble(_heightController.text),
        extraFee: _toDouble(_extraFeeController.text),
        discount: _toDouble(_discountController.text),
        notes: _notesController.text,
      );

      if (!mounted) return;
      setState(() => _quote = quote);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _createShipment() async {
    if (!_formKey.currentState!.validate() || _selectedReceiverBranchId == null) {
      return;
    }
    final weight = _toDouble(_weightController.text);
    if (weight == null || weight <= 0) {
      _showError('Please enter a valid package weight.');
      return;
    }
    if (weight > 200) {
      _showError('This ticket flow supports packages up to 200 kg only.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final shipment = await _logisticsService.createShipment(
        receiverBranchId: _selectedReceiverBranchId!,
        senderName: _senderNameController.text,
        senderPhone: _senderPhoneController.text,
        receiverName: _receiverNameController.text,
        receiverPhone: _receiverPhoneController.text,
        itemDescription: _itemDescriptionController.text,
        pricingMode: _pricingMode,
        weightKg: _toDouble(_weightController.text),
        lengthCm: _toDouble(_lengthController.text),
        widthCm: _toDouble(_widthController.text),
        heightCm: _toDouble(_heightController.text),
        extraFee: _toDouble(_extraFeeController.text),
        discount: _toDouble(_discountController.text),
        notes: _notesController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shipment ${shipment.ticketNumber} created.')),
      );
      setState(() => _quote = null);
      await _loadData();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _updateShipment(
    BranchLogisticsShipment shipment,
    String action,
  ) async {
    try {
      await _logisticsService.updateShipmentStatus(
        shipmentId: shipment.id,
        action: action,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${shipment.ticketNumber} updated.')),
      );
      await _loadData();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB91C1C),
      ),
    );
  }

  double? _toDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  String _money(double value, String currency) {
    return '$currency ${value.toStringAsFixed(2)}';
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return '-';
    switch (status) {
      case 'CREATED':
        return 'Ticket Created';
      case 'ASSIGNED':
        return 'Assigned to Driver';
      case 'RECEIVED_AT_SENDER_WAREHOUSE':
        return 'Received at Sender Branch';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'RECEIVED_AT_RECEIVER_WAREHOUSE':
        return 'Arrived at Destination Branch';
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'COMPLETED':
        return 'Picked Up';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status
            .split('_')
            .map((part) => '${part.substring(0, 1)}${part.substring(1).toLowerCase()}')
            .join(' ');
    }
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

  Branch? get _selectedReceiverBranch {
    final selectedId = _selectedReceiverBranchId;
    if (selectedId == null) return null;
    for (final branch in _branches) {
      if (branch.id == selectedId) return branch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ownedBranch == null) {
      return const BranchOwnerMessageCard(
        title: 'Branch setup required',
        description:
            'This feature becomes available after your account is linked to a branch.',
      );
    }

    if (_loading) {
      return const BranchOwnerLoadingCard(
        message: 'Loading branch logistics workspace...',
      );
    }

    if (_error != null) {
      return BranchOwnerMessageCard(
        title: 'Unable to load Branch Logistics',
        description: _error!,
        actionLabel: 'Try again',
        onAction: _loadData,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionHero(
          title: 'Branch Logistics',
          description:
              'Create branch-to-branch tickets, estimate pricing by weight, and keep both warehouses aligned on shipment status.',
          icon: Icons.inventory_2_rounded,
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Pricing: 0-50kg Standard USD 2.50 / VIP USD 4.00, 50-100kg Standard USD 3.50 / VIP USD 5.00, 100-200kg Standard USD 4.50 / VIP USD 6.00.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            BranchOwnerStatCard(
              label: 'Total Shipments',
              value: _shipments.length.toString(),
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF0F766E),
            ),
            BranchOwnerStatCard(
              label: 'Inbound',
              value: _shipments
                  .where((item) => item.isInboundFor(widget.ownedBranch!.id))
                  .length
                  .toString(),
              icon: Icons.south_west_rounded,
              color: const Color(0xFF1D4ED8),
            ),
            BranchOwnerStatCard(
              label: 'Outbound',
              value: _shipments
                  .where((item) => item.isOutboundFor(widget.ownedBranch!.id))
                  .length
                  .toString(),
              icon: Icons.north_east_rounded,
              color: const Color(0xFFB45309),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildShipmentForm(),
        const SizedBox(height: 20),
        _buildShipmentsList(),
      ],
    );
  }

  Widget _buildShipmentForm() {
    final receiverBranch = _selectedReceiverBranch;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create warehouse ticket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the same operational fields, but keep it inside the branch-owner workflow instead of a registration flow.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                _partyCard(
                  accent: const Color(0xFF0F766E),
                  icon: Icons.upload_rounded,
                  title: 'Ticket sender',
                  subtitle: widget.ownedBranch?.name ?? 'Your branch',
                  children: [
                    _field(
                      controller: _senderNameController,
                      label: 'Sender name',
                      width: double.infinity,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _senderPhoneController,
                      label: 'Sender phone',
                      width: double.infinity,
                    ),
                    const SizedBox(height: 14),
                    _detailLine(
                      Icons.storefront_rounded,
                      'Branch address',
                      widget.ownedBranch?.address?.trim().isNotEmpty == true
                          ? widget.ownedBranch!.address!
                          : 'No branch address yet',
                    ),
                  ],
                ),
                _partyCard(
                  accent: const Color(0xFF1D4ED8),
                  icon: Icons.download_rounded,
                  title: 'Ticket receiver',
                  subtitle: receiverBranch?.name ?? 'Select receiver branch',
                  children: [
                    _branchDropdown(),
                    const SizedBox(height: 12),
                    _field(
                      controller: _receiverNameController,
                      label: 'Receiver name',
                      width: double.infinity,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _receiverPhoneController,
                      label: 'Receiver phone',
                      width: double.infinity,
                    ),
                    const SizedBox(height: 14),
                    _detailLine(
                      Icons.person_rounded,
                      'Branch owner',
                      receiverBranch?.ownerName?.trim().isNotEmpty == true
                          ? receiverBranch!.ownerName!
                          : 'No branch owner assigned',
                    ),
                    const SizedBox(height: 10),
                    _detailLine(
                      Icons.phone_rounded,
                      'Owner phone',
                      receiverBranch?.ownerPhone?.trim().isNotEmpty == true
                          ? receiverBranch!.ownerPhone!
                          : 'No owner phone available',
                    ),
                    const SizedBox(height: 10),
                    _detailLine(
                      Icons.location_on_rounded,
                      'Branch address',
                      receiverBranch?.address?.trim().isNotEmpty == true
                          ? receiverBranch!.address!
                          : 'No branch address available',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _pricingModeDropdown(),
                _field(
                  controller: _itemDescriptionController,
                  label: 'Item description',
                  maxLines: 2,
                  width: 520,
                ),
                _field(
                  controller: _weightController,
                  label: 'Weight (kg)',
                  keyboardType: TextInputType.number,
                ),
                _field(
                  controller: _lengthController,
                  label: 'Length (cm)',
                  keyboardType: TextInputType.number,
                ),
                _field(
                  controller: _widthController,
                  label: 'Width (cm)',
                  keyboardType: TextInputType.number,
                ),
                _field(
                  controller: _heightController,
                  label: 'Height (cm)',
                  keyboardType: TextInputType.number,
                ),
                _field(
                  controller: _extraFeeController,
                  label: 'Extra fee',
                  keyboardType: TextInputType.number,
                ),
                _field(
                  controller: _discountController,
                  label: 'Discount',
                  keyboardType: TextInputType.number,
                ),
                _field(
                  controller: _notesController,
                  label: 'Notes',
                  maxLines: 2,
                  width: 520,
                  required: false,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _calculatePrice,
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('Calculate price'),
                ),
                FilledButton.icon(
                  onPressed: _submitting ? null : _createShipment,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                  ),
                  icon: const Icon(Icons.add_task_rounded),
                  label: Text(_submitting ? 'Saving...' : 'Create shipment'),
                ),
              ],
            ),
            if (_quote != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  children: [
                    _quoteItem(
                      'Total',
                      _money(_quote!.totalPrice, _quote!.currency),
                    ),
                    _quoteItem(
                      'Base price',
                      _money(_quote!.basePrice, _quote!.currency),
                    ),
                    _quoteItem(
                      'Chargeable kg',
                      _quote!.chargeableWeightKg.toStringAsFixed(2),
                    ),
                    _quoteItem(
                      'Volume m³',
                      _quote!.volumeM3.toStringAsFixed(3),
                    ),
                    _quoteItem('Mode', _quote!.pricingMode.label),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentsList() {
    return Container(
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
                child: Text(
                  'Recent shipment tickets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              DropdownButton<String>(
                value: _directionFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'outbound', child: Text('Outbound')),
                  DropdownMenuItem(value: 'inbound', child: Text('Inbound')),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _directionFilter = value);
                  await _loadData();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_shipments.isEmpty)
            const BranchOwnerMessageCard(
              title: 'No shipment ticket yet',
              description:
                  'Create your first branch-to-branch shipment ticket from the form above.',
            )
          else
            ..._shipments.take(8).map(_shipmentCard),
        ],
      ),
    );
  }

  Widget _shipmentCard(BranchLogisticsShipment shipment) {
    final isOutbound = shipment.isOutboundFor(widget.ownedBranch!.id);
    final actions = _actionsForShipment(shipment, isOutbound);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      shipment.ticketNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shipment.sender.name} -> ${shipment.receiver.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(shipment.totalPrice, shipment.currency),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _badge(
                    _statusLabel(shipment.status),
                    const Color(0xFFE2E8F0),
                    const Color(0xFF334155),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            shipment.itemDescription,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _miniInfo(
                isOutbound ? 'Outbound' : 'Inbound',
              ),
              Text(
                'From ${shipment.senderBranch?.name ?? '-'}',
                style: const TextStyle(color: Color(0xFF475569)),
              ),
              Text(
                'To ${shipment.receiverBranch?.name ?? '-'}',
                style: const TextStyle(color: Color(0xFF475569)),
              ),
              Text(
                _dateLabel(shipment.createdAt),
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _actionsForShipment(
    BranchLogisticsShipment shipment,
    bool isOutbound,
  ) {
    switch (shipment.status) {
      case 'CREATED':
        return const [];
      case 'ASSIGNED':
        return isOutbound
            ? [
                OutlinedButton(
                  onPressed: () => _updateShipment(shipment, 'receive-at-sender'),
                  child: const Text('Collect from Branch'),
                ),
              ]
            : const [];
      case 'RECEIVED_AT_SENDER_WAREHOUSE':
        return isOutbound
            ? [
                OutlinedButton(
                  onPressed: () => _updateShipment(shipment, 'dispatch'),
                  child: const Text('Send to Destination'),
                ),
              ]
            : const [];
      case 'IN_TRANSIT':
        return !isOutbound
            ? [
                OutlinedButton(
                  onPressed: () =>
                      _updateShipment(shipment, 'receive-at-destination'),
                  child: const Text('Mark Arrived'),
                ),
              ]
            : const [];
      case 'RECEIVED_AT_RECEIVER_WAREHOUSE':
        return !isOutbound
            ? [
                OutlinedButton(
                  onPressed: () => _updateShipment(shipment, 'ready'),
                  child: const Text('Ready for Pickup'),
                ),
                FilledButton(
                  onPressed: () => _updateShipment(shipment, 'complete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                  ),
                  child: const Text('Mark Picked Up'),
                ),
              ]
            : const [];
      case 'READY_FOR_PICKUP':
        return !isOutbound
            ? [
                FilledButton(
                  onPressed: () => _updateShipment(shipment, 'complete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                  ),
                  child: const Text('Mark Picked Up'),
                ),
              ]
            : const [];
      default:
        return const [];
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    double width = 250,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Widget _branchDropdown() {
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: _selectedReceiverBranchId,
        items: _branches
            .map(
              (branch) => DropdownMenuItem(
                value: branch.id,
                child: Text(branch.name),
              ),
            )
            .toList(),
        validator: (value) => value == null ? 'Select branch' : null,
        onChanged: (value) {
          setState(() => _selectedReceiverBranchId = value);
        },
        decoration: InputDecoration(
          labelText: 'Receiver branch',
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Widget _pricingModeDropdown() {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<BranchLogisticsPricingMode>(
        value: _pricingMode,
        items: BranchLogisticsPricingMode.values
            .map(
              (mode) => DropdownMenuItem(
                value: mode,
                child: Text(mode.label),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => _pricingMode = value);
        },
        decoration: InputDecoration(
          labelText: 'Service type',
          helperText: _pricingMode.deliveryCommitment,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Widget _quoteItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  Widget _miniInfo(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1D4ED8),
      ),
    );
  }

  Widget _partyCard({
    required Color accent,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: 420,
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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _detailLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
