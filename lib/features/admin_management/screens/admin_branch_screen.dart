import 'package:flutter/material.dart';
import '../models/branch_model.dart';
import '../services/branch_service.dart';
import '../widgets/branch_performance_card.dart';
import '../../auth/widgets/auth_widgets.dart';

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
      if (mounted) showErrorDialog(context, "មិនអាចទាញយកទិន្នន័យបានទេ");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('កំហុស (Error)', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('យល់ព្រម'),
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
        title: const Text('ផ្ទាំងគ្រប់គ្រងប្រតិបត្តិការសាខា',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A5F),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded)),
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
                    mainAxisExtent: 260,
                  ),
                  itemCount: _branches.length,
                  itemBuilder: (context, index) => BranchPerformanceCard(branch: _branches[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A5F),
        onPressed: () {}, // TODO: Open Create Branch Dialog
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("បង្កើតសាខាថ្មី", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("មិនទាន់មានសាខានៅឡើយទេ", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}