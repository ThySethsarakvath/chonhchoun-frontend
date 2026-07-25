import 'package:flutter/material.dart';

import '../widgets/driver_colors.dart';

class DriverIdentityScope extends InheritedWidget {
  const DriverIdentityScope({
    required this.avatarUrl,
    required super.child,
    super.key,
  });

  final String? avatarUrl;

  static DriverIdentityScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DriverIdentityScope>();
  }

  @override
  bool updateShouldNotify(DriverIdentityScope oldWidget) {
    return avatarUrl != oldWidget.avatarUrl;
  }
}

class DriverHeroSection extends StatelessWidget {
  const DriverHeroSection({
    super.key,
    required this.subtitle,
    required this.name,
    required this.content,
    this.leading,
    this.searchHint = 'Search delivery or tracking number',
    this.onSearchSubmitted,
  });

  final String subtitle;
  final String name;
  final Widget content;
  final Widget? leading;
  final String searchHint;
  final ValueChanged<String>? onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = DriverIdentityScope.maybeOf(context)?.avatarUrl?.trim();
    final hasProfileAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final skylineHeight = (MediaQuery.sizeOf(context).width * 96 / 410).clamp(
      76.0,
      118.0,
    );
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [DriverColors.blueDark, DriverColors.blue],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -40,
            top: 48,
            child: Container(
              height: 130,
              width: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -18,
            top: 126,
            child: Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, skylineHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      leading ?? const _DriverMenuButton(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: hasProfileAvatar
                              ? Image.network(
                                  avatarUrl,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _driverAvatarFallback(),
                                )
                              : _driverAvatarFallback(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      readOnly: onSearchSubmitted == null,
                      onSubmitted: onSearchSubmitted,
                      style: const TextStyle(
                        color: DriverColors.text,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: const TextStyle(
                          color: Color(0xFFAAB8C8),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFAAB8C8),
                          size: 21,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  content,
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.72,
              child: SizedBox(
                height: skylineHeight,
                child: Image.asset(
                  'assets/images/footer.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverAvatarFallback() {
    return Image.asset(
      'assets/images/agent.png',
      width: 38,
      height: 38,
      fit: BoxFit.cover,
    );
  }
}

class DriverStatusChip extends StatelessWidget {
  const DriverStatusChip({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? DriverColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: chipColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class DriverSurfaceCard extends StatelessWidget {
  const DriverSurfaceCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DriverBackChip extends StatelessWidget {
  const DriverBackChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          height: 44,
          width: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: DriverColors.text,
          ),
        ),
      ),
    );
  }
}

class DriverStatLine extends StatelessWidget {
  const DriverStatLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DriverColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(thickness: 1, color: DriverColors.line)),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            color: DriverColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class DriverBottomBar extends StatelessWidget {
  const DriverBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 8, 10, bottomInset > 0 ? 10 : 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _DriverBottomBarItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            Expanded(
              child: _DriverBottomBarItem(
                icon: Icons.directions_bike_rounded,
                label: 'Deliveries',
                isSelected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
            ),
            Expanded(
              child: _DriverBottomBarItem(
                icon: Icons.history_rounded,
                label: 'History',
                isSelected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
            ),
            Expanded(
              child: _DriverBottomBarItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: selectedIndex == 3,
                onTap: () => onSelected(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverBottomBarItem extends StatelessWidget {
  const _DriverBottomBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? DriverColors.blue : Colors.grey.shade400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? DriverColors.softBlue.withValues(alpha: 0.55)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  height: 1,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverMenuButton extends StatelessWidget {
  const _DriverMenuButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Scaffold.maybeOf(context)?.openDrawer(),
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.menu_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class DriverQuickAction {
  const DriverQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = DriverColors.blue,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
}

class DriverQuickActionStrip extends StatelessWidget {
  const DriverQuickActionStrip({required this.actions, super.key});

  final List<DriverQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: actions
            .map(
              (action) => Expanded(
                child: InkWell(
                  onTap: action.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: action.color.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(action.icon, color: action.color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DriverColors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
