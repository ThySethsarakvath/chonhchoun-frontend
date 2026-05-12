import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import 'app_drawer.dart';

class AppDrawerController extends InheritedWidget {
  final VoidCallback open;
  final VoidCallback close;
  final bool isOpen;

  const AppDrawerController({
    super.key,
    required this.open,
    required this.close,
    required this.isOpen,
    required super.child,
  });

  static AppDrawerController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppDrawerController>();

  @override
  bool updateShouldNotify(AppDrawerController old) =>
      isOpen != old.isOpen;
}

class AppDrawerWrapper extends StatefulWidget {
  final String city;
  final String avatarUrl;
  final UserProfile? userProfile;
  final Widget child;
  final VoidCallback? onProfileTap;

  const AppDrawerWrapper({
    super.key,
    required this.city,
    required this.avatarUrl,
    this.userProfile,
    required this.child,
    this.onProfileTap,
  });

  @override
  State<AppDrawerWrapper> createState() => _AppDrawerWrapperState();
}

class _AppDrawerWrapperState extends State<AppDrawerWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _slideAnim;   // 0.0 = closed, 1.0 = open
  late Animation<double> _scrimAnim;

  int _selectedDrawerIndex = -1; // -1 = nothing selected yet

  bool get _isOpen => _animCtrl.value > 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _scrimAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _open() => _animCtrl.forward();
  void _close() => _animCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.78;

    return AppDrawerController(
      open: _open,
      close: _close,
      isOpen: _isOpen,
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (context, _) {
          return Stack(
            children: [
              Transform.translate(
                offset: Offset(_slideAnim.value * drawerWidth * 0.25, 0),
                child: widget.child,
              ),
              if (_animCtrl.value > 0)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _close,
                    child: Container(
                      color: Colors.black
                          .withOpacity(_scrimAnim.value * 0.45),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(
                  drawerWidth * (_slideAnim.value - 1), // starts off-screen
                  0,
                ),
                child: AppDrawer(
                  city: widget.city,
                  avatarUrl: widget.avatarUrl,
                  userProfile: widget.userProfile,
                  selectedIndex: _selectedDrawerIndex,
                  onItemSelected: (i) {
                    setState(() => _selectedDrawerIndex = i);
                  },
                  onClose: _close,
                  onProfileTap: () {
                    _close();
                    if (widget.onProfileTap != null) {
                      widget.onProfileTap!();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}