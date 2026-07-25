import 'package:flutter/material.dart';

import '../models/branch_model.dart';
import '../services/branch_service.dart';
import '../widgets/branch_performance_card.dart';

class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  final BranchService _service = BranchService();

  List<Branch> _branches = [];
  bool _loading = false;

  List<Branch> _sortBranches(List<Branch> branches) {
    final sorted = List<Branch>.from(branches);
    sorted.sort((a, b) {
      final aNumber = a.branchNumber;
      final bNumber = b.branchNumber;

      if (aNumber != null && bNumber != null) {
        return aNumber.compareTo(bNumber);
      }
      if (aNumber != null) return -1;
      if (bNumber != null) return 1;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);

    try {
      final data = await _service.getAllBranches();
      if (!mounted) return;

      setState(() => _branches = _sortBranches(data));
    } catch (_) {
      if (!mounted) return;
      _showErrorDialog(
        'Unable to load branch data right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openEditBranchDialog(Branch branch) async {
    final nameController = TextEditingController(text: branch.name);
    final addressController = TextEditingController(text: branch.address ?? '');
    final phoneController = TextEditingController(
      text: branch.phone ?? branch.ownerPhone ?? '',
    );
    final descriptionController = TextEditingController(
      text: branch.description ?? '',
    );
    final latitudeController = TextEditingController(
      text: branch.lat?.toString() ?? '',
    );
    final longitudeController = TextEditingController(
      text: branch.lng?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text('Edit ${branch.name}'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Branch name',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Enter a branch name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Enter an address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descriptionController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: '11.5564',
                        ),
                        validator: (value) {
                          final parsed = double.tryParse((value ?? '').trim());
                          if (parsed == null) return 'Enter a valid latitude';
                          if (parsed < -90 || parsed > 90) {
                            return 'Latitude must be between -90 and 90';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: '104.9282',
                        ),
                        validator: (value) {
                          final parsed = double.tryParse((value ?? '').trim());
                          if (parsed == null) return 'Enter a valid longitude';
                          if (parsed < -180 || parsed > 180) {
                            return 'Longitude must be between -180 and 180';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final latitude = double.parse(
                            latitudeController.text.trim(),
                          );
                          final longitude = double.parse(
                            longitudeController.text.trim(),
                          );

                          setDialogState(() => saving = true);
                          try {
                            final updated = await _service.updateBranch(
                              branchId: branch.id,
                              name: nameController.text.trim(),
                              address: addressController.text.trim(),
                              phone: phoneController.text.trim(),
                              description:
                                  descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                              latitude: latitude,
                              longitude: longitude,
                            );

                            if (!mounted) return;

                            setState(() {
                              _branches = _sortBranches(
                                _branches
                                    .map(
                                      (item) =>
                                          item.id == updated.id
                                          ? updated
                                          : item,
                                    )
                                    .toList(),
                              );
                            });

                            Navigator.pop(dialogContext);
                            _showSnackBar(
                              'Branch details updated successfully.',
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() => saving = false);
                            _showSnackBar(e.toString());
                          }
                        },
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      nameController.dispose();
      addressController.dispose();
      phoneController.dispose();
      descriptionController.dispose();
      latitudeController.dispose();
      longitudeController.dispose();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Something went wrong',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Branch Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A5F),
        actions: [
          IconButton(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh branches',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _branches.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                mainAxisExtent: 240,
              ),
              itemCount: _branches.length,
              itemBuilder: (context, index) {
                final branch = _branches[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openEditBranchDialog(branch),
                  child: BranchPerformanceCard(branch: branch),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No branches available yet.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
