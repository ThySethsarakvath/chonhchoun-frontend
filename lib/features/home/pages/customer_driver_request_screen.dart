import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../router/app_router.dart';
import '../../admin_management/models/branch_model.dart';
import '../../admin_management/services/branch_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/user_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../../auth/widgets/auth_scaffold.dart';
import '../../driver_registration/models/vehicle_type.dart';
import '../../driver_registration/services/driver_application_service.dart';

const _requestAccent = Color(0xFF5B6C8F);
const _requestAccentDark = Color(0xFF32435C);
const _requestSurface = Color(0xFFF7F8FB);
const _requestBorder = Color(0xFFE2E7F0);

class CustomerDriverRequestScreen extends StatefulWidget {
  const CustomerDriverRequestScreen({super.key});

  @override
  State<CustomerDriverRequestScreen> createState() =>
      _CustomerDriverRequestScreenState();
}

class _CustomerDriverRequestScreenState
    extends State<CustomerDriverRequestScreen> {
  final _branchService = BranchService();
  final _userService = UserService();
  final _driverService = DriverApplicationService();
  final _picker = ImagePicker();
  final _plateNumberCtrl = TextEditingController();

  List<Branch> _branches = const [];
  UserProfile? _profile;
  String? _selectedBranchId;
  String _vehicleChoice = driverOwnMotorcycleType;
  String _ownVehicleType = driverOwnMotorcycleType;
  File? _avatarFile;
  File? _cvFile;
  File? _nationalIdFile;
  File? _drivingLicenseFile;
  bool _loading = true;
  bool _submitting = false;

  bool get _usesOwnVehicle => _vehicleChoice != driverBranchTruckChoice;

  bool get _requiresDrivingLicense {
    if (!_usesOwnVehicle) return true;
    return _ownVehicleType != driverOwnMotorcycleType;
  }

  bool get _showsPlateNumberField =>
      _usesOwnVehicle && _ownVehicleType != driverOwnMotorcycleType;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _plateNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('សូមចូលគណនីម្ដងទៀត។');
      }

      final results = await Future.wait([
        _branchService.getMapBranches(),
        _userService.getMe(accessToken: accessToken),
      ]);

      if (!mounted) return;
      final branches =
          (results[0] as List<Branch>).where((branch) => branch.isActive).toList();
      final profile = results[1] as UserProfile;

      setState(() {
        _branches = branches;
        _profile = profile;
        _selectedBranchId =
            branches.length == 1 ? branches.first.id : _selectedBranchId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showErrorDialog(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null || !mounted) return;
    setState(() => _avatarFile = File(picked.path));
  }

  Future<void> _pickDocument({
    required List<String> allowedExtensions,
    required void Function(File file) onSelected,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    final pickedPath = result?.files.single.path;
    if (pickedPath == null || !mounted) return;
    final pickedFile = File(pickedPath);
    setState(() => onSelected(pickedFile));
  }

  String? _fileName(File? file) {
    if (file == null) return null;
    return file.path.split(Platform.pathSeparator).last;
  }

  String _branchLabel(Branch branch) {
    final branchNumber = branch.branchNumber?.toString() ?? '1';
    final address = (branch.address ?? '').trim();
    if (address.isNotEmpty) {
      return 'សាខា $branchNumber - $address';
    }
    return 'សាខា $branchNumber';
  }

  String? _validate() {
    if (_profile == null) return 'មិនអាចទាញព័ត៌មានគណនីបានទេ។';
    if (_profile!.role != 'customer') {
      return 'មុខងារនេះសម្រាប់គណនីអតិថិជនប៉ុណ្ណោះ។';
    }
    if (_selectedBranchId == null || _selectedBranchId!.isEmpty) {
      return 'សូមជ្រើសរើសសាខា។';
    }
    if (_cvFile == null || _nationalIdFile == null) {
      return 'សូមបញ្ចូល CV និងអត្តសញ្ញាណប័ណ្ណជាមុនសិន។';
    }
    if (_requiresDrivingLicense && _drivingLicenseFile == null) {
      return 'សូមបញ្ចូលប័ណ្ណបើកបរ។';
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      showErrorDialog(context, validationError);
      return;
    }

    setState(() => _submitting = true);
    try {
      await _driverService.submitCustomerApplication(
        branchId: _selectedBranchId!,
        vehicleType: _usesOwnVehicle ? _ownVehicleType : null,
        plateNumber:
            _showsPlateNumberField && _plateNumberCtrl.text.trim().isNotEmpty
                ? _plateNumberCtrl.text.trim()
                : null,
        avatarFile: _avatarFile,
        cvFile: _cvFile!,
        nationalIdFile: _nationalIdFile!,
        drivingLicenseFile: _drivingLicenseFile,
      );

      if (!mounted) return;
      showSuccessSnack(context, 'បានផ្ញើសំណើរជាអ្នកបើកបរដោយជោគជ័យ។');
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.customer,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  ImageProvider<Object>? _avatarPreview() {
    if (_avatarFile != null) return FileImage(_avatarFile!);
    final avatarUrl = _profile?.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return NetworkImage(avatarUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FA),
        elevation: 0,
        surfaceTintColor: const Color(0xFFF6F7FA),
        foregroundColor: _requestAccentDark,
        title: const Text(
          'ស្នើសុំធ្វើជាអ្នកបើកបរ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2C5F8A)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(
                      onTap: _pickAvatar,
                      avatarProvider: _avatarPreview(),
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(profile: _profile),
                    const SizedBox(height: 16),
                    _RouteGuideCard(
                      usesOwnVehicle: _usesOwnVehicle,
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'ព័ត៌មានសំណើ',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('ជ្រើសរើសសាខា'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBranchId,
                            decoration: _inputDecoration('ជ្រើសរើសសាខា'),
                            items: _branches
                                .map(
                                  (branch) => DropdownMenuItem<String>(
                                    value: branch.id,
                                    child: Text(_branchLabel(branch)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedBranchId = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          const _FieldLabel('ប្រភេទការងារ'),
                          const SizedBox(height: 8),
                          _ChoiceCard(
                            selected: _vehicleChoice != driverBranchTruckChoice,
                            title: 'ខ្ញុំមានយានជំនិះផ្ទាល់ខ្លួន',
                            subtitle:
                                'សម្រាប់ម៉ូតូ ឬ ឡានដឹកទំនិញដែលអ្នកមានរួចហើយ។',
                            icon: Icons.two_wheeler_rounded,
                            onTap: () {
                              setState(() {
                                _vehicleChoice = _ownVehicleType;
                                if (!_requiresDrivingLicense) {
                                  _drivingLicenseFile = null;
                                }
                                if (!_showsPlateNumberField) {
                                  _plateNumberCtrl.clear();
                                }
                              });
                            },
                          ),
                          if (_vehicleChoice != driverBranchTruckChoice) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _ownVehicleType,
                              decoration: _inputDecoration('ជ្រើសរើសប្រភេទយានជំនិះ'),
                              items: ownVehicleTypeOptions
                                  .map(
                                    (option) => DropdownMenuItem<String>(
                                      value: option.value,
                                      child: Text(option.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null || value.isEmpty) return;
                                setState(() {
                                  _ownVehicleType = value;
                                  _vehicleChoice = value;
                                  if (!_requiresDrivingLicense) {
                                    _drivingLicenseFile = null;
                                  }
                                  if (!_showsPlateNumberField) {
                                    _plateNumberCtrl.clear();
                                  }
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 10),
                          _ChoiceCard(
                            selected: _vehicleChoice == driverBranchTruckChoice,
                            title: 'សុំយានជំនិះពីសាខា',
                            subtitle:
                                'សម្រាប់អ្នកដែលត្រូវការឡានពីសាខាដើម្បីចាប់ផ្តើមការងារ។',
                            icon: Icons.local_shipping_rounded,
                            onTap: () {
                              setState(() {
                                _vehicleChoice = driverBranchTruckChoice;
                                _plateNumberCtrl.clear();
                              });
                            },
                          ),
                          if (_showsPlateNumberField) ...[
                            const SizedBox(height: 16),
                            const _FieldLabel('ស្លាកលេខ'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _plateNumberCtrl,
                              decoration: _inputDecoration(
                                'បញ្ចូលស្លាកលេខ (បើមាន)',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'ឯកសារភ្ជាប់',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DocumentTile(
                            title: 'CV',
                            subtitle: _fileName(_cvFile) ?? 'ជ្រើសរើសឯកសារ CV',
                            onTap: () => _pickDocument(
                              allowedExtensions: const [
                                'pdf',
                                'jpg',
                                'jpeg',
                                'png',
                                'webp',
                              ],
                              onSelected: (file) => _cvFile = file,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _DocumentTile(
                            title: 'អត្តសញ្ញាណប័ណ្ណ',
                            subtitle:
                                _fileName(_nationalIdFile) ?? 'ជ្រើសរើសឯកសារ',
                            onTap: () => _pickDocument(
                              allowedExtensions: const [
                                'pdf',
                                'jpg',
                                'jpeg',
                                'png',
                                'webp',
                              ],
                              onSelected: (file) => _nationalIdFile = file,
                            ),
                          ),
                          if (_requiresDrivingLicense) ...[
                            const SizedBox(height: 12),
                            _DocumentTile(
                              title: 'ប័ណ្ណបើកបរ',
                              subtitle: _fileName(_drivingLicenseFile) ??
                                  'ជ្រើសរើសឯកសារ',
                              helperText: _usesOwnVehicle
                                  ? 'តម្រូវសម្រាប់អ្នកដែលប្រើឡានផ្ទាល់ខ្លួន។'
                                  : 'តម្រូវសម្រាប់អ្នកសុំយានជំនិះពីសាខា។',
                              onTap: () => _pickDocument(
                                allowedExtensions: const [
                                  'pdf',
                                  'jpg',
                                  'jpeg',
                                  'png',
                                  'webp',
                                ],
                                onSelected: (file) => _drivingLicenseFile = file,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _requestAccentDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'ផ្ញើសំណើ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _RouteGuideCard extends StatelessWidget {
  final bool usesOwnVehicle;

  const _RouteGuideCard({
    required this.usesOwnVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _requestBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your driver path',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _requestAccentDark,
            ),
          ),
          const SizedBox(height: 12),
          _RouteGuideLine(
            active: usesOwnVehicle,
            title: 'City Express motorbike',
            description:
                'Use your own motorbike for in-city delivery. This is the simple rider path.',
          ),
          const SizedBox(height: 10),
          _RouteGuideLine(
            active: !usesOwnVehicle,
            title: 'Branch logistics truck driver',
            description:
                'Apply to a branch first. The branch owner must approve you before assigning a branch truck.',
          ),
        ],
      ),
    );
  }
}

class _RouteGuideLine extends StatelessWidget {
  final bool active;
  final String title;
  final String description;

  const _RouteGuideLine({
    required this.active,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? _requestAccent : _requestBorder,
          width: active ? 1.3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _requestAccentDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF5B708B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: _requestSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _requestBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _requestBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _requestAccent, width: 1.4),
    ),
  );
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onTap;
  final ImageProvider<Object>? avatarProvider;

  const _HeroCard({
    required this.onTap,
    required this.avatarProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _requestBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ក្លាយជាភ្នាក់ងារដឹកជញ្ជូន',
                      style: TextStyle(
                        color: _requestAccentDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'សម្រាប់អតិថិជនដែលចង់ផ្ញើសំណើទៅសាខា ដើម្បីពិនិត្យ និងអនុម័តជាអ្នកបើកបរ។',
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 92,
                  height: 92,
                  color: const Color(0xFFF2F4F7),
                  child: Image.asset(
                    'assets/images/driver_agent_request.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.delivery_dining_rounded,
                      color: _requestAccent,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              GestureDetector(
                onTap: onTap,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFF2F4F7),
                  backgroundImage: avatarProvider,
                  child: avatarProvider == null
                      ? const Icon(
                          Icons.add_a_photo_outlined,
                          color: _requestAccent,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'អាចប្ដូររូបប្រវត្តិបាន ប្រសិនបើអ្នកចង់ប្រើរូបថ្មីសម្រាប់សំណើនេះ។',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final UserProfile? profile;

  const _InfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ព័ត៌មានគណនី',
      child: Column(
        children: [
          _ReadOnlyField(label: 'ឈ្មោះ', value: profile?.name ?? '-'),
          const SizedBox(height: 12),
          _ReadOnlyField(label: 'អ៊ីមែល', value: profile?.email ?? '-'),
          const SizedBox(height: 12),
          _ReadOnlyField(label: 'លេខទូរស័ព្ទ', value: profile?.phone ?? '-'),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _requestBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _requestAccentDark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _requestSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _requestBorder),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3A4E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _requestAccentDark,
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ChoiceCard({
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _requestAccent : _requestBorder,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _requestAccentDark),
            ),
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
                      color: _requestAccentDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF5B708B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: _requestAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? helperText;
  final VoidCallback onTap;

  const _DocumentTile({
    required this.title,
    required this.subtitle,
    this.helperText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _requestSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _requestBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.upload_file_rounded,
                  color: _requestAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$title: $subtitle',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _requestAccentDark,
                      fontWeight: FontWeight.w600,
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
                  fontSize: 12.5,
                  color: Color(0xFF5B708B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
