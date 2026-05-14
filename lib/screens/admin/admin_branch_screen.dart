import 'package:flutter/material.dart';
import '../../features/agencies_management/models/branch_model.dart';
import '../../features/agencies_management/services/branch_service.dart';
import '../../features/auth/services/auth_service.dart'; 
import '../../features/auth/widgets/auth_widgets.dart';

class AdminBranchScreen extends StatefulWidget {
  const AdminBranchScreen({super.key});

  @override
  State<AdminBranchScreen> createState() => _AdminBranchScreenState();
}

class _AdminBranchScreenState extends State<AdminBranchScreen> {
  final _service = BranchService();
  bool _loading = false;
  List<Branch> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAllBranches();
      setState(() => _branches = data);
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (_) {
      if (mounted) showErrorDialog(context, 'មានបញ្ហាបច្ចេកទេស');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('គ្រប់គ្រងសាខា', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: _loadBranches, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _branches.length,
              itemBuilder: (context, index) {
                final branch = _branches[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1E3A5F),
                      child: Text(branch.code[0], style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(branch.address ?? 'គ្មានអាសយដ្ឋាន'),
                    trailing: Icon(
                      Icons.circle_rounded,
                      size: 12,
                      color: branch.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A5F),
        onPressed: () {
          // TODO: Implement Create Branch Dialog
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}