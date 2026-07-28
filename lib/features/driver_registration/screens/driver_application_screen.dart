import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../router/app_router.dart';
import '../../admin_management/models/branch_model.dart';
import '../../admin_management/services/branch_service.dart';
import '../../auth/widgets/auth_header.dart';
import '../../auth/widgets/auth_scaffold.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../models/vehicle_type.dart';
import '../services/driver_application_service.dart';
import '../widgets/driver_application_widgets.dart';

class DriverApplicationScreen extends StatefulWidget {
  const DriverApplicationScreen({super.key});

  @override
  State<DriverApplicationScreen> createState() => _DriverApplicationScreenState();
}

class _DriverApplicationScreenState extends State<DriverApplicationScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _plateNumberCtrl = TextEditingController();
  final _service = DriverApplicationService();
  final _branchService = BranchService();
  final _picker = ImagePicker();

  List<Branch> _branches = const [];
  String? _selectedBranchId;
  String _vehicleChoice = driverOwnMotorcycleType;
  String _ownVehicleType = driverOwnMotorcycleType;
  File? _avatarFile;
  File? _cvFile;
  File? _nationalIdFile;
  File? _drivingLicenseFile;
  bool _loadingBranches = true;
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static final _emailReg = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$');
  static final _phoneReg = RegExp(r'^(\+?855|0)[0-9]{8,9}$');

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
    _loadBranches();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _plateNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    setState(() => _loadingBranches = true);
    try {
      final branches = await _branchService.getMapBranches();
      if (!mounted) return;
      setState(() {
        _branches = branches.where((branch) => branch.isActive).toList();
        _selectedBranchId =
            _branches.length == 1 ? _branches.first.id : _selectedBranchId;
        _loadingBranches = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingBranches = false);
      showErrorDialog(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
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

  String? _validate() {
    if (_nameCtrl.text.trim().length < 2) {
      return 'Please enter your full name.';
    }
    if (!_emailReg.hasMatch(_emailCtrl.text.trim())) {
      return 'Please enter a valid email address.';
    }
    if (!_phoneReg.hasMatch(_phoneCtrl.text.trim())) {
      return 'Please enter a valid Cambodian phone number.';
    }
    if (_passwordCtrl.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      return 'Passwords do not match.';
    }
    if (_selectedBranchId == null || _selectedBranchId!.isEmpty) {
      return 'Please select a branch.';
    }
    if (_avatarFile == null || _cvFile == null || _nationalIdFile == null) {
      return 'Please upload your profile photo, CV, and national ID.';
    }
    if (_requiresDrivingLicense && _drivingLicenseFile == null) {
      return 'Please upload your driving license.';
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
      await _service.submitApplication(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        confirmPassword: _confirmPasswordCtrl.text,
        branchId: _selectedBranchId!,
        vehicleType: _usesOwnVehicle ? _ownVehicleType : null,
        plateNumber:
            _showsPlateNumberField && _plateNumberCtrl.text.trim().isNotEmpty
                ? _plateNumberCtrl.text.trim()
                : null,
        avatarFile: _avatarFile!,
        cvFile: _cvFile!,
        nationalIdFile: _nationalIdFile!,
        drivingLicenseFile: _drivingLicenseFile,
      );
      if (!mounted) return;
      showSuccessSnack(
        context,
        'Driver application submitted successfully.',
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
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

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      logoAlignment: LogoAlignment.left,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DriverApplicationHeader(),
          const SizedBox(height: 28),
          DriverAvatarPicker(
            imageFile: _avatarFile,
            onTap: _pickAvatar,
          ),
          const SizedBox(height: 20),
          AuthTextField(
            label: 'Full name',
            placeholder: 'Enter your full name',
            controller: _nameCtrl,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Email',
            placeholder: 'Enter your email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Phone number',
            placeholder: 'Enter your phone number',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Password',
            placeholder: 'Create a password',
            controller: _passwordCtrl,
            obscure: _obscurePassword,
            showToggle: true,
            onToggle: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Confirm password',
            placeholder: 'Confirm your password',
            controller: _confirmPasswordCtrl,
            obscure: _obscureConfirmPassword,
            showToggle: true,
            onToggle: () {
              setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              );
            },
          ),
          const SizedBox(height: 16),
          DriverBranchDropdown(
            branches: _branches,
            selectedBranchId: _selectedBranchId,
            loading: _loadingBranches,
            onChanged: (value) => setState(() => _selectedBranchId = value),
          ),
          const SizedBox(height: 16),
          _DriverFlowHintCard(
            usesOwnVehicle: _usesOwnVehicle,
          ),
          const SizedBox(height: 16),
          DriverApplicationVehicleChoice(
            selectedValue: _vehicleChoice,
            selectedOwnVehicleType: _usesOwnVehicle ? _ownVehicleType : null,
            onChanged: (value) => setState(() {
              _vehicleChoice = value;
              if (_vehicleChoice == driverBranchTruckChoice) {
                _drivingLicenseFile = null;
                _plateNumberCtrl.clear();
              }
              if (!_requiresDrivingLicense) {
                _drivingLicenseFile = null;
              }
              if (!_showsPlateNumberField) {
                _plateNumberCtrl.clear();
              }
            }),
            onOwnVehicleTypeChanged: (value) => setState(() {
              if (value == null || value.isEmpty) return;
              _ownVehicleType = value;
              _vehicleChoice = value;
              if (!_requiresDrivingLicense) {
                _drivingLicenseFile = null;
              }
              if (!_showsPlateNumberField) {
                _plateNumberCtrl.clear();
              }
            }),
          ),
          if (_showsPlateNumberField) ...[
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Plate number',
              placeholder: 'Enter plate number (optional)',
              controller: _plateNumberCtrl,
            ),
          ],
          const SizedBox(height: 20),
          DriverDocumentPickerTile(
            label: 'Upload CV',
            fileName: _fileName(_cvFile),
            onTap: () => _pickDocument(
              allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
              onSelected: (file) => _cvFile = file,
            ),
          ),
          const SizedBox(height: 12),
          DriverDocumentPickerTile(
            label: 'Upload national ID',
            fileName: _fileName(_nationalIdFile),
            onTap: () => _pickDocument(
              allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
              onSelected: (file) => _nationalIdFile = file,
            ),
          ),
          if (_requiresDrivingLicense) ...[
            const SizedBox(height: 12),
            DriverDocumentPickerTile(
              label: 'Upload driving license',
              fileName: _fileName(_drivingLicenseFile),
              helperText:
                  _usesOwnVehicle
                      ? 'Required for own truck registrations.'
                      : 'Required when the branch will assign a vehicle.',
              onTap: () => _pickDocument(
                allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
                onSelected: (file) => _drivingLicenseFile = file,
              ),
            ),
          ],
          const SizedBox(height: 24),
          AuthButton(
            label: _usesOwnVehicle
                ? 'Start City Express Request'
                : 'Submit Branch Driver Request',
            onPressed: _submit,
            loading: _submitting,
          ),
          const SizedBox(height: 20),
          AuthLinkRow(
            prefix: 'Need a customer account instead? ',
            linkText: 'Register here',
            onTap: () => Navigator.pushReplacementNamed(
              context,
              AppRoutes.register,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverFlowHintCard extends StatelessWidget {
  final bool usesOwnVehicle;

  const _DriverFlowHintCard({
    required this.usesOwnVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: usesOwnVehicle
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: usesOwnVehicle
              ? const Color(0xFFA7F3D0)
              : const Color(0xFFFED7AA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            usesOwnVehicle ? 'City Express flow' : 'Branch logistics flow',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: usesOwnVehicle
                  ? const Color(0xFF047857)
                  : const Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            usesOwnVehicle
                ? 'Use your own motorbike for in-city delivery. Keep the form simple and submit your rider documents.'
                : 'Apply to a branch first. After branch approval, the branch owner can assign a truck and manage your logistics work.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: usesOwnVehicle
                  ? const Color(0xFF065F46)
                  : const Color(0xFF9A3412),
            ),
          ),
        ],
      ),
    );
  }
}
