import 'package:flutter/material.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/widgets/app_shell_widgets.dart';

class CustomerProfileTab extends StatelessWidget {
  const CustomerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildProfileHeader()),
          SliverToBoxAdapter(child: _buildSummaryCards()),
          SliverToBoxAdapter(child: _buildActionList()),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return const SliverAppBar(
      expandedHeight: 60,
      pinned: true,
      backgroundColor: AppColors.blueDark,
      title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.blueDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: AppColors.blue),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "រតនៈ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "ratanak@chonhchoun.com",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStatCard("Total Orders", "12", Icons.shopping_bag_outlined),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: AppSurfaceCard(
        child: Column(
          children: [
            Icon(icon, color: AppColors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppSurfaceCard(
        child: Column(
          children: [
            _buildActionItem(Icons.person_outline, "Update Information"),
            const Divider(),
            _buildActionItem(Icons.payment_outlined, "Payment Methods"),
            const Divider(),
            _buildActionItem(Icons.help_outline, "Help Center"),
            const Divider(),
            _buildActionItem(Icons.logout, "Logout", isDanger: true),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String label, {
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? AppColors.danger : AppColors.blue,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDanger ? AppColors.danger : AppColors.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      contentPadding: EdgeInsets.zero,
      onTap: () {},
    );
  }
}
