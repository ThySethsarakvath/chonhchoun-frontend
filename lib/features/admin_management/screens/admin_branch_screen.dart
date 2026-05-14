import 'package:flutter/material.dart';
import '../../features/admin_management/models/branch_model.dart';
import '../../features/admin_management/services/branch_service.dart';
import '../../features/auth/widgets/auth_widgets.dart';

class AdminBranchScreen extends StatefulWidget {
  const AdminBranchScreen({super.key});

  @override
  State<AdminBranchScreen> createState() => _AdminBranchScreenState();
}

class _AdminBranchScreenState extends State<AdminBranchScreen> {
  final _service = BranchService();
  List<Branch> _branches = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAllBranches();
      setState(() => _branches = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('គ្រប់គ្រងសាខា')),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _branches.length,
            itemBuilder: (context, index) {
              final branch = _branches[index];
              return ListTile(
                title: Text(branch.name),
                subtitle: Text(branch.code),
                trailing: Icon(Icons.circle, color: branch.isActive ? Colors.green : Colors.red),
              );
            },
          ),
    );
  }
}