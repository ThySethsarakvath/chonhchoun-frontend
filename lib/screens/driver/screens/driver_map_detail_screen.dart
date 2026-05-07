import 'package:flutter/material.dart';

import '../../../shared/models/driver_request.dart';
import '../../../shared/widgets/app_button_widgets.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/widgets/app_map_widgets.dart';
import '../../../shared/widgets/app_shell_widgets.dart';

class DriverMapDetailScreen extends StatelessWidget {
  const DriverMapDetailScreen({
    super.key,
    required this.request,
  });

  final DriverRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: AppDecisionBar(
        primaryLabel: 'Accept',
        secondaryLabel: 'Reject',
        onPrimaryPressed: () => Navigator.of(context).pop(),
        onSecondaryPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.blueDark, AppColors.blue],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppBackChip(onTap: () => Navigator.of(context).pop()),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Request Map Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  const DriverLeafletMapCard(
                    interactive: true,
                    showAttribution: true,
                    overlay: DriverLiveMapOverlay(),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            request.title,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Simple placeholder map for now.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
}
