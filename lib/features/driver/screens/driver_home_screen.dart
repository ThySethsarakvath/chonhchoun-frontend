import 'package:flutter/material.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../router/app_router.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/user_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../../chat/models/conversation.dart';
import '../../chat/screens/conversations_screen.dart';
import '../../chat/services/conversation_service.dart';

/// Minimal driver workspace: lists the driver's assigned deliveries and
/// lets them open a chat with each customer.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final UserService _userService = UserService();
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      try {
        _profile = await _userService.getMe(accessToken: token);
      } catch (e) {
        debugPrint('driver profile error: $e');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    await TokenStorage.clearTokens();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      appBar: AppBar(
        backgroundColor: AppColors.blueDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Driver Workspace',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            if (profile != null)
              Text(profile.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : profile == null
              ? const Center(
                  child: Text('មិនអាចទាញយកគណនីបានទេ',
                      style: TextStyle(color: Color(0xFF8BA4C8))))
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('ការដឹកជញ្ជូនរបស់ខ្ញុំ',
                            style: TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(
                      child: ConversationsScreen(
                        currentUserId: profile.id,
                        loader: () async {
                          final token = await TokenStorage.getAccessToken();
                          if (token == null) return <Conversation>[];
                          return ConversationService().driverConversations(token);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
