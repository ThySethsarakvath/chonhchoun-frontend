import 'package:flutter/material.dart';
import '../../admin_management/models/branch_model.dart';
import '../../admin_management/services/branch_service.dart';
import '../../branch_logistics/models/branch_logistics_models.dart';
import '../../branch_logistics/services/branch_logistics_service.dart';
import '../../driver_registration/models/driver_management_model.dart';
import '../../driver_registration/services/driver_application_service.dart';
import '../models/dispatch_receipt_models.dart';
import '../services/dispatch_receipt_service.dart';

class CreateDispatchReceiptScreen extends StatefulWidget {
  const CreateDispatchReceiptScreen({super.key});

  @override
  State<CreateDispatchReceiptScreen> createState() =>
      _CreateDispatchReceiptScreenState();
}

class _CreateDispatchReceiptScreenState
    extends State<CreateDispatchReceiptScreen> {
  final _dispatchService = DispatchReceiptService();
  final _branchService = BranchService();
  final _driverAppService = DriverApplicationService();
  final _logisticsService = BranchLogisticsService();

  bool _loading = true;
  List<ManagedDriver> _availableDrivers = [];
  List<Branch> _allBranches = [];
  List<BranchLogisticsShipment> _availableShipments = [];

  String? _selectedDriverId;
  final List<CreateDispatchReceiptStopDto> _stops = [];
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _driverAppService.getBranchOwnerManagementOverview(),
        _branchService.getMapBranches(),
        _logisticsService.listShipments(direction: 'outbound', status: 'CREATED'),
      ]);

      final overview = results[0] as BranchDriverManagementOverview;
      final branches = results[1] as List<Branch>;
      final shipments = results[2] as List<BranchLogisticsShipment>;

      if (!mounted) return;
      setState(() {
        _availableDrivers = overview.drivers
            .where((d) => d.availabilityStatus == 'AVAILABLE' && d.isActive)
            .toList();
        _allBranches = branches;
        _availableShipments = shipments
            .where((s) => s.dispatchReceiptId == null)
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _addStop() {
    showDialog(
      context: context,
      builder: (ctx) {
        String? selectedBranchId;
        final selectedShipmentIds = <String>{};

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Filter shipments whose receiver is the selected branch
            // and which are not already in another stop
            final usedShipmentIds = _stops.expand((s) => s.shipmentIds).toSet();
            final validShipments = _availableShipments.where((s) {
              if (usedShipmentIds.contains(s.id)) return false;
              if (selectedBranchId == null) return true;
              return s.receiverBranch?.id == selectedBranchId;
            }).toList();

            return AlertDialog(
              title: const Text('Add Stop'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Destination Branch'),
                      value: selectedBranchId,
                      items: _allBranches
                          .map((b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(b.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedBranchId = val;
                          selectedShipmentIds.clear(); // reset when branch changes
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Shipments:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (selectedBranchId == null)
                      const Text('Select a destination branch first.')
                    else if (validShipments.isEmpty)
                      const Text('No shipments available for this destination.')
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: validShipments.length,
                          itemBuilder: (context, index) {
                            final s = validShipments[index];
                            return CheckboxListTile(
                              title: Text(s.ticketNumber),
                              subtitle: Text(s.itemDescription),
                              value: selectedShipmentIds.contains(s.id),
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (val == true) {
                                    selectedShipmentIds.add(s.id);
                                  } else {
                                    selectedShipmentIds.remove(s.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedBranchId == null || selectedShipmentIds.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _stops.add(
                              CreateDispatchReceiptStopDto(
                                stopOrder: _stops.length + 1,
                                destinationBranchId: selectedBranchId!,
                                shipmentIds: selectedShipmentIds.toList(),
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                        },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
      // Re-adjust stop orders
      for (int i = 0; i < _stops.length; i++) {
        final stop = _stops[i];
        _stops[i] = CreateDispatchReceiptStopDto(
          stopOrder: i + 1,
          destinationBranchId: stop.destinationBranchId,
          shipmentIds: stop.shipmentIds,
        );
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedDriverId == null || _stops.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await _dispatchService.createReceipt(
        CreateDispatchReceiptDto(
          driverId: _selectedDriverId!,
          stops: _stops,
          notes: _notesCtrl.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Dispatch Receipt')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Dispatch Receipt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Driver',
              border: OutlineInputBorder(),
            ),
            value: _selectedDriverId,
            items: _availableDrivers
                .map((d) => DropdownMenuItem(
                      value: d.id,
                      child: Text('${d.name} (${d.phone})'),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedDriverId = val),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addStop,
                icon: const Icon(Icons.add),
                label: const Text('Add Stop'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_stops.isEmpty)
            const Text('No stops added yet. Add stops to create a receipt.')
          else
            ..._stops.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              final branch = _allBranches.firstWhere((b) => b.id == stop.destinationBranchId);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Stop ${stop.stopOrder}: ${branch.name}'),
                  subtitle: Text('${stop.shipmentIds.length} shipments'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeStop(index),
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_selectedDriverId == null || _stops.isEmpty || _submitting)
                  ? null
                  : _submit,
              child: _submitting
                  ? const CircularProgressIndicator()
                  : const Text('Create Receipt'),
            ),
          ),
        ],
      ),
    );
  }
}
