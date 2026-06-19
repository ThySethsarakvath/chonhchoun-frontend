import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../features/auth/tokens/token_storage.dart';
import '../data/driver_demo_data.dart';
import '../models/driver_earnings.dart';
import '../services/driver_dashboard_service.dart';
import '../widgets/driver_button_widgets.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_shell_widgets.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  final DriverDashboardService _service = DriverDashboardService();

  DriverEarningsRange _range = DriverEarningsRange.week;
  int? _selectedBar;

  DriverEarningsSummary? _summary;
  bool _loading = true;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final summary = await _service.fetchEarnings(token);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLive = true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DriverDayEarning> get _days {
    final weekly = _summary?.weekly;
    if (weekly != null && weekly.isNotEmpty) return weekly;
    return driverWeeklyEarnings;
  }

  List<DriverTransaction> get _transactions {
    final txns = _summary?.transactions;
    if (txns != null && txns.isNotEmpty) return txns;
    return driverRecentTransactions;
  }

  double get _availableBalance => _summary?.availableBalance ?? 168.0;

  double get _weekTotal => _days.fold(0.0, (sum, d) => sum + d.amount);

  int get _weekDeliveries => _days.fold(0, (sum, d) => sum + d.deliveries);

  ({double total, int deliveries}) get _rangeFigures {
    switch (_range) {
      case DriverEarningsRange.week:
        return (total: _weekTotal, deliveries: _weekDeliveries);
      case DriverEarningsRange.month:
        return (total: _weekTotal * 4.3, deliveries: (_weekDeliveries * 4.3).round());
      case DriverEarningsRange.all:
        final s = _summary;
        if (s != null && s.totalEarnings > 0) {
          return (total: s.totalEarnings, deliveries: s.completedDeliveries);
        }
        return (total: _weekTotal * 26.8, deliveries: (_weekDeliveries * 26.8).round());
    }
  }

  @override
  Widget build(BuildContext context) {
    final figures = _rangeFigures;
    final total = figures.total;
    final deliveries = figures.deliveries;
    final avgPerDelivery = deliveries == 0 ? 0.0 : total / deliveries;
    final onlineLabel = _summary?.onlineLabel ?? '42h 32m';
    final rating = _summary?.rating ?? 4.7;

    return Scaffold(
      backgroundColor: DriverColors.surface,
      body: RefreshIndicator(
        color: DriverColors.blue,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            DriverHeroSection(
              subtitle: 'Earnings',
              name: 'Your wallet',
              leading: DriverBackChip(onTap: () => Navigator.of(context).pop()),
              content: _EarningsTotalCard(
                total: total,
                rangeLabel: _range.label,
                loading: _loading,
                isLive: _isLive,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  children: [
                    _RangeSelector(
                      value: _range,
                      onChanged: (range) => setState(() => _range = range),
                    ),
                    const SizedBox(height: 18),
                    DriverSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Earnings overview',
                                  style: TextStyle(
                                    color: DriverColors.text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Text(
                                driverOverviewRange,
                                style: const TextStyle(
                                  color: DriverColors.muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 188,
                            child: _WeeklyBarChart(
                              days: _days,
                              selectedIndex: _selectedBar,
                              onBarTapped: (index) => setState(
                                () => _selectedBar =
                                    _selectedBar == index ? null : index,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StatsRow(
                      deliveries: deliveries,
                      hours: onlineLabel,
                      avgPerDelivery: avgPerDelivery,
                      rating: rating,
                    ),
                    const SizedBox(height: 16),
                    _CashOutCard(
                      available: _availableBalance,
                      onCashOut: () => _showCashOutSheet(context),
                    ),
                    const SizedBox(height: 16),
                    _TransactionsCard(transactions: _transactions),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCashOutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _CashOutSheet(
        available: _availableBalance,
        onConfirm: () {
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: DriverColors.success,
              content: Text(
                'Cashing out \$${_availableBalance.toStringAsFixed(2)} to your wallet',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EarningsTotalCard extends StatelessWidget {
  const _EarningsTotalCard({
    required this.total,
    required this.rangeLabel,
    required this.loading,
    required this.isLive,
  });

  final double total;
  final String rangeLabel;
  final bool loading;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DriverColors.softBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Earned · $rangeLabel',
                  style: const TextStyle(color: DriverColors.text, fontSize: 13),
                ),
              ),
              if (loading)
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DriverColors.blue,
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isLive ? DriverColors.success : DriverColors.muted)
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLive ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        size: 14,
                        color: isLive ? DriverColors.success : DriverColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLive ? 'Live' : 'Offline',
                        style: TextStyle(
                          color:
                              isLive ? DriverColors.success : DriverColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '\$',
                style: TextStyle(
                  color: DriverColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                total.toStringAsFixed(2),
                style: const TextStyle(
                  color: DriverColors.text,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.value, required this.onChanged});

  final DriverEarningsRange value;
  final ValueChanged<DriverEarningsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: DriverEarningsRange.values.map((range) {
          final isSelected = range == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(range),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? DriverColors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  range.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : DriverColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({
    required this.days,
    required this.selectedIndex,
    required this.onBarTapped,
  });

  final List<DriverDayEarning> days;
  final int? selectedIndex;
  final ValueChanged<int> onBarTapped;

  @override
  Widget build(BuildContext context) {
    final maxAmount = days
        .map((d) => d.amount)
        .fold(0.0, (max, amount) => amount > max ? amount : max);
    final maxY = maxAmount <= 0 ? 10.0 : (maxAmount * 1.25).ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => DriverColors.blueDark,
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItem: (group, _, rod, rodIndex) {
              final day = days[group.x];
              return BarTooltipItem(
                '\$${day.amount.toStringAsFixed(2)}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: '${day.deliveries} deliveries',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
          touchCallback: (event, response) {
            if (event.isInterestedForInteractions && response?.spot != null) {
              onBarTapped(response!.spot!.touchedBarGroupIndex);
            }
          },
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: DriverColors.line.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: const [5, 6],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) {
                  return const SizedBox.shrink();
                }
                final isSelected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    days[index].label,
                    style: TextStyle(
                      color:
                          isSelected ? DriverColors.blue : DriverColors.muted,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].amount,
                  width: 18,
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: selectedIndex == null || selectedIndex == i
                        ? const [DriverColors.blue, DriverColors.blueDark]
                        : [
                            DriverColors.blue.withValues(alpha: 0.28),
                            DriverColors.blue.withValues(alpha: 0.28),
                          ],
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: DriverColors.surface,
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.deliveries,
    required this.hours,
    required this.avgPerDelivery,
    required this.rating,
  });

  final int deliveries;
  final String hours;
  final double avgPerDelivery;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_shipping_rounded,
            value: '$deliveries',
            label: 'Deliveries',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.payments_rounded,
            value: '\$${avgPerDelivery.toStringAsFixed(2)}',
            label: 'Avg / trip',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.star_rounded,
            value: rating.toStringAsFixed(1),
            label: 'Rating',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: DriverColors.blue.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: DriverColors.blue, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: DriverColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: DriverColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashOutCard extends StatelessWidget {
  const _CashOutCard({required this.available, required this.onCashOut});

  final double available;
  final VoidCallback onCashOut;

  @override
  Widget build(BuildContext context) {
    return DriverSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: DriverColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: DriverColors.success),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available to cash out',
                      style: TextStyle(
                        color: DriverColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${available.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: DriverColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DriverPrimaryButton(
              label: 'Cash out',
              onPressed: onCashOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.transactions});

  final List<DriverTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return DriverSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent activity',
            style: TextStyle(
              color: DriverColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < transactions.length; i++) ...[
            _TransactionRow(transaction: transactions[i]),
            if (i != transactions.length - 1)
              const Divider(height: 22, thickness: 1, color: DriverColors.line),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final DriverTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isPayout = transaction.isPayout;
    final amountColor = isPayout ? DriverColors.text : DriverColors.success;
    final iconBg = isPayout
        ? DriverColors.muted.withValues(alpha: 0.12)
        : DriverColors.blue.withValues(alpha: 0.09);
    final iconColor = isPayout ? DriverColors.muted : DriverColors.blue;
    final sign = transaction.amount < 0 ? '-' : '+';

    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(transaction.icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DriverColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                transaction.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DriverColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$sign\$${transaction.amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              transaction.time,
              style: const TextStyle(
                color: DriverColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CashOutSheet extends StatelessWidget {
  const _CashOutSheet({required this.available, required this.onConfirm});

  final double available;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: DriverColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cash out',
              style: TextStyle(
                color: DriverColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Move your available balance to your linked wallet. '
              'Transfers usually arrive within a few minutes.',
              style: TextStyle(color: DriverColors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DriverColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      color: DriverColors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ABA · **** 4417',
                      style: TextStyle(
                        color: DriverColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '\$${available.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: DriverColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: DriverPrimaryButton(
                label: 'Confirm cash out',
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
