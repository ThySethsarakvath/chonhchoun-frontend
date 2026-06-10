import 'dart:io';

import 'package:flutter/material.dart';

import '../../admin_management/models/branch_model.dart';
import '../models/vehicle_type.dart';

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

class DriverVehicleTypeDropdown extends StatelessWidget {
  final String? selectedVehicleType;
  final ValueChanged<String?>? onChanged;
  final List<VehicleTypeOption> options;
  final String label;
  final String hintText;

  const DriverVehicleTypeDropdown({
    super.key,
    required this.selectedVehicleType,
    required this.onChanged,
    this.options = vehicleTypeOptions,
    this.label = 'Vehicle type',
    this.hintText = 'Select your vehicle type',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E2D3D),
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedVehicleType,
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
          hint: Text(hintText),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.value,
                  child: Row(
                    children: [
                      Icon(option.icon, size: 18, color: const Color(0xFF2C5F8A)),
                      const SizedBox(width: 10),
                      Text(option.label),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class DriverApplicationVehicleChoice extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const DriverApplicationVehicleChoice({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'តើអ្នកនឹងប្រើយានជំនិះប្រភេទណា?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E2D3D),
              ),
        ),
        const SizedBox(height: 8),
        _VehicleChoiceTile(
          selected: selectedValue == driverOwnMotorcycleType,
          title: 'ម៉ូតូផ្ទាល់ខ្លួន',
          subtitle: 'សូមប្រើម៉ូតូផ្ទាល់ខ្លួនរបស់អ្នកសម្រាប់ការងារដឹកជញ្ជូន។',
          icon: Icons.two_wheeler_rounded,
          onTap: () => onChanged(driverOwnMotorcycleType),
        ),
        const SizedBox(height: 10),
        _VehicleChoiceTile(
          selected: selectedValue == driverBranchTruckChoice,
          title: 'បើកឡានរបស់សាខា',
          subtitle:
              'សាខានឹងផ្ដល់ឡានឲ្យអ្នកបន្ទាប់ពីការស្នើសុំត្រូវបានអនុម័ត។',
          icon: Icons.local_shipping_rounded,
          onTap: () => onChanged(driverBranchTruckChoice),
        ),
      ],
    );
  }
}

class _VehicleChoiceTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _VehicleChoiceTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF4A8DDB) : const Color(0xFFDDE3EE),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2C5F8A)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2D3D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7A8D),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: const Color(0xFF2C5F8A),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverDocumentPickerTile extends StatelessWidget {
  final String label;
  final String? fileName;
  final String? helperText;
  final VoidCallback onTap;

  const DriverDocumentPickerTile({
    super.key,
    required this.label,
    required this.fileName,
    this.helperText,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            if (helperText != null && helperText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                helperText!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7A8D),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
