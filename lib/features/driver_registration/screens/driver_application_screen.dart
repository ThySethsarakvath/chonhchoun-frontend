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
  final _service = DriverApplicationService();
  final _branchService = BranchService();
  final _picker = ImagePicker();

  List<Branch> _branches = const [];
  String? _selectedBranchId;
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
    if (_nameCtrl.text.trim().length < 2) return 'សូមបញ្ចូលឈ្មោះពេញឱ្យត្រឹមត្រូវ។';
    if (!_emailReg.hasMatch(_emailCtrl.text.trim())) return 'សូមបញ្ចូលអ៊ីមែលឱ្យត្រឹមត្រូវ។';
    if (!_phoneReg.hasMatch(_phoneCtrl.text.trim())) {
      return 'សូមបញ្ចូលលេខទូរស័ព្ទខ្មែរឱ្យត្រឹមត្រូវ។';
    }
    if (_passwordCtrl.text.length < 6) {
      return 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួអក្សរ។';
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      return 'ពាក្យសម្ងាត់មិនដូចគ្នា។';
    }
    if (_selectedBranchId == null || _selectedBranchId!.isEmpty) {
      return 'សូមជ្រើសរើសសាខា។';
    }
    if (_avatarFile == null ||
        _cvFile == null ||
        _nationalIdFile == null ||
        _drivingLicenseFile == null) {
      return 'សូមបង្ហោះរូបភាពប្រវត្តិរូប CV អត្តសញ្ញាណប័ណ្ណ និងប័ណ្ណបើកបរ។';
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
        avatarFile: _avatarFile!,
        cvFile: _cvFile!,
        nationalIdFile: _nationalIdFile!,
        drivingLicenseFile: _drivingLicenseFile!,
      );
      if (!mounted) return;
      showSuccessSnack(
        context,
        'ពាក្យស្នើសុំអ្នកបើកបររបស់អ្នកត្រូវបានផ្ញើសម្រាប់ការពិនិត្យរបស់ម្ចាស់សាខារួចហើយ។',
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
            label: 'ឈ្មោះពេញ',
            placeholder: 'សូមបញ្ចូលឈ្មោះពេញ',
            controller: _nameCtrl,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'អ៊ីមែល',
            placeholder: 'សូមបញ្ចូលអ៊ីមែល',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'លេខទូរស័ព្ទ',
            placeholder: 'សូមបញ្ចូលលេខទូរស័ព្ទ',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'ពាក្យសម្ងាត់',
            placeholder: 'បង្កើតពាក្យសម្ងាត់',
            controller: _passwordCtrl,
            obscure: _obscurePassword,
            showToggle: true,
            onToggle: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'បញ្ជាក់ពាក្យសម្ងាត់',
            placeholder: 'សូមបញ្ជាក់ពាក្យសម្ងាត់',
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
          const SizedBox(height: 20),
          DriverDocumentPickerTile(
            label: 'បង្ហោះ CV',
            fileName: _fileName(_cvFile),
            onTap: () => _pickDocument(
              allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
              onSelected: (file) => _cvFile = file,
            ),
          ),
          const SizedBox(height: 12),
          DriverDocumentPickerTile(
            label: 'បង្ហោះអត្តសញ្ញាណប័ណ្ណ',
            fileName: _fileName(_nationalIdFile),
            onTap: () => _pickDocument(
              allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
              onSelected: (file) => _nationalIdFile = file,
            ),
          ),
          const SizedBox(height: 12),
          DriverDocumentPickerTile(
            label: 'បង្ហោះប័ណ្ណបើកបរ',
            fileName: _fileName(_drivingLicenseFile),
            onTap: () => _pickDocument(
              allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
              onSelected: (file) => _drivingLicenseFile = file,
            ),
          ),
          const SizedBox(height: 24),
          AuthButton(
            label: 'ដាក់ស្នើពាក្យ',
            onPressed: _submit,
            loading: _submitting,
          ),
          const SizedBox(height: 20),
          AuthLinkRow(
            prefix: 'ត្រូវការគណនីអតិថិជនធម្មតាមែនទេ? ',
            linkText: 'ចុះឈ្មោះនៅទីនេះ',
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
