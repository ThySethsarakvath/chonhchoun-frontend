import 'package:flutter/material.dart';

import '../../../shared/models/driver_request.dart';
import '../../../shared/widgets/driver_colors.dart';
import '../../../shared/widgets/driver_request_widgets.dart';
import '../../../shared/widgets/driver_shell_widgets.dart';
import '../driver_provider.dart';

class DriverHistoryTab extends StatelessWidget {
  const DriverHistoryTab({
    super.key,
    required this.onOpenDetail,
  });

  final ValueChanged<DriverRequest> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final provider = DriverScope.of(context);
    final history = provider.historyRequests;

    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchHistoryRequests();
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DriverHeroSection(
            subtitle: 'Completed Deliveries',
            name: 'History',
            content: DriverBalanceCard(amount: provider.balance.toStringAsFixed(2)),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: [
                  DriverSurfaceCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Delivered',
                              style: TextStyle(
                                color: DriverColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'All time completed jobs',
                              style: TextStyle(
                                color: DriverColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: DriverColors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${history.length} Jobs',
                            style: const TextStyle(
                              color: DriverColors.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Delivered Packages (${history.length})',
                          style: const TextStyle(
                            color: DriverColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 48,
                              color: DriverColors.muted,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No completed deliveries yet.',
                              style: TextStyle(color: DriverColors.muted, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...history.map((req) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DriverHomeRequestPreview(
                          request: req,
                          onTap: () => onOpenDetail(req),
                          showButtons: false,
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
