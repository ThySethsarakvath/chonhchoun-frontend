import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../router/app_router.dart';
import '../features/auth/services/user_service.dart';
import '../features/auth/widgets/auth_widgets.dart';
import '../features/auth/widgets/auth_scaffold.dart';

class AvatarUploadScreen extends StatefulWidget {
  final AvatarUploadArgs args;

  const AvatarUploadScreen({super.key, required this.args});

  @override
  State<AvatarUploadScreen> createState() => _AvatarUploadScreenState();
}

class _AvatarUploadScreenState extends State<AvatarUploadScreen> {
  final _picker = ImagePicker();
  final _userService = UserService();

  File? _pickedImage;
  bool _uploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;
      setState(() => _pickedImage = File(picked.path));
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          source == ImageSource.camera
              ? 'មិនអាចបើកកាមេរ៉ាបានទេ។ សូមអនុញ្ញាតការអនុញ្ញាតនៅក្នុងការកំណត់។'
              : 'មិនអាចចូលប្រើបណ្ណាល័យរូបភាពបានទេ។',
        );
      }
    }
  }

  Future<void> _uploadAndContinue() async {
    if (_pickedImage == null) {
      _skip();
      return;
    }

    setState(() => _uploading = true);
    try {
      await _userService.uploadAvatar(
        imageFile: _pickedImage!,
        accessToken: widget.args.accessToken,
      );
      if (mounted) _goHome();
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _skip() => _goHome();

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.customer,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bluePanelHeight = screenHeight * 0.60;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      body: Column(
        children: [
          SizedBox(
            height: bluePanelHeight,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1E4D73), Color(0xFF2C6B9E)],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/footer.png',
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, _, _) => const SizedBox(height: 70),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Center(
                    // Add Center here to handle horizontal centering
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Centers children vertically
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Centers children horizontally
                      children: [
                        // No top SizedBox needed if using MainAxisAlignment.center
                        const Text(
                          'សូមស្វាគមន៍',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.args.userName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _AvatarCircle(image: _pickedImage),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ImageSourceButton(
                          icon: Icons.camera_alt_outlined,
                          label: 'ថតរូបថ្មី',
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _ImageSourceButton(
                          icon: Icons.photo_library_outlined,
                          label: 'រករូបភាព',
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_pickedImage != null)
                    AuthButton(
                      label: 'បន្ត',
                      onPressed: _uploadAndContinue,
                      loading: _uploading,
                    ),

                  if (_pickedImage != null) const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _uploading ? null : _skip,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF2C5F8A),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'រំលង',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C5F8A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final File? image;

  const _AvatarCircle({this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFD6E8F5),
        border: Border.all(color: const Color(0xFF87C0CD), width: 15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: image != null
            ? Image.file(image!, fit: BoxFit.cover)
            : Image.asset(
                'assets/images/avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.person_rounded,
                  size: 64,
                  color: Color(0xFF2C5F8A),
                ),
              ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE3EE)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C5F8A).withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2C5F8A), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3A4E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
