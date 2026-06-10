import 'package:flutter/material.dart';
import '../../features/admin_management/models/branch_model.dart';
import '../../features/admin_management/services/branch_service.dart';
import '../../features/auth/services/auth_service.dart'; 
import '../../features/auth/widgets/auth_scaffold.dart';
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
    : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('កូដ (Code)')),
              DataColumn(label: Text('ឈ្មោះសាខា (Name)')),
              DataColumn(label: Text('អាសយដ្ឋាន (Address)')),
              DataColumn(label: Text('ស្ថានភាព (Status)')),
              DataColumn(label: Text('សកម្មភាព (Actions)')),
            ],
            rows: _branches.map((branch) => DataRow(cells: [
              DataCell(Text(branch.code ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(branch.name)),
              DataCell(Text(branch.address ?? 'N/A')),
              DataCell(Icon(
                Icons.circle,
                size: 12,
                color: branch.isActive ? Colors.green : Colors.red,
              )),
              DataCell(IconButton(icon: const Icon(Icons.edit_note), onPressed: () {})),
            ])).toList(),
          ),
        ),
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
