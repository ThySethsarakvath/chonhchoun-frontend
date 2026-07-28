import 'package:flutter/material.dart';

import '../../admin_management/models/branch_model.dart';
import '../../admin_management/services/branch_service.dart';
import '../../auth/models/user_model.dart';
import '../../branch_logistics/models/branch_logistics_models.dart';
import '../../branch_logistics/services/branch_logistics_service.dart';
import '../../driver_registration/models/driver_management_model.dart';
import '../../driver_registration/models/vehicle_type.dart';
import '../../driver_registration/services/driver_application_service.dart';
import '../widgets/branch_owner_content_widgets.dart';

class BranchLogisticsListScreen extends StatefulWidget {
  final Branch? ownedBranch;

  const BranchLogisticsListScreen({
    super.key,
    required this.ownedBranch,
  });

  @override
  State<BranchLogisticsListScreen> createState() =>
      _BranchLogisticsListScreenState();
}

class _BranchLogisticsListScreenState extends State<BranchLogisticsListScreen> {
  final BranchLogisticsService _logisticsService = BranchLogisticsService();
  final BranchService _branchService = BranchService();
  final DriverApplicationService _driverApplicationService =
      DriverApplicationService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _itemDescriptionController =
      TextEditingController();
  final TextEditingController _packageCountController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String _directionFilter = 'all';
  String _statusFilter = 'active';
  BranchLogisticsPricingMode _deliveryType = BranchLogisticsPricingMode.standard;
  bool _showOptionalDimensions = false;
  String? _draftStockId;
  final Set<String> _selectedTripTicketIds = <String>{};
  String? _selectedReceiverBranchId;
  String? _selectedSenderUserId;
  String? _selectedReceiverUserId;
  List<Branch> _branches = const [];
  List<UserProfile> _ticketUsers = const [];
  List<BranchLogisticsShipment> _shipments = const [];
  BranchDriverManagementOverview? _driverManagementOverview;

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
    _packageCountController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
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
        _logisticsService.listTicketUsers(),
        _logisticsService.listShipments(
          direction: _directionFilter,
          status: _resolvedStatusFilter,
        ),
        _driverApplicationService.getBranchOwnerManagementOverview(),
      ]);

      final branches = results[0] as List<Branch>;
      final ticketUsers = results[1] as List<UserProfile>;
      final shipments = results[2] as List<BranchLogisticsShipment>;
      final driverManagement =
          results[3] as BranchDriverManagementOverview;
      final ownedBranchId = widget.ownedBranch?.id;
      final availableBranches = ownedBranchId == null
          ? branches
          : branches.where((branch) => branch.id != ownedBranchId).toList();

      if (!mounted) return;
      setState(() {
        _branches = availableBranches;
        _ticketUsers = ticketUsers;
        _shipments = shipments;
        _driverManagementOverview = driverManagement;
        _selectedReceiverBranchId ??=
            availableBranches.isNotEmpty ? availableBranches.first.id : null;
        _loading = false;
      });
      _applySenderSelection(_selectedSenderUserId);
      _applyReceiverSelection(_selectedReceiverUserId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String? get _resolvedStatusFilter {
    if (_statusFilter == 'completed') return 'COMPLETED';
    return null;
  }

  List<BranchLogisticsShipment> get _visibleShipments {
    if (_statusFilter == 'active') {
      return _shipments
          .where(
            (shipment) =>
                shipment.status != 'COMPLETED' &&
                shipment.status != 'CANCELLED',
          )
          .toList();
    }
    return _shipments;
  }

  UserProfile? _findTicketUser(String? userId) {
    if (userId == null) return null;
    for (final user in _ticketUsers) {
      if (user.id == userId) return user;
    }
    return null;
  }

  void _applySenderSelection(String? userId) {
    if (userId == null) {
      _selectedSenderUserId = null;
      _senderNameController.clear();
      _senderPhoneController.clear();
      return;
    }
    final user = _findTicketUser(userId);
    if (user == null) return;
    _selectedSenderUserId = user.id;
    _senderNameController.text = user.name;
    _senderPhoneController.text = user.phone ?? '';
  }

  void _applyReceiverSelection(String? userId) {
    if (userId == null) {
      _selectedReceiverUserId = null;
      _receiverNameController.clear();
      _receiverPhoneController.clear();
      return;
    }
    final user = _findTicketUser(userId);
    if (user == null) return;
    _selectedReceiverUserId = user.id;
    _receiverNameController.text = user.name;
    _receiverPhoneController.text = user.phone ?? '';
  }

  List<UserProfile> get _availableSenderUsers {
    return _ticketUsers
        .where((user) => user.id != _selectedReceiverUserId)
        .toList();
  }

  List<UserProfile> get _availableReceiverUsers {
    return _ticketUsers
        .where((user) => user.id != _selectedSenderUserId)
        .toList();
  }

  bool _validateWeightLimit() {
    final weight = _toDouble(_weightController.text);
    if (weight == null || weight <= 0) {
      _showError('Please enter a valid package weight.');
      return false;
    }
    if (weight > 200) {
      _showError('This ticket flow supports packages up to 200 kg only.');
      return false;
    }
    return true;
  }

  int? _packageCountValue() {
    return int.tryParse(_packageCountController.text.trim());
  }

  String _buildTicketNotes() {
    final parts = <String>[];
    if (_draftStockId != null && _draftStockId!.isNotEmpty) {
      parts.add('Stock ID: ${_draftStockId!}');
    }
    final packageCount = _packageCountValue();
    if (packageCount != null) {
      parts.add('Package stock: $packageCount');
    }
    final notes = _notesController.text.trim();
    if (notes.isNotEmpty) {
      parts.add(notes);
    }
    return parts.join('\n');
  }

  String _packageStockLabel(BranchLogisticsShipment shipment) {
    final notes = shipment.notes ?? '';
    final match = RegExp(r'Package stock:\s*(\d+)', caseSensitive: false)
        .firstMatch(notes);
    if (match != null) {
      return '${match.group(1)} packages';
    }
    return '-';
  }

  int _packageStockCount(BranchLogisticsShipment shipment) {
    final notes = shipment.notes ?? '';
    final match = RegExp(r'Package stock:\s*(\d+)', caseSensitive: false)
        .firstMatch(notes);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  String _stockIdLabel(BranchLogisticsShipment shipment) {
    final notes = shipment.notes ?? '';
    final match =
        RegExp(r'Stock ID:\s*([A-Z0-9\-]+)', caseSensitive: false)
            .firstMatch(notes);
    if (match != null) {
      return match.group(1) ?? '-';
    }
    return '-';
  }

  String _generateStockId() {
    final branchNumber =
        widget.ownedBranch?.branchNumber?.toString().padLeft(2, '0') ?? '00';
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return 'STK-B$branchNumber-${now.year}$month$day';
  }

  bool _isVip(BranchLogisticsShipment shipment) {
    return shipment.pricingMode == BranchLogisticsPricingMode.vip;
  }

  bool _isStandardDayThree(BranchLogisticsShipment shipment) {
    if (_isVip(shipment)) return false;
    final createdAt = shipment.createdAt;
    if (createdAt == null) return false;
    final now = DateTime.now();
    return now.difference(createdAt.toLocal()).inDays >= 2;
  }

  String _serviceLevelLabel(BranchLogisticsShipment shipment) {
    return _isVip(shipment) ? 'VIP Same Day' : 'Standard 1-3 Days';
  }

  Color _serviceLevelForeground(BranchLogisticsShipment shipment) {
    return _isVip(shipment)
        ? const Color(0xFF9A3412)
        : const Color(0xFF1D4ED8);
  }

  Color _serviceLevelBackground(BranchLogisticsShipment shipment) {
    return _isVip(shipment)
        ? const Color(0xFFFFEDD5)
        : const Color(0xFFDBEAFE);
  }

  String _urgencyLabel(BranchLogisticsShipment shipment) {
    if (_isVip(shipment)) return 'Priority Today';
    if (_isStandardDayThree(shipment)) return 'Standard Day 3';
    return 'Queue Ready';
  }

  Color _urgencyForeground(BranchLogisticsShipment shipment) {
    if (_isVip(shipment)) return const Color(0xFF991B1B);
    if (_isStandardDayThree(shipment)) return const Color(0xFFB45309);
    return const Color(0xFF475569);
  }

  Color _urgencyBackground(BranchLogisticsShipment shipment) {
    if (_isVip(shipment)) return const Color(0xFFFEE2E2);
    if (_isStandardDayThree(shipment)) return const Color(0xFFFEF3C7);
    return const Color(0xFFE2E8F0);
  }

  bool _isTripSelectable(BranchLogisticsShipment shipment) {
    return shipment.status == 'CREATED';
  }

  void _toggleTripSelection(BranchLogisticsShipment shipment, bool selected) {
    setState(() {
      if (selected) {
        _selectedTripTicketIds.add(shipment.id);
      } else {
        _selectedTripTicketIds.remove(shipment.id);
      }
    });
  }

  ManagedVehicle? _assignedBranchVehicleForDriver(ManagedDriver driver) {
    for (final assignment in driver.assignments) {
      final vehicle = assignment.vehicle;
      if (vehicle == null) continue;
      if (!vehicle.isCompanyVehicle || !vehicle.isActive) continue;
      if (vehicle.status != 'AVAILABLE' && vehicle.status != 'IN_USE') {
        continue;
      }
      return vehicle;
    }
    return null;
  }

  bool _isCityExpressDriver(ManagedDriver driver) {
    final currentBranchVehicle = _assignedBranchVehicleForDriver(driver);
    if (currentBranchVehicle != null) return false;

    final currentVehicle =
        driver.assignments.isNotEmpty ? driver.assignments.first.vehicle : null;
    return currentVehicle != null &&
        currentVehicle.ownershipType == 'DRIVER_OWNED' &&
        currentVehicle.type == driverOwnMotorcycleType &&
        currentVehicle.ownerDriverId == driver.id;
  }

  List<ManagedDriver> get _availableTripDrivers {
    final overview = _driverManagementOverview;
    if (overview == null) return const <ManagedDriver>[];

    return overview.drivers.where((driver) {
      if (!driver.isActive) return false;
      if (_isCityExpressDriver(driver)) return false;
      if (driver.availabilityStatus != 'AVAILABLE') return false;
      return _assignedBranchVehicleForDriver(driver) != null;
    }).toList(growable: false);
  }

  String _driverTripLabel(ManagedDriver driver) {
    final vehicle = _assignedBranchVehicleForDriver(driver);
    if (vehicle == null) return driver.name;
    return '${driver.name} | ${vehicle.code} | ${vehicleTypeLabel(vehicle.type)}';
  }

  bool _countsAsActiveTruckLoad(BranchLogisticsShipment shipment) {
    return shipment.status == 'ASSIGNED' ||
        shipment.status == 'RECEIVED_AT_SENDER_WAREHOUSE' ||
        shipment.status == 'IN_TRANSIT';
  }

  _VehicleTripLoad _vehicleTripLoad(
    ManagedVehicle vehicle, {
    Set<String> excludeShipmentIds = const <String>{},
  }) {
    var stock = 0;
    var weightKg = 0.0;

    for (final shipment in _shipments) {
      if (excludeShipmentIds.contains(shipment.id)) continue;
      if (!_countsAsActiveTruckLoad(shipment)) continue;
      if (shipment.assignedVehicle?.id != vehicle.id) continue;
      stock += _packageStockCount(shipment);
      weightKg += shipment.weightKg ?? 0;
    }

    return _VehicleTripLoad(
      stock: stock,
      weightKg: weightKg,
    );
  }

  String _weightLabel(double value) {
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} kg';
  }

  String _truckCapacitySummary(ManagedVehicle vehicle) {
    final activeLoad = _vehicleTripLoad(vehicle);
    final stockLimit = vehicle.maxPackageCount;
    final weightLimit = vehicle.maxWeightKg;
    final remainingStock = stockLimit == null
        ? null
        : ((stockLimit - activeLoad.stock) < 0
              ? 0
              : (stockLimit - activeLoad.stock));
    final remainingWeight = weightLimit == null
        ? null
        : ((weightLimit - activeLoad.weightKg) < 0
              ? 0.0
              : (weightLimit - activeLoad.weightKg));

    final parts = <String>[];
    if (remainingStock != null) {
      parts.add('$remainingStock/${stockLimit} packages free');
    }
    if (remainingWeight != null) {
      parts.add(
        '${_weightLabel(remainingWeight)}/${_weightLabel(weightLimit!)} free',
      );
    }
    if (parts.isEmpty) {
      return 'Capacity not set';
    }
    return parts.join(' | ');
  }

  List<_AssignedTripSummary> _assignedTripSummaries(
    List<BranchLogisticsShipment> shipments,
  ) {
    final grouped = <String, List<BranchLogisticsShipment>>{};
    for (final shipment in shipments) {
      final vehicleId = shipment.assignedVehicle?.id;
      final driverId = shipment.assignedDriver?.id;
      if (vehicleId == null || driverId == null) continue;
      final key = '$vehicleId|$driverId';
      grouped.putIfAbsent(key, () => <BranchLogisticsShipment>[]).add(shipment);
    }

    final summaries = grouped.entries.map((entry) {
      final tripShipments = entry.value;
      final lead = tripShipments.first;
      final totalStock = tripShipments.fold<int>(
        0,
        (sum, shipment) => sum + _packageStockCount(shipment),
      );
      final totalWeight = tripShipments.fold<double>(
        0,
        (sum, shipment) => sum + (shipment.weightKg ?? 0),
      );
      final vehicleCode = lead.assignedVehicle?.code ?? 'Assigned vehicle';
      final driverName = lead.assignedDriver?.name ?? 'Assigned driver';
      ManagedVehicle? vehicle;
      final knownVehicles = _driverManagementOverview?.vehicles ?? const [];
      for (final item in knownVehicles) {
        if (item.id == lead.assignedVehicle?.id) {
          vehicle = item;
          break;
        }
      }
      final usedCapacity = vehicle == null
          ? '$totalStock packages | ${_weightLabel(totalWeight)}'
          : '${totalStock}/${vehicle.maxPackageCount?.toString() ?? '-'} packages | ${_weightLabel(totalWeight)}/${vehicle.maxWeightKg == null ? '-' : _weightLabel(vehicle.maxWeightKg!)}';

      return _AssignedTripSummary(
        vehicleCode: vehicleCode,
        driverName: driverName,
        statusLabel: _groupActionStateLabel(tripShipments),
        usedCapacityLabel: usedCapacity,
        assignedTimeLabel: _dateLabel(lead.assignedAt),
        ticketCount: tripShipments.length,
      );
    }).toList(growable: false);

    summaries.sort((a, b) => a.vehicleCode.compareTo(b.vehicleCode));
    return summaries;
  }

  String _packageSizeLabel(BranchLogisticsShipment shipment) {
    return '${shipment.weightKg?.toStringAsFixed(0) ?? '-'} kg | '
        '${shipment.lengthCm?.toStringAsFixed(0) ?? '-'} x '
        '${shipment.widthCm?.toStringAsFixed(0) ?? '-'} x '
        '${shipment.heightCm?.toStringAsFixed(0) ?? '-'} cm';
  }

  String _contactLabel(String name, String phone) {
    return '$name | $phone';
  }

  String _buildAssignmentTripNote({
    required String destinationName,
    required ManagedDriver driver,
    required ManagedVehicle? vehicle,
    required int ticketCount,
    required int totalStock,
    required double totalWeight,
    required String ownerNote,
  }) {
    final parts = <String>[
      'Trip note: Branch delivery to $destinationName',
      'Assigned driver: ${driver.name}',
      'Assigned vehicle: ${vehicle?.code ?? 'Branch vehicle'}',
      'Trip load: $ticketCount ticket(s) | $totalStock packages | ${_weightLabel(totalWeight)}',
    ];
    final trimmedOwnerNote = ownerNote.trim();
    if (trimmedOwnerNote.isNotEmpty) {
      parts.add('Owner note: $trimmedOwnerNote');
    }
    return parts.join('\n');
  }

  Future<void> _showPreparedTripDialog({
    required String destinationName,
    required List<BranchLogisticsShipment> shipments,
  }) async {
    final totalStock = shipments.fold<int>(
      0,
      (sum, shipment) => sum + _packageStockCount(shipment),
    );
    final totalWeight = shipments.fold<double>(
      0,
      (sum, shipment) => sum + (shipment.weightKg ?? 0),
    );
    final vipCount = shipments.where(_isVip).length;
    final urgentCount = shipments.where(_isStandardDayThree).length;
    final availableDrivers = _availableTripDrivers;
    String? selectedDriverId =
        availableDrivers.isNotEmpty ? availableDrivers.first.id : null;
    final tripNotesController = TextEditingController();
    var assigningTrip = false;
    var dialogOpen = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          ManagedDriver? selectedDriver;
          final selectedIds = shipments.map((shipment) => shipment.id).toSet();
          for (final driver in availableDrivers) {
            if (driver.id == selectedDriverId) {
              selectedDriver = driver;
              break;
            }
          }
          final selectedVehicle = selectedDriver == null
              ? null
              : _assignedBranchVehicleForDriver(selectedDriver);
          final activeLoad = selectedVehicle == null
              ? const _VehicleTripLoad(stock: 0, weightKg: 0)
              : _vehicleTripLoad(
                  selectedVehicle,
                  excludeShipmentIds: selectedIds,
                );
          final weightLimit = selectedVehicle?.maxWeightKg;
          final stockLimit = selectedVehicle?.maxPackageCount;
          final remainingWeight = weightLimit == null
              ? null
              : weightLimit - activeLoad.weightKg;
          final remainingStock = stockLimit == null
              ? null
              : stockLimit - activeLoad.stock;
          final weightAfterAssign = activeLoad.weightKg + totalWeight;
          final stockAfterAssign = activeLoad.stock + totalStock;
          final weightFit =
              weightLimit == null || weightAfterAssign <= weightLimit;
          final stockFit =
              stockLimit == null || stockAfterAssign <= stockLimit;

          Future<void> submitAssignment() async {
            if (selectedDriver == null) {
              _showError('Please choose an available branch driver.');
              return;
            }
            final chosenDriver = selectedDriver!;
            final assignmentNote = _buildAssignmentTripNote(
              destinationName: destinationName,
              driver: chosenDriver,
              vehicle: selectedVehicle,
              ticketCount: shipments.length,
              totalStock: totalStock,
              totalWeight: totalWeight,
              ownerNote: tripNotesController.text,
            );

            setModalState(() => assigningTrip = true);
            try {
              await _logisticsService.assignTripToDriver(
                shipmentIds: shipments.map((shipment) => shipment.id).toList(),
                driverId: chosenDriver.id,
                notes: assignmentNote,
              );
              if (!mounted) return;
              dialogOpen = false;
              Navigator.of(dialogContext).pop();
              setState(() {
                for (final shipment in shipments) {
                  _selectedTripTicketIds.remove(shipment.id);
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Trip assigned to ${chosenDriver.name} with ${selectedVehicle?.code ?? 'branch vehicle'}.',
                  ),
                ),
              );
              await _loadData();
            } catch (e) {
              _showError(e.toString().replaceFirst('Exception: ', ''));
            } finally {
              if (mounted && dialogOpen) {
                setModalState(() => assigningTrip = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Prepare and Assign Trip'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailLine('Destination', destinationName),
                    const SizedBox(height: 8),
                    _detailLine('Tickets', '${shipments.length} selected'),
                    const SizedBox(height: 8),
                    _detailLine('Total stock', '$totalStock packages'),
                    const SizedBox(height: 8),
                    _detailLine(
                      'Total weight',
                      '${totalWeight.toStringAsFixed(totalWeight % 1 == 0 ? 0 : 1)} kg',
                    ),
                    const SizedBox(height: 8),
                    _detailLine('VIP tickets', '$vipCount'),
                    const SizedBox(height: 8),
                    _detailLine('Day-3 standard', '$urgentCount'),
                    const SizedBox(height: 16),
                    const Text(
                      'Assign branch driver',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (availableDrivers.isEmpty)
                      const Text(
                        'No available branch driver with a branch vehicle is ready yet. Set driver status to Available and assign a branch truck in Driver Management first.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        value: selectedDriverId,
                        items: availableDrivers
                            .map(
                              (driver) => DropdownMenuItem<String>(
                                value: driver.id,
                                child: Text(
                                  _driverTripLabel(driver),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: assigningTrip
                            ? null
                            : (value) {
                                setModalState(() => selectedDriverId = value);
                              },
                        decoration: InputDecoration(
                          labelText: 'Branch driver',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                      if (selectedVehicle != null) ...[
                        const SizedBox(height: 12),
                        _detailLine('Vehicle', selectedVehicle.code),
                        const SizedBox(height: 8),
                        _detailLine(
                          'Capacity',
                          '${selectedVehicle.maxPackageCount?.toString() ?? '-'} packages | ${selectedVehicle.maxWeightKg?.toStringAsFixed(0) ?? '-'} kg',
                        ),
                        const SizedBox(height: 8),
                        _detailLine(
                          'Current load',
                          '${activeLoad.stock} packages | ${_weightLabel(activeLoad.weightKg)}',
                        ),
                        const SizedBox(height: 8),
                        _detailLine(
                          'Available now',
                          '${remainingStock == null ? 'No package limit' : '$remainingStock packages'} | ${remainingWeight == null ? 'No weight limit' : _weightLabel(remainingWeight <= 0 ? 0 : remainingWeight)}',
                        ),
                        const SizedBox(height: 8),
                        _detailLine(
                          'After this trip',
                          '$stockAfterAssign packages | ${_weightLabel(weightAfterAssign)}',
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (weightFit && stockFit)
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (weightFit && stockFit)
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFED7AA),
                            ),
                          ),
                          child: Text(
                            (weightFit && stockFit)
                                ? 'This trip still fits the truck after counting the load already assigned on this vehicle.'
                                : 'This truck does not have enough free capacity for this trip right now. Use another truck, or wait until current tickets are completed.',
                            style: TextStyle(
                              fontSize: 12,
                              color: (weightFit && stockFit)
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF9A3412),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: tripNotesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Owner note',
                        hintText: 'Optional handling note for the driver',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Standard day-3 tickets should leave now. VIP and standard tickets to the same destination can be mixed in one trip when capacity is available.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: assigningTrip
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: assigningTrip || availableDrivers.isEmpty
                    ? null
                    : submitAssignment,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                ),
                child: Text(
                  assigningTrip ? 'Assigning...' : 'Assign Trip',
                ),
              ),
            ],
          );
        },
      ),
    );
    tripNotesController.dispose();
  }

  Future<void> _createShipment() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSenderUserId == null ||
        _selectedReceiverBranchId == null ||
        _selectedReceiverUserId == null) {
      if (_selectedSenderUserId == null) {
        _showError('Please select a sender account.');
      } else
      if (_selectedReceiverUserId == null) {
        _showError('Please select a receiver account.');
      }
      return;
    }
    if (!_validateWeightLimit()) {
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
        pricingMode: _deliveryType,
        senderUserId: _selectedSenderUserId,
        receiverUserId: _selectedReceiverUserId,
        weightKg: _toDouble(_weightController.text),
        lengthCm: _toDouble(_lengthController.text),
        widthCm: _toDouble(_widthController.text),
        heightCm: _toDouble(_heightController.text),
        notes: _buildTicketNotes(),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ticket ${shipment.ticketNumber} created and is waiting for driver assignment.',
          ),
        ),
      );
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

  Future<void> _updateShipmentGroup(
    List<BranchLogisticsShipment> shipments,
    String action, {
    required String successLabel,
  }) async {
    if (shipments.isEmpty) return;

    try {
      for (final shipment in shipments) {
        await _logisticsService.updateShipmentStatus(
          shipmentId: shipment.id,
          action: action,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successLabel for ${shipments.length} ticket(s).'),
        ),
      );
      await _loadData();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openCreateTicketDialog() async {
    _draftStockId = _generateStockId();
    _deliveryType = BranchLogisticsPricingMode.standard;
    _showOptionalDimensions = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final receiverBranch = _selectedReceiverBranch;
            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Create Ticket',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _submitting
                                    ? null
                                    : () => Navigator.of(dialogContext).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a simple ticket first.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Record sender, receiver, package stock, and package details here. Assign the driver later from Driver Management.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _dialogSectionTitle('Delivery Rule'),
                          const SizedBox(height: 8),
                          _dialogInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailLine('Package ID', _draftStockId ?? '-'),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _deliveryTypeChip(
                                      mode: BranchLogisticsPricingMode.standard,
                                      label: 'Standard',
                                      helper: 'Send within 1-3 days',
                                      onSelected: () {
                                        setState(() {
                                          _deliveryType =
                                              BranchLogisticsPricingMode.standard;
                                        });
                                        setModalState(() {});
                                      },
                                    ),
                                    _deliveryTypeChip(
                                      mode: BranchLogisticsPricingMode.vip,
                                      label: 'VIP',
                                      helper: 'Same day delivery',
                                      onSelected: () {
                                        setState(() {
                                          _deliveryType =
                                              BranchLogisticsPricingMode.vip;
                                        });
                                        setModalState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _dialogSectionTitle('Sender'),
                          const SizedBox(height: 8),
                          _dialogInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _userDropdown(
                                  label: 'Sender account',
                                  value: _selectedSenderUserId,
                                  users: _availableSenderUsers,
                                  onChanged: (value) {
                                    setState(() => _selectedSenderUserId = value);
                                    _applySenderSelection(value);
                                    setModalState(() {});
                                  },
                                ),
                                const SizedBox(height: 12),
                                _detailLine('Name', _senderNameController.text),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Phone',
                                  _senderPhoneController.text.trim().isNotEmpty
                                      ? _senderPhoneController.text.trim()
                                      : '-',
                                ),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Branch owner',
                                  widget.ownedBranch?.ownerName?.trim().isNotEmpty == true
                                      ? widget.ownedBranch!.ownerName!
                                      : '-',
                                ),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Address',
                                  widget.ownedBranch?.address?.trim().isNotEmpty == true
                                      ? widget.ownedBranch!.address!
                                      : '-',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _dialogSectionTitle('Receiver'),
                          const SizedBox(height: 8),
                          _dialogInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _branchDropdown(
                                  width: double.infinity,
                                  onChanged: (value) {
                                    setState(() => _selectedReceiverBranchId = value);
                                    setModalState(() {});
                                  },
                                ),
                                const SizedBox(height: 12),
                                _userDropdown(
                                  label: 'Receiver account',
                                  value: _selectedReceiverUserId,
                                  users: _availableReceiverUsers,
                                  onChanged: (value) {
                                    setState(() => _selectedReceiverUserId = value);
                                    _applyReceiverSelection(value);
                                    setModalState(() {});
                                  },
                                ),
                                const SizedBox(height: 14),
                                _detailLine(
                                  'Name',
                                  _receiverNameController.text.trim().isNotEmpty
                                      ? _receiverNameController.text.trim()
                                      : '-',
                                ),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Phone',
                                  _receiverPhoneController.text.trim().isNotEmpty
                                      ? _receiverPhoneController.text.trim()
                                      : '-',
                                ),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Branch owner',
                                  receiverBranch?.ownerName?.trim().isNotEmpty == true
                                      ? receiverBranch!.ownerName!
                                      : '-',
                                ),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Address',
                                  receiverBranch?.address?.trim().isNotEmpty == true
                                      ? receiverBranch!.address!
                                      : '-',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _dialogSectionTitle('Ticket Details'),
                          const SizedBox(height: 8),
                          _dialogInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailLine(
                                  'Users',
                                  '${_senderNameController.text.trim().isNotEmpty ? _senderNameController.text.trim() : '-'} -> ${_receiverNameController.text.trim().isNotEmpty ? _receiverNameController.text.trim() : '-'}',
                                ),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Operation',
                                  '${widget.ownedBranch?.address?.trim().isNotEmpty == true ? widget.ownedBranch!.address! : widget.ownedBranch?.name ?? 'Sender branch'} -> ${receiverBranch?.address?.trim().isNotEmpty == true ? receiverBranch!.address! : receiverBranch?.name ?? 'Receiver branch'}',
                                ),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Branches',
                                  '${widget.ownedBranch?.ownerName?.trim().isNotEmpty == true ? widget.ownedBranch!.ownerName! : widget.ownedBranch?.name ?? '-'} -> ${receiverBranch?.ownerName?.trim().isNotEmpty == true ? receiverBranch!.ownerName! : receiverBranch?.name ?? '-'}',
                                ),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Driver assignment',
                                  'Pending. Create the ticket first, then assign from Prepare Trip.',
                                ),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Ticket status',
                                  'Waiting for driver assignment.',
                                ),
                                const SizedBox(height: 8),
                                _detailLine(
                                  'Trip rule',
                                  _deliveryType == BranchLogisticsPricingMode.vip
                                      ? 'VIP goes same day when possible and can join an available branch trip.'
                                      : 'Standard can wait up to 3 days and should be prioritized on day 3.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _field(
                                controller: _packageCountController,
                                label: 'Number of pieces',
                                keyboardType: TextInputType.number,
                                required: true,
                              ),
                              _field(
                                controller: _weightController,
                                label: 'Total weight (kg)',
                                keyboardType: TextInputType.number,
                                required: true,
                              ),
                              _field(
                                controller: _itemDescriptionController,
                                label: 'Package detail',
                                maxLines: 2,
                                width: 520,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showOptionalDimensions =
                                    !_showOptionalDimensions;
                                if (!_showOptionalDimensions) {
                                  _lengthController.clear();
                                  _widthController.clear();
                                  _heightController.clear();
                                }
                              });
                              setModalState(() {});
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _showOptionalDimensions
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    color: const Color(0xFF334155),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Add package size (optional)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Use Length x Width x Height only if this ticket needs package dimensions.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showOptionalDimensions) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _field(
                                  controller: _lengthController,
                                  label: 'Length (cm)',
                                  keyboardType: TextInputType.number,
                                  required: false,
                                ),
                                _field(
                                  controller: _widthController,
                                  label: 'Width (cm)',
                                  keyboardType: TextInputType.number,
                                  required: false,
                                ),
                                _field(
                                  controller: _heightController,
                                  label: 'Height (cm)',
                                  keyboardType: TextInputType.number,
                                  required: false,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: _submitting ? null : _createShipment,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF334155),
                                ),
                                icon: const Icon(Icons.add_task_rounded),
                                label: Text(
                                  _submitting ? 'Saving...' : 'Create Ticket',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    _draftStockId = null;
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

  String _ticketPricingLabel(BranchLogisticsShipment shipment) {
    final paidAmount = shipment.amountPaid > 0
        ? shipment.amountPaid
        : shipment.totalPrice;
    return _money(paidAmount, shipment.currency);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'CREATED':
        return 'Waiting for Driver';
      case 'ASSIGNED':
        return 'Not Yet Collected';
      case 'RECEIVED_AT_SENDER_WAREHOUSE':
        return 'Collected';
      case 'IN_TRANSIT':
        return 'Deliver Halfway';
      case 'RECEIVED_AT_RECEIVER_WAREHOUSE':
        return 'Arrived';
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool _isToday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final local = dateTime.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  String _todayStockGroupLabel(List<BranchLogisticsShipment> shipments) {
    final todayShipments = shipments.where((shipment) => _isToday(shipment.createdAt)).toList();
    if (todayShipments.isEmpty) return 'No new stock today';
    if (todayShipments.any((shipment) =>
        shipment.status == 'RECEIVED_AT_RECEIVER_WAREHOUSE' ||
        shipment.status == 'READY_FOR_PICKUP' ||
        shipment.status == 'COMPLETED')) {
      return 'Today stock arrived';
    }
    if (todayShipments.any((shipment) => shipment.status == 'IN_TRANSIT')) {
      return 'Today stock delivering';
    }
    if (todayShipments.any(
      (shipment) => shipment.status == 'RECEIVED_AT_SENDER_WAREHOUSE',
    )) {
      return 'Today stock collected';
    }
    if (todayShipments.any((shipment) => shipment.status == 'ASSIGNED')) {
      return 'Today stock not yet collected';
    }
    return 'Today stock waiting for driver';
  }

  String _groupActionStateLabel(List<BranchLogisticsShipment> shipments) {
    if (shipments.any((shipment) => shipment.status == 'IN_TRANSIT')) {
      return 'Group status: Delivering';
    }
    if (shipments.any(
      (shipment) => shipment.status == 'RECEIVED_AT_RECEIVER_WAREHOUSE',
    )) {
      return 'Group status: Arrived';
    }
    if (shipments.any(
      (shipment) => shipment.status == 'RECEIVED_AT_SENDER_WAREHOUSE',
    )) {
      return 'Group status: Collected';
    }
    if (shipments.any((shipment) => shipment.status == 'ASSIGNED')) {
      return 'Group status: Not Yet Collected';
    }
    if (shipments.any((shipment) => shipment.status == 'CREATED')) {
      return 'Group status: Waiting for Driver';
    }
    return 'Group status: Mixed';
  }

  String _routeLabel(BranchLogisticsShipment shipment) {
    final from = shipment.senderBranch?.operationLabel ?? 'Sender Branch';
    final to = shipment.receiverBranch?.operationLabel ?? 'Receiver Branch';
    return '$from -> $to';
  }

  String _branchOperationLabel(BranchLogisticsShipment shipment) {
    final fromOwner = shipment.senderBranch?.ownerName?.trim();
    final toOwner = shipment.receiverBranch?.ownerName?.trim();
    final from = (fromOwner != null && fromOwner.isNotEmpty)
        ? fromOwner
        : shipment.senderBranch?.name ?? 'Sender Branch';
    final to = (toOwner != null && toOwner.isNotEmpty)
        ? toOwner
        : shipment.receiverBranch?.name ?? 'Receiver Branch';
    return '$from -> $to';
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

  String _assignedDriverLabel(BranchLogisticsShipment shipment) {
    final driver = shipment.assignedDriver;
    final vehicle = shipment.assignedVehicle;
    if (driver == null) {
      return 'Waiting for available branch driver';
    }

    final parts = <String>[driver.name];
    if (vehicle != null && vehicle.code.trim().isNotEmpty) {
      parts.add(vehicle.code.trim());
    }
    if (driver.phone != null && driver.phone!.trim().isNotEmpty) {
      parts.add(driver.phone!.trim());
    }
    return parts.join(' | ');
  }

  String _assignmentTimeLabel(BranchLogisticsShipment shipment) {
    if (shipment.assignedAt == null) {
      return 'Not assigned yet';
    }
    final driverName = shipment.assignedDriver?.name ?? 'Driver';
    return '$driverName | ${_dateLabel(shipment.assignedAt)}';
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
        _buildTopBar(),
        const SizedBox(height: 16),
        _buildShipmentsList(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                      'Branch Logistics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Create ticket first, group by destination, then assign one branch driver and vehicle for the prepared trip.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreateTicketDialog,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Ticket'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _filterChip(
                label: 'All',
                selected: _directionFilter == 'all',
                onTap: () async {
                  setState(() => _directionFilter = 'all');
                  await _loadData();
                },
              ),
              _filterChip(
                label: 'Outbound',
                selected: _directionFilter == 'outbound',
                onTap: () async {
                  setState(() => _directionFilter = 'outbound');
                  await _loadData();
                },
              ),
              _filterChip(
                label: 'Inbound',
                selected: _directionFilter == 'inbound',
                onTap: () async {
                  setState(() => _directionFilter = 'inbound');
                  await _loadData();
                },
              ),
              _filterChip(
                label: 'Active',
                selected: _statusFilter == 'active',
                onTap: () async {
                  setState(() => _statusFilter = 'active');
                  await _loadData();
                },
              ),
              _filterChip(
                label: 'Completed',
                selected: _statusFilter == 'completed',
                onTap: () async {
                  setState(() => _statusFilter = 'completed');
                  await _loadData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentsList() {
    final groupedShipments = <String, List<BranchLogisticsShipment>>{};
    for (final shipment in _visibleShipments.take(12)) {
      final key = shipment.receiverBranch?.name ?? 'No destination branch';
      groupedShipments.putIfAbsent(key, () => <BranchLogisticsShipment>[]).add(shipment);
    }

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
                  'Logistics Tickets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                '${_visibleShipments.length} item(s)',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_visibleShipments.isEmpty)
            const BranchOwnerMessageCard(
              title: 'No logistics ticket yet',
              description: 'No ticket matches this filter yet.',
            )
          else
            ...groupedShipments.entries.map(
              (entry) => _destinationGroupCard(
                destinationName: entry.key,
                shipments: entry.value,
              ),
            ),
        ],
      ),
    );
  }

  Widget _destinationGroupCard({
    required String destinationName,
    required List<BranchLogisticsShipment> shipments,
  }) {
    final hasVip = shipments.any(_isVip);
    final hasDayThree = shipments.any(_isStandardDayThree);
    final todayStockLabel = _todayStockGroupLabel(shipments);
    final groupActionStateLabel = _groupActionStateLabel(shipments);
    final selectableShipments =
        shipments.where(_isTripSelectable).toList(growable: false);
    final selectedShipments = selectableShipments
        .where((shipment) => _selectedTripTicketIds.contains(shipment.id))
        .toList(growable: false);
    final assignedTripSummaries = _assignedTripSummaries(shipments);
    final selectedStock = selectedShipments.fold<int>(
      0,
      (sum, shipment) => sum + _packageStockCount(shipment),
    );
    final availableCapacityDrivers = _availableTripDrivers
        .where((driver) {
          final vehicle = _assignedBranchVehicleForDriver(driver);
          if (vehicle == null) return false;
          final activeLoad = _vehicleTripLoad(vehicle);
          final stockLimit = vehicle.maxPackageCount;
          if (stockLimit == null) return true;
          return activeLoad.stock < stockLimit;
        })
        .toList(growable: false);
    final mixMessage = hasVip
        ? 'VIP tickets can leave same day and can be mixed with standard tickets for this destination if capacity allows.'
        : hasDayThree
            ? 'Standard day-3 tickets should be prioritized on the next branch-logistics trip.'
            : 'Group these tickets into one branch-logistics trip when driver and vehicle are ready.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                      destinationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _badge(
                          todayStockLabel,
                          const Color(0xFFEFF6FF),
                          const Color(0xFF1D4ED8),
                        ),
                        _badge(
                          'Driver collects after assignment',
                          const Color(0xFFF1F5F9),
                          const Color(0xFF475569),
                        ),
                        _badge(
                          groupActionStateLabel,
                          const Color(0xFFF8FAFC),
                          const Color(0xFF334155),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _badge(
                '${shipments.length} ticket(s)',
                const Color(0xFFE2E8F0),
                const Color(0xFF334155),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mixMessage,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          if (assignedTripSummaries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Monitor',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...assignedTripSummaries.map(
                    (summary) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${summary.vehicleCode} | ${summary.driverName}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _badge(
                                summary.statusLabel,
                                const Color(0xFFEFF6FF),
                                const Color(0xFF1D4ED8),
                              ),
                              _badge(
                                '${summary.ticketCount} ticket(s)',
                                const Color(0xFFF1F5F9),
                                const Color(0xFF475569),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Used capacity: ${summary.usedCapacityLabel}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Assigned time: ${summary.assignedTimeLabel}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (selectableShipments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Prepare trip: ${selectedShipments.length}/${selectableShipments.length} tickets',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Stock $selectedStock packages',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (availableCapacityDrivers.isNotEmpty)
                    Text(
                      'Truck ready: ${_truckCapacitySummary(_assignedBranchVehicleForDriver(availableCapacityDrivers.first)!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: () {
                      final selectAll =
                          selectedShipments.length != selectableShipments.length;
                      setState(() {
                        for (final shipment in selectableShipments) {
                          if (selectAll) {
                            _selectedTripTicketIds.add(shipment.id);
                          } else {
                            _selectedTripTicketIds.remove(shipment.id);
                          }
                        }
                      });
                    },
                    child: Text(
                      selectedShipments.length == selectableShipments.length
                          ? 'Clear Group'
                          : 'Select Group',
                    ),
                  ),
                  FilledButton(
                    onPressed: selectedShipments.isEmpty
                        ? null
                        : () => _showPreparedTripDialog(
                              destinationName: destinationName,
                              shipments: selectedShipments,
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                    ),
                    child: const Text('Prepare Trip'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...shipments.map(_shipmentCard),
        ],
      ),
    );
  }

  Widget _shipmentCard(BranchLogisticsShipment shipment) {
    final isOutbound = shipment.isOutboundFor(widget.ownedBranch!.id);
    final actions = _actionsForShipment(shipment, isOutbound);
    final selectable = _isTripSelectable(shipment);
    final selected = _selectedTripTicketIds.contains(shipment.id);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            shipment.ticketNumber,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (selectable)
                      Checkbox(
                        value: selected,
                        onChanged: (value) =>
                            _toggleTripSelection(shipment, value ?? false),
                      ),
                    Expanded(
                      child: Text(
                        '${shipment.sender.name} -> ${shipment.receiver.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _badge(
                      _statusLabel(shipment.status),
                      const Color(0xFFE2E8F0),
                      const Color(0xFF334155),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _badge(
                      _serviceLevelLabel(shipment),
                      _serviceLevelBackground(shipment),
                      _serviceLevelForeground(shipment),
                    ),
                    _badge(
                      _urgencyLabel(shipment),
                      _urgencyBackground(shipment),
                      _urgencyForeground(shipment),
                    ),
                    _badge(
                      'Stock ${_packageStockLabel(shipment)}',
                      const Color(0xFFDBEAFE),
                      const Color(0xFF1D4ED8),
                    ),
                    _badge(
                      'Price ${_ticketPricingLabel(shipment)}',
                      const Color(0xFFE0F2FE),
                      const Color(0xFF075985),
                    ),
                    Text(
                      _routeLabel(shipment),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (selectable)
                      const Text(
                        'Mixable for trip',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                shipment.itemDescription,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _pricingHighlightCard(shipment),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryLine(
                  isOutbound ? 'Direction' : 'Direction',
                  isOutbound ? 'Outbound' : 'Inbound',
                ),
                const SizedBox(height: 6),
                _summaryLine(
                  'Sender',
                  _contactLabel(shipment.sender.name, shipment.sender.phone),
                ),
                const SizedBox(height: 6),
                _summaryLine(
                  'Receiver',
                  _contactLabel(shipment.receiver.name, shipment.receiver.phone),
                ),
                const SizedBox(height: 6),
                _summaryLine(
                  'Package size',
                  _packageSizeLabel(shipment),
                ),
                const SizedBox(height: 6),
                _summaryLine('Assigned driver', _assignedDriverLabel(shipment)),
                const SizedBox(height: 6),
                _summaryLine('Assigned time', _assignmentTimeLabel(shipment)),
                const SizedBox(height: 6),
                _summaryLine('Package ID', _stockIdLabel(shipment)),
                const SizedBox(height: 6),
                _summaryLine('Service level', _serviceLevelLabel(shipment)),
                const SizedBox(height: 6),
                _summaryLine('Priority', _urgencyLabel(shipment)),
                const SizedBox(height: 6),
                _summaryLine(
                  'Ticket payment',
                  '${shipment.paymentStatus} | ${_money(shipment.amountPaid, shipment.currency)}',
                ),
                const SizedBox(height: 6),
                _summaryLine(
                  'Stock batch',
                  _packageStockLabel(shipment),
                ),
                const SizedBox(height: 6),
                _summaryLine('Route', _routeLabel(shipment)),
                const SizedBox(height: 6),
                _summaryLine('Operation', _branchOperationLabel(shipment)),
                const SizedBox(height: 6),
                _summaryLine('Date', _dateLabel(shipment.createdAt)),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _actionsForShipment(
    BranchLogisticsShipment shipment,
    bool isOutbound,
  ) {
    final actions = <Widget>[];

    switch (shipment.status) {
      case 'RECEIVED_AT_RECEIVER_WAREHOUSE':
        if (!isOutbound) {
          actions.addAll([
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
          ]);
        }
        break;
      case 'READY_FOR_PICKUP':
        if (!isOutbound) {
          actions.add(
            FilledButton(
              onPressed: () => _updateShipment(shipment, 'complete'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
              ),
              child: const Text('Mark Picked Up'),
            ),
          );
        }
        break;
      default:
        break;
    }

    return actions;
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

  Widget _branchDropdown({
    ValueChanged<String?>? onChanged,
    double width = 320,
  }) {
    return SizedBox(
      width: width,
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
        onChanged: onChanged ??
            (value) {
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

  Widget _userDropdown({
    required String label,
    required String? value,
    required List<UserProfile> users,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: users.any((user) => user.id == value) ? value : null,
      items: users
          .map(
            (user) => DropdownMenuItem(
              value: user.id,
              child: Text(
                '${user.name} (${user.phone ?? '-'})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      validator: (selected) => selected == null ? 'Select user account' : null,
      onChanged: onChanged,
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

  Widget _deliveryTypeChip({
    required BranchLogisticsPricingMode mode,
    required String label,
    required String helper,
    required VoidCallback onSelected,
  }) {
    final selected = _deliveryType == mode;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF1D4ED8)
                : const Color(0xFFE2E8F0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              helper,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
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

  Widget _pricingHighlightCard(BranchLogisticsShipment shipment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Color(0xFF1D4ED8),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ticket Pricing',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${shipment.paymentStatus} | ${_ticketPricingLabel(shipment)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _dialogInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _detailLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _VehicleTripLoad {
  final int stock;
  final double weightKg;

  const _VehicleTripLoad({
    required this.stock,
    required this.weightKg,
  });
}

class _AssignedTripSummary {
  final String vehicleCode;
  final String driverName;
  final String statusLabel;
  final String usedCapacityLabel;
  final String assignedTimeLabel;
  final int ticketCount;

  const _AssignedTripSummary({
    required this.vehicleCode,
    required this.driverName,
    required this.statusLabel,
    required this.usedCapacityLabel,
    required this.assignedTimeLabel,
    required this.ticketCount,
  });
}
