import 'dart:io';

import 'package:flutter/material.dart';

import '../../admin_management/models/branch_model.dart';

class DriverApplicationHeader extends StatelessWidget {
  const DriverApplicationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ដាក់ពាក្យអ្នកបើកបរ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2D3D),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'ដាក់ពាក្យធ្វើការក្រោមការគ្រប់គ្រងរបស់ម្ចាស់សាខា។ យើងនឹងផ្ញើអ៊ីមែលជូនអ្នកបន្ទាប់ពីម្ចាស់សាខាពិនិត្យពាក្យស្នើសុំរបស់អ្នករួច។',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7A8D)),
        ),
      ],
    );
  }
}

class DriverAvatarPicker extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onTap;

  const DriverAvatarPicker({
    super.key,
    required this.imageFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFD6E8F5),
              backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
              child: imageFile == null
                  ? const Icon(
                      Icons.add_a_photo_outlined,
                      color: Color(0xFF2C5F8A),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'ចុចដើម្បីបង្ហោះរូបភាពប្រវត្តិរូប',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7A8D)),
          ),
        ),
      ],
    );
  }
}

class DriverBranchDropdown extends StatelessWidget {
  final List<Branch> branches;
  final String? selectedBranchId;
  final bool loading;
  final ValueChanged<String?>? onChanged;

  const DriverBranchDropdown({
    super.key,
    required this.branches,
    required this.selectedBranchId,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ជ្រើសរើសសាខា',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E2D3D),
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedBranchId,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE3EE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE3EE)),
            ),
          ),
          hint: Text(loading ? 'កំពុងផ្ទុកសាខា...' : 'សូមជ្រើសរើសសាខា'),
          items: branches
              .map(
                (branch) => DropdownMenuItem<String>(
                  value: branch.id,
                  child: Text(_branchLabel(branch)),
                ),
              )
              .toList(),
          onChanged: loading ? null : onChanged,
        ),
      ],
    );
  }

  String _branchLabel(Branch branch) {
    final branchNumber = branch.branchNumber?.toString() ?? '1';
    final address = (branch.address ?? '').trim();
    if (address.isNotEmpty) {
      return 'សាខា $branchNumber ($address)';
    }
    return 'សាខា $branchNumber';
  }
}

class DriverDocumentPickerTile extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback onTap;

  const DriverDocumentPickerTile({
    super.key,
    required this.label,
    required this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE3EE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.upload_file_rounded, color: Color(0xFF2C5F8A)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName == null ? label : '$label: $fileName',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D3A4E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
