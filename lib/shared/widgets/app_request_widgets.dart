import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../models/driver_request.dart';
import 'app_button_widgets.dart';
import 'app_shell_widgets.dart';

class AppBalanceCard extends StatelessWidget {
  const AppBalanceCard({super.key, required this.amount});
  final String amount;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.softBlue, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Available balance', style: TextStyle(color: AppColors.text, fontSize: 13)),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('\$', style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(amount, style: const TextStyle(color: AppColors.text, fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          const Padding(padding: EdgeInsets.only(bottom: 6), child: Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.muted)),
        ]),
      ]),
    );
  }
}

class AppStatusSummary extends StatelessWidget {
  const AppStatusSummary({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.softBlue, borderRadius: BorderRadius.circular(20)),
      child: const Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Driver status', style: TextStyle(color: AppColors.text, fontSize: 13)),
          SizedBox(height: 8),
          Text('Ready for pickups', style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w700)),
        ])),
        AppStatusChip(label: 'Online'),
      ]),
    );
  }
}

class AppHomeRequestPreview extends StatelessWidget {
  const AppHomeRequestPreview({super.key, required this.request, required this.onTap, this.showButtons = true});
  final DriverRequest request;
  final VoidCallback onTap;
  final bool showButtons;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8))]),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(request.title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 18))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: request.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)), child: Text(request.fee, style: TextStyle(color: request.accent, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 8),
          Text('Recipient: ${request.recipient}', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          AppMiniRouteLine(pickup: request.pickup, dropOff: request.dropOff),
          const SizedBox(height: 16),
          Row(children: [AppDetailChip(icon: Icons.timer_outlined, text: request.eta), const SizedBox(width: 10), AppDetailChip(icon: Icons.credit_card_outlined, text: request.payment)]),
          if (showButtons) ...[
            const SizedBox(height: 18),
            Row(children: [Expanded(child: AppSoftButton(label: 'Reject', onPressed: () {})), const SizedBox(width: 12), Expanded(child: AppPrimaryButton(label: 'Accept', onPressed: onTap))]),
          ],
        ])),
      ),
    );
  }
}

class AppRequestCard extends StatelessWidget {
  const AppRequestCard({super.key, required this.request, required this.onOpenDetail});
  final DriverRequest request;
  final VoidCallback onOpenDetail;
  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(request.title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 18))),
        Text(request.fee, style: TextStyle(color: request.accent, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 6),
      Text('Recipient: ${request.recipient}', style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 16),
      AppMiniRouteLine(pickup: request.pickup, dropOff: request.dropOff),
      const SizedBox(height: 18),
      Row(children: [Expanded(child: AppSoftButton(label: 'Reject', onPressed: () {})), const SizedBox(width: 12), Expanded(child: AppPrimaryButton(label: 'Accept', onPressed: onOpenDetail))]),
    ]));
  }
}

class AppMiniRouteLine extends StatelessWidget {
  const AppMiniRouteLine({super.key, required this.pickup, required this.dropOff});
  final String pickup;
  final String dropOff;
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Column(children: [
        Icon(Icons.location_on_rounded, size: 18, color: AppColors.danger),
        SizedBox(height: 2), Icon(Icons.more_vert_rounded, size: 16, color: AppColors.line),
        SizedBox(height: 2), Icon(Icons.circle_rounded, size: 14, color: AppColors.success),
      ]),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pickup  $pickup', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 10),
        Text(dropOff, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600)),
      ])),
    ]);
  }
}

class AppDetailChip extends StatelessWidget {
  const AppDetailChip({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18, color: AppColors.blue), const SizedBox(width: 8), Text(text, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600))]),
    );
  }
}

class AppInfoBlock extends StatelessWidget {
  const AppInfoBlock({super.key, required this.label, required this.value, this.emphasize = false});
  final String label;
  final String value;
  final bool emphasize;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: emphasize ? AppColors.blue : AppColors.text, fontSize: emphasize ? 24 : 16, fontWeight: FontWeight.w700)),
    ]);
  }
}

class AppRoutePoint extends StatelessWidget {
  const AppRoutePoint({super.key, required this.icon, required this.iconColor, required this.label, required this.value, this.compact = false});
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: compact ? 18 : 20, color: iconColor),
      const SizedBox(width: 14),
      Expanded(child: compact ? const SizedBox(height: 10) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w600)),
      ])),
    ]);
  }
}

class AppPickupThumbnail extends StatelessWidget {
  const AppPickupThumbnail({super.key, required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64, width: 64,
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.72)]), borderRadius: BorderRadius.circular(20)),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
