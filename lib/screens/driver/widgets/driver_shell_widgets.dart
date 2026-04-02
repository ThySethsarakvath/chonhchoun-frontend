import 'package:flutter/material.dart';

import '../widgets/driver_colors.dart';

class DriverHeroSection extends StatelessWidget {
  const DriverHeroSection({
    super.key,
    required this.subtitle,
    required this.name,
    required this.content,
    this.leading,
  });

  final String subtitle;
  final String name;
  final Widget content;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                name,
                                maxLines: 1,
                                softWrap: false,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/agent.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
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
              opacity: 0.32,
              child: Image.asset(
                'assets/images/footer.png',
                height: 90,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverStatusChip extends StatelessWidget {
  const DriverStatusChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: DriverColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: DriverColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DriverSurfaceCard extends StatelessWidget {
  const DriverSurfaceCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
  const DriverBackChip({
    super.key,
    required this.onTap,
  });

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
  const DriverStatLine({
    super.key,
    required this.label,
    required this.value,
  });

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
        const Expanded(
          child: Divider(
            thickness: 1,
            color: DriverColors.line,
          ),
        ),
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
        padding: EdgeInsets.fromLTRB(18, 8, 18, bottomInset > 0 ? 10 : 8),
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
            SizedBox(
              width: 84,
              child: _DriverBottomBarItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            SizedBox(
              width: 84,
              child: _DriverBottomBarItem(
                icon: Icons.work_history_rounded,
                label: 'Deliveries',
                isSelected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
            ),
            SizedBox(
              width: 84,
              child: _DriverBottomBarItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: selectedIndex == 2,
                onTap: () => onSelected(2),
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
      child: SizedBox(
        height: 56,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  height: 1,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
