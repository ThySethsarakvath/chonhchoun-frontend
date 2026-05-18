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
            constraints: const BoxConstraints(minWidth: 980),
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 28,
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Created')),
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
      ],
    );
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
