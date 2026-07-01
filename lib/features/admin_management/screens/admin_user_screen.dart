import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../auth/widgets/auth_scaffold.dart';
import '../models/admin_user_model.dart';
import '../services/admin_user_service.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final _service = AdminUserService();
  final _searchCtrl = TextEditingController();

  List<AdminUser> _users = [];
  bool _loading = false;
  String? _upgradingUserId;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_handleSearchChanged);
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() => _searchTerm = _searchCtrl.text.trim().toLowerCase());
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final users = await _service.getUsers();
      if (mounted) {
        setState(() => _users = users);
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (_) {
      if (mounted) showErrorDialog(context, 'Unable to load users.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AdminUser> get _filteredUsers {
    if (_searchTerm.isEmpty) return _users;

    return _users.where((user) {
      return user.name.toLowerCase().contains(_searchTerm) ||
          user.email.toLowerCase().contains(_searchTerm) ||
          (user.phone ?? '').toLowerCase().contains(_searchTerm) ||
          user.role.toLowerCase().contains(_searchTerm);
    }).toList();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';

    final monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${value.day.toString().padLeft(2, '0')} ${monthNames[value.month - 1]} ${value.year}';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'customer':
        return 'Customer';
      case 'driver':
        return 'Driver';
      case 'branch_owner':
        return 'Branch Owner';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  String _friendlyUpgradeError(ApiException error, AdminUser user) {
    final message = error.message.toLowerCase();

    if (message.contains('only customer accounts can be upgraded')) {
      return '${user.name} cannot be upgraded because this account is currently ${_roleLabel(user.role)}, not Customer.';
    }

    if (message.contains('a branch already exists for this branch owner')) {
      return '${user.name} already has a branch assigned. Please downgrade or reassign that branch first.';
    }

    if (message.contains('user not found')) {
      return 'This user record could not be found anymore. Refresh the user list and try again.';
    }

    if (message.contains('invalid user id')) {
      return 'This user cannot be upgraded because the selected account ID is invalid.';
    }

    if (message.contains('forbidden') || error.statusCode == 403) {
      return 'Only an admin account can upgrade a user to Branch Owner.';
    }

    if (message.contains('unauthorized') || error.statusCode == 401) {
      return 'Your admin session expired. Please sign in again and retry the upgrade.';
    }

    return 'Unable to upgrade ${user.name} to Branch Owner. ${error.message}';
  }

  String _friendlyDowngradeError(ApiException error, AdminUser user) {
    final message = error.message.toLowerCase();

    if (message.contains('only branch owner accounts can be downgraded')) {
      return '${user.name} cannot be downgraded because this account is currently ${_roleLabel(user.role)}, not Branch Owner.';
    }

    if (message.contains('user not found')) {
      return 'This user record could not be found anymore. Refresh the user list and try again.';
    }

    if (message.contains('forbidden') || error.statusCode == 403) {
      return 'Only an admin account can downgrade a Branch Owner.';
    }

    if (message.contains('unauthorized') || error.statusCode == 401) {
      return 'Your admin session expired. Please sign in again and retry the downgrade.';
    }

    return 'Unable to downgrade ${user.name}. ${error.message}';
  }

  Future<void> _openUpgradeDialog(AdminUser user) async {
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final addressCtrl = TextEditingController();
    final latitudeCtrl = TextEditingController();
    final longitudeCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Upgrade ${user.name}'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogField(
                    controller: phoneCtrl,
                    label: 'Phone',
                    hintText: '+855...',
                  ),
                  const SizedBox(height: 12),
                  _DialogField(
                    controller: addressCtrl,
                    label: 'Address',
                    hintText: 'Phnom Penh',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DialogField(
                          controller: latitudeCtrl,
                          label: 'Latitude',
                          hintText: '11.5564',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DialogField(
                          controller: longitudeCtrl,
                          label: 'Longitude',
                          hintText: '104.9282',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final latitude = double.tryParse(latitudeCtrl.text.trim());
                final longitude = double.tryParse(longitudeCtrl.text.trim());

                if (phoneCtrl.text.trim().isEmpty ||
                    addressCtrl.text.trim().isEmpty ||
                    latitude == null ||
                    longitude == null) {
                  showErrorDialog(
                    dialogContext,
                    'Please complete all branch owner fields: phone, address, latitude, and longitude.',
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                await _upgradeUser(
                  user,
                  UpgradeBranchOwnerRequest(
                    phone: phoneCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    latitude: latitude,
                    longitude: longitude,
                  ),
                );
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upgradeUser(
    AdminUser user,
    UpgradeBranchOwnerRequest request,
  ) async {
    setState(() => _upgradingUserId = user.id);
    try {
      await _service.upgradeToBranchOwner(userId: user.id, request: request);
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} is now a branch owner.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, _friendlyUpgradeError(e, user));
    } catch (_) {
      if (mounted) {
        showErrorDialog(
          context,
          'Unable to upgrade ${user.name} right now. Please verify the account is still a Customer and does not already own a branch.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _upgradingUserId = null);
      }
    }
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, email, phone, or role',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _StatCard(label: 'Total Users', value: '${_users.length}'),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Active Users',
            value: '${_users.where((user) => user.isActive).length}',
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1180),
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 28,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Created')),
                  DataColumn(label: Text('Action')),
                ],
                rows: _filteredUsers.map(_buildRow).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(AdminUser user) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(Text(user.email)),
        DataCell(Text(user.phone ?? '-')),
        DataCell(Text(user.role)),
        DataCell(_StatusPill(isActive: user.isActive)),
        DataCell(Text(_formatDate(user.createdAt))),
        DataCell(_buildActionCell(user)),
      ],
    );
  }

  Widget _buildActionCell(AdminUser user) {
    if (user.role == 'branch_owner') {
      final isBusy = _upgradingUserId == user.id;

      return FilledButton.tonal(
        onPressed: isBusy ? null : () => _confirmDowngrade(user),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFEE2E2),
          foregroundColor: const Color(0xFFB42318),
        ),
        child: isBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Downgrade Branch Owner'),
      );
    }

    if (user.role != 'customer') {
      return const Text(
        'Unavailable',
        style: TextStyle(color: Colors.grey),
      );
    }

    final isBusy = _upgradingUserId == user.id;

    return FilledButton.tonal(
      onPressed: isBusy ? null : () => _openUpgradeDialog(user),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFE0F2FE),
        foregroundColor: const Color(0xFF0F4C81),
      ),
      child: isBusy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Upgrade to Branch Owner'),
    );
  }

  Future<void> _confirmDowngrade(AdminUser user) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Downgrade ${user.name}?'),
        content: const Text(
          'This will change the user back to customer and suspend the assigned branch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _downgradeUser(user);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            child: const Text('Downgrade'),
          ),
        ],
      ),
    );
  }

  Future<void> _downgradeUser(AdminUser user) async {
    setState(() => _upgradingUserId = user.id);
    try {
      await _service.downgradeBranchOwner(userId: user.id);
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} has been downgraded to customer.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, _friendlyDowngradeError(e, user));
    } catch (_) {
      if (mounted) {
        showErrorDialog(
          context,
          'Unable to downgrade ${user.name} right now. Please try again after refreshing the user list.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _upgradingUserId = null);
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No users found for the current filter.',
            style: TextStyle(color: Colors.grey),
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
          'Admin Users',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A5F),
        actions: [
          IconButton(
            onPressed: _fetchUsers,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? _buildEmptyState()
                      : _buildTable(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;

  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final background =
        isActive ? const Color(0xFFE8F7EC) : const Color(0xFFFCEAEA);
    final foreground =
        isActive ? const Color(0xFF1B7F3A) : const Color(0xFFB42318);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}
