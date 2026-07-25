import 'package:flutter/material.dart';
import '../router/app_router.dart';
import '../features/auth/models/user_model.dart';
import '../features/auth/services/user_service.dart';
import '../features/auth/services/auth_service.dart';
import '../features/auth/tokens/token_storage.dart';
import '../shared/widgets/home_bottom_nav.dart';
import '../features/driver_registration/models/vehicle_type.dart';

const _profileRequestAccent = Color(0xFF5B6C8F);
const _profileRequestDark = Color(0xFF32435C);
const _profileRequestSurface = Color(0xFFF7F8FB);
const _profileRequestBorder = Color(0xFFE2E7F0);

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
            content: Text(
              'Error loading profile: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _openEditProfileSheet() async {
    final profile = _userProfile;
    if (profile == null) return;

    final nameCtrl = TextEditingController(text: profile.name);
    final phoneCtrl = TextEditingController(
      text: profile.phone == null || profile.phone!.isEmpty
          ? ''
          : _formatPhone(profile.phone),
    );
    String? errorText;
    bool saving = false;

    final updatedProfile = await showModalBottomSheet<UserProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();

              if (name.length < 2) {
                setSheetState(() => errorText = 'Please enter a valid name.');
                return;
              }
              if (phone.isEmpty) {
                setSheetState(
                  () => errorText = 'Please enter your phone number.',
                );
                return;
              }
              if (!_phoneReg.hasMatch(phone)) {
                setSheetState(
                  () => errorText =
                      'Phone number must be a valid Cambodian number.',
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
                  throw Exception('Please log in again.');
                }

                final updated = await _userService.updateProfile(
                  accessToken: accessToken,
                  name: name,
                  phone: phone,
                );
                if (!mounted) return;
                Navigator.pop(sheetContext, updated);
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  errorText = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
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
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2D3D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Update your name and phone number.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _EditField(
                      label: 'Full name',
                      controller: nameCtrl,
                      hintText: 'Enter your full name',
                    ),
                    const SizedBox(height: 14),
                    _EditField(
                      label: 'Phone number',
                      controller: phoneCtrl,
                      hintText: 'Enter your phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _profileRequestDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();

    if (updatedProfile != null && mounted) {
      setState(() => _userProfile = updatedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'áž…áž¶áž€áž…áŸáž‰',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'ážáž¾áž¢áŸ’áž“áž€áž–áž·ážáž‡áž¶áž…áž„áŸ‹áž…áž¶áž€áž…áŸáž‰áž˜áŸ‚áž“áž‘áŸ?',
          style: TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'áž”áŸ„áŸ‡áž”áž„áŸ‹',
              style: TextStyle(color: Color(0xFF8BA4C8)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _performLogout();
            },
            child: const Text(
              'áž…áž¶áž€áž…áŸáž‰',
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
                      'áž¢áŸ†áž–áž¸áž¢áŸ’áž“áž€',
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
                      onTap: _openEditProfileSheet,
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
                          label: 'ážˆáŸ’áž˜áŸ„áŸ‡',
                          value: p?.name ?? 'â€”',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _ProfileField(
                          label: 'áž—áŸáž‘',
                          value:
                              'áž”áŸ’ážšáž»ážŸ', // TODO: add gender to UserProfile when backend supports it
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _ProfileField(
                    label: 'áž›áŸážáž‘áž¼ážšážŸáŸáž–áŸ’áž‘',
                    value: _formatPhone(p?.phone),
                  ),
                  const SizedBox(height: 14),

                  _ProfileField(label: 'áž¢áž»áž¸áž˜áŸ‰áŸ‚áž›', value: p?.email ?? 'â€”'),
                  if (p?.role == 'customer') ...[
                    const SizedBox(height: 18),
                    _DriverRequestActionCard(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.becomeDriver);
                      },
                    ),
                  ],
                  if (p?.role == 'driver') ...[
                    const SizedBox(height: 14),
                    _ProfileField(
                      label: 'Vehicle type',
                      value: vehicleTypeLabel(p?.vehicleType),
                    ),
                    if (p?.assignedVehicleCode != null &&
                        p!.assignedVehicleCode!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ProfileField(
                        label: 'Truck code',
                        value: p.assignedVehicleCode!,
                      ),
                    ],
                  ],
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
                        'áž…áž¶áž€áž…áŸáž‰',
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
    if (raw == null || raw.isEmpty) return 'â€”';
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

// â”€â”€ Read-only profile field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

class _EditField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _EditField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _profileRequestDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: _profileRequestSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _profileRequestBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _profileRequestBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _profileRequestAccent),
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverRequestActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DriverRequestActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _profileRequestBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ážŸáŸ’áž“áž¾ážŸáž»áŸ†áž€áŸ’áž›áž¶áž™áž‡áž¶áž¢áŸ’áž“áž€áž”áž¾áž€áž”ážš',
                  style: TextStyle(
                    color: _profileRequestDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'áž”áŸ’ážšážŸáž·áž“áž”áž¾áž¢áŸ’áž“áž€áž…áž„áŸ‹áž’áŸ’ážœáž¾áž€áž¶ážšáž‡áž¶áž—áŸ’áž“áž¶áž€áŸ‹áž„áž¶ážšážŠáž¹áž€áž‡áž‰áŸ’áž‡áž¼áž“ áž¢áŸ’áž“áž€áž¢áž¶áž…áž•áŸ’áž‰áž¾ážŸáŸ†ážŽáž¾áž‘áŸ…ážŸáž¶ážáž¶áž–áž¸áž‘áž¸áž“áŸáŸ‡áž”áž¶áž“áŸ”',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    backgroundColor: _profileRequestSurface,
                    foregroundColor: _profileRequestDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'áž”áž¾áž€ážŸáŸ†ážŽáž¾',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/driver_agent_request.png',
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: _profileRequestSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: _profileRequestAccent,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
