import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../router/app_router.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/services/user_service.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/tokens/token_storage.dart';
import '../../shared/widgets/home_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile? profile;
  final ProfileSource source;

  const ProfileScreen({
    super.key,
    this.profile,
    this.source = ProfileSource.home,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  static final _phoneReg = RegExp(r'^(\+?855|0)[0-9]{8,9}$');

  UserProfile? _userProfile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _userProfile = widget.profile;
    } else {
      _fetchUserProfile();
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _loading = true);
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final profile = await _userService.getMe(accessToken: accessToken);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មិនអាចផ្ទុកព័ត៌មានគណនីបានទេ។ សូមព្យាយាមម្ដងទៀត។'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _openEditProfileSheet() async {
    final profile = _userProfile;
    if (profile == null) return;

    final nameController = TextEditingController(text: profile.name);
    final phoneController = TextEditingController(
      text: profile.phone == null || profile.phone!.isEmpty
          ? ''
          : _formatPhone(profile.phone),
    );
    Uint8List? avatarBytes;
    String? avatarFileName;
    String? errorText;
    bool saving = false;

    final updatedProfile = await showModalBottomSheet<UserProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickAvatar() async {
              try {
                final image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                  maxWidth: 1200,
                  maxHeight: 1200,
                );
                if (image == null) return;
                final bytes = await image.readAsBytes();
                setSheetState(() {
                  avatarBytes = bytes;
                  avatarFileName = image.name;
                  errorText = null;
                });
              } catch (error) {
                setSheetState(
                  () => errorText =
                      'មិនអាចជ្រើសរើសរូបភាពនេះបានទេ។ សូមសាកល្បងរូបភាពផ្សេង។',
                );
              }
            }

            Future<void> submit() async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.length < 2) {
                setSheetState(
                  () => errorText = 'សូមបញ្ចូលឈ្មោះពេញឱ្យបានត្រឹមត្រូវ។',
                );
                return;
              }
              if (!_phoneReg.hasMatch(phone)) {
                setSheetState(
                  () =>
                      errorText = 'សូមបញ្ចូលលេខទូរសព្ទកម្ពុជាឱ្យបានត្រឹមត្រូវ។',
                );
                return;
              }

              setSheetState(() {
                saving = true;
                errorText = null;
              });
              try {
                final accessToken = await TokenStorage.getAccessToken();
                if (accessToken == null || accessToken.isEmpty) {
                  throw Exception('សូមចូលគណនីម្ដងទៀត។');
                }

                await _userService.updateProfile(
                  accessToken: accessToken,
                  name: name,
                  phone: phone,
                );
                if (avatarBytes != null && avatarFileName != null) {
                  await _userService.uploadAvatarBytes(
                    imageBytes: avatarBytes!,
                    fileName: avatarFileName!,
                    accessToken: accessToken,
                  );
                }
                final refreshed = await _userService.getMe(
                  accessToken: accessToken,
                );
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext, refreshed);
                }
              } catch (error) {
                setSheetState(() {
                  saving = false;
                  errorText =
                      'មិនអាចធ្វើបច្ចុប្បន្នភាពគណនីបានទេ។ សូមព្យាយាមម្ដងទៀត។';
                });
              }
            }

            final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
            return Padding(
              padding: EdgeInsets.only(top: 40, bottom: bottomInset),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD5DDE8),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'កែប្រែគណនី',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2D3D),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: InkWell(
                          onTap: saving ? null : pickAvatar,
                          borderRadius: BorderRadius.circular(60),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: const Color(0xFFD6E8F5),
                                backgroundImage: avatarBytes != null
                                    ? MemoryImage(avatarBytes!)
                                    : profile.avatarUrl != null &&
                                          profile.avatarUrl!.isNotEmpty
                                    ? NetworkImage(profile.avatarUrl!)
                                    : null,
                                child:
                                    avatarBytes == null &&
                                        (profile.avatarUrl == null ||
                                            profile.avatarUrl!.isEmpty)
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 50,
                                        color: Color(0xFF2C5F8A),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C5F8A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _EditProfileField(
                        label: 'ឈ្មោះពេញ',
                        controller: nameController,
                      ),
                      const SizedBox(height: 14),
                      _EditProfileField(
                        label: 'លេខទូរសព្ទ',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: saving ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C5F8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'រក្សាទុកការកែប្រែ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    if (updatedProfile != null && mounted) {
      setState(() => _userProfile = updatedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('បានធ្វើបច្ចុប្បន្នភាពគណនីដោយជោគជ័យ។')),
      );
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ចាកចេញ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'តើអ្នកពិតជាចង់ចាកចេញមែនទេ?',
          style: TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'បោះបង់',
              style: TextStyle(color: Color(0xFF8BA4C8)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _performLogout();
            },
            child: const Text(
              'ចាកចេញ',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2C5F8A)),
        ),
      );

      // Get access token
      final accessToken = await TokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          await TokenStorage.clearTokens();
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (_) => false,
          );
        }
        return;
      }

      // Call logout endpoint
      await _authService.logout(accessToken: accessToken);

      // Clear tokens
      await TokenStorage.clearTokens();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        // Even if backend logout fails, clear local tokens and redirect
        await TokenStorage.clearTokens();
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      }
    }
  }

  void _handleBackNavigation() {
    switch (widget.source) {
      case ProfileSource.settings:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.settings,
          (_) => false,
        );
        break;
      case ProfileSource.drawer:
      case ProfileSource.home:
      default:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.customer,
          (_) => false,
        );
        break;
    }
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.customer,
          (_) => false,
        );
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.customer,
          (_) => false,
        );
        // TODO: navigate to shipping screen
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.customer,
          (_) => false,
        );
        // TODO: navigate to chat screen
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.settings,
          (_) => false,
        );
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.customer,
          (_) => false,
        );
        // TODO: handle QR code scanner
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _userProfile;

    if (_loading && p == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF3FB),
        extendBody: true,
        bottomNavigationBar: HomeBottomNav(
          currentIndex: -1,
          onTap: _handleNavigation,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2C5F8A)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      extendBody: true,
      bottomNavigationBar: HomeBottomNav(
        currentIndex: -1, // No tab selected on profile screen
        onTap: _handleNavigation,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      'អំពីអ្នក',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2D3D),
                      ),
                    ),
                  ),
                  // Back button (left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _handleBackNavigation,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2C5F8A).withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF2C5F8A),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Edit button (right)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: p == null ? null : _openEditProfileSheet,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2C5F8A).withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF2C5F8A),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 100),
                children: [
                  Center(child: _ProfileAvatar(avatarUrl: p?.avatarUrl)),
                  const SizedBox(height: 35),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _ProfileField(
                          label: 'ឈ្មោះ',
                          value: p?.name ?? '—',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _ProfileField(
                          label: 'ភេទ',
                          value:
                              'ប្រុស', // TODO: add gender to UserProfile when backend supports it
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _ProfileField(
                    label: 'លេខទូរស័ព្ទ',
                    value: _formatPhone(p?.phone),
                  ),
                  const SizedBox(height: 14),

                  _ProfileField(label: 'អ៊ីមែល', value: p?.email ?? '—'),
                  const SizedBox(height: 80),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'ចាកចេញ',
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
          ],
        ),
      ),
    );
  }

  String _formatPhone(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    if (raw.startsWith('+855')) return '0${raw.substring(4)}';
    return raw;
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  const _ProfileAvatar({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFD6E8F5),
        border: Border.all(color: const Color(0xFF87C0CD), width: 12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C5F8A).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _defaultIcon(),
              )
            : Image.asset(
                'assets/images/avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _defaultIcon(),
              ),
      ),
    );
  }

  Widget _defaultIcon() =>
      const Icon(Icons.person_rounded, size: 56, color: Color(0xFF2C5F8A));
}

// ── Read-only profile field ───────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A8DDB),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C5F8A).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3A4E),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileField extends StatelessWidget {
  const _EditProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F8FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2C5F8A)),
        ),
      ),
    );
  }
}
