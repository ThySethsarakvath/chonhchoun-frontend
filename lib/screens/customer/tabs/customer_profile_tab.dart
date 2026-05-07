import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../customer_profile/widgets/customer_profile_actions_card.dart';
import '../customer_profile/widgets/customer_profile_header.dart';
import '../customer_profile/widgets/customer_profile_info_card.dart';
import '../models/customer_profile.dart';
import '../services/customer_profile_service.dart';
import '../widgets/customer_colors.dart';

class CustomerProfileTab extends StatefulWidget {
  const CustomerProfileTab({super.key});

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
  final CustomerProfileService _profileService = CustomerProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  CustomerProfile? _profile;
  bool _loading = true;
  bool _uploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cachedProfile = await _profileService.getCachedProfile();
    if (mounted && cachedProfile != null) {
      setState(() {
        _profile = cachedProfile;
        _loading = true;
      });
    }

    try {
      final profile = await _profileService.fetchProfile();
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _errorMessage = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _changePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() => _uploading = true);

    try {
      final profile = await _profileService.uploadAvatar(pickedFile.path);
      if (!mounted) return;

      setState(() {
        _profile = profile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _showLogoutPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logout action placeholder. Hook this to your logout flow next.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      backgroundColor: CustomerColors.surface,
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: _loading && profile == null
                  ? const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : profile == null
                      ? _ProfileErrorState(
                          message: _errorMessage ??
                              'Unable to load your profile right now.',
                          onRetry: _loadProfile,
                        )
                      : Column(
                          children: [
                            CustomerProfileHeader(
                              name: profile.name,
                              email: profile.email,
                              role: profile.role,
                              avatarUrl: profile.avatarUrl,
                              isUploading: _uploading,
                              onChangePhoto: _changePhoto,
                            ),
                            CustomerProfileInfoCard(
                              name: profile.name,
                              email: profile.email,
                              role: profile.role,
                            ),
                            CustomerProfileActionsCard(
                              onLogoutTap: _showLogoutPlaceholder,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return const SliverAppBar(
      expandedHeight: 60,
      pinned: true,
      backgroundColor: CustomerColors.blueDark,
      title: Text(
        'Profile',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: CustomerColors.muted,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CustomerColors.text,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomerColors.blueDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
