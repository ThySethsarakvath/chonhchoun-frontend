import 'package:flutter/material.dart';
import '../router/app_router.dart';
import '../features/home/widgets/home_bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _navIndex = 3; // Settings tab index

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
        // Already on settings
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
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      extendBody: true,
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _navIndex,
        onTap: _handleNavigation,
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Center(
                    child: Text(
                      'ការកំណត់',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2D3D),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                    children: [
                      _SectionLabel(label: 'គណនី'),
                      _SettingsCard(
                        items: [
                          _SettingsItem(
                            icon: Icons.person_outline_rounded,
                            label: 'កែប្រែប្រវត្តិរូប',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.profile,
                                arguments: ProfileArgs(
                                  source: ProfileSource.settings,
                                ),
                              );
                            },
                          ),
                          _SettingsItem(
                            icon: Icons.shield_outlined,
                            label: 'សុវត្ថិភាព',
                            onTap: () {},
                          ),
                          _SettingsItem(
                            icon: Icons.notifications_none_rounded,
                            label: 'ការជូនដំណឹង',
                            onTap: () {},
                          ),
                          _SettingsItem(
                            icon: Icons.lock_outline_rounded,
                            label: 'ឯកជនភាព',
                            onTap: () {},
                            showDivider: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _SectionLabel(label: 'អំពីយើង'),
                      _SettingsCard(
                        items: [
                          _SettingsItem(
                            icon: Icons.credit_card_outlined,
                            label: 'ការជាវ',
                            onTap: () {},
                          ),
                          _SettingsItem(
                            icon: Icons.help_outline_rounded,
                            label: 'ជំនួយការ',
                            onTap: () {},
                          ),
                          _SettingsItem(
                            icon: Icons.info_outline_rounded,
                            label: 'លក្ខខណ្ឌ និងគោលការណ៍',
                            onTap: () {},
                            showDivider: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _SectionLabel(label: 'ទិន្នន័យ'),
                      _SettingsCard(
                        items: [
                          _SettingsItem(
                            icon: Icons.storage_outlined,
                            label: 'បង្កើនទំហំទំនេរ',
                            onTap: () {},
                          ),
                          _SettingsItem(
                            icon: Icons.data_saver_on_outlined,
                            label: 'សន្សំសំចៃទិន្នន័យ',
                            onTap: () {},
                            showDivider: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _SectionLabel(label: 'ផ្សេងៗ'),
                      _SettingsCard(
                        items: [
                          _SettingsItem(
                            icon: Icons.flag_outlined,
                            label: 'រាយការណ៍បញ្ហា',
                            onTap: () {},
                          ),
                          _SettingsItem(
                            icon: Icons.person_add_outlined,
                            label: 'បន្ថែមគណនីថ្មី',
                            onTap: () {},
                            showDivider: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A8DDB),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── White card wrapping a list of items ──────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C5F8A).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }
}

// ── Individual settings row ───────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF2C5F8A), size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3A4E),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFBCC8D8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 66,
            endIndent: 16,
            color: Color(0xFFF0F4FA),
          ),
      ],
    );
  }
}
