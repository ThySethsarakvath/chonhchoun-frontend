import 'package:flutter/material.dart';

import '../../branch_wallet/models/branch_wallet_models.dart';
import '../../branch_wallet/services/branch_wallet_service.dart';
import '../widgets/branch_owner_content_widgets.dart';

class BranchWalletScreen extends StatefulWidget {
  const BranchWalletScreen({super.key});

  @override
  State<BranchWalletScreen> createState() => _BranchWalletScreenState();
}

class _BranchWalletScreenState extends State<BranchWalletScreen> {
  final BranchWalletService _walletService = BranchWalletService();

  bool _loading = true;
  String? _error;
  BranchWalletView? _walletView;
  BranchWalletSummary? _summary;
  List<BranchWalletTransaction> _transactions = const [];
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  static const BranchWalletView _emptyWalletView = BranchWalletView(
    branch: BranchWalletBranchInfo(
      id: '',
      name: 'Branch Wallet',
    ),
    wallet: BranchWalletInfo(
      id: '',
      availableBalance: 0,
      pendingBalance: 0,
      totalCredited: 0,
      totalDebited: 0,
      currency: 'USD',
    ),
  );

  static const BranchWalletSummary _emptySummary = BranchWalletSummary(
    branchId: '',
    availableBalance: 0,
    pendingBalance: 0,
    totalCredited: 0,
    totalDebited: 0,
    netBalance: 0,
    currency: 'USD',
  );

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final monthRange = _selectedMonthRange;
      final results = await Future.wait([
        _walletService.getMyWallet(),
        _walletService.getMyWalletSummary(),
        _walletService.getMyTransactions(
          dateFrom: monthRange.start.toIso8601String(),
          dateTo: monthRange.end.toIso8601String(),
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _walletView = results[0] as BranchWalletView;
        _summary = results[1] as BranchWalletSummary;
        _transactions = results[2] as List<BranchWalletTransaction>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _walletView = _emptyWalletView;
        _summary = _emptySummary;
        _transactions = const [];
        _loading = false;
      });
    }
  }

  _MonthRange get _selectedMonthRange {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month);
    final end = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
    ).subtract(const Duration(milliseconds: 1));
    return _MonthRange(start: start, end: end);
  }

  List<DateTime> get _availableMonths {
    final months = <DateTime>[];
    final now = DateTime.now();
    for (var offset = 0; offset < 12; offset += 1) {
      months.add(DateTime(now.year, now.month - offset));
    }
    return months;
  }

  _BranchRevenueMetrics get _monthlyMetrics {
    final tickets = <String, double>{};
    var grossRevenue = 0.0;
    var branchIncome = 0.0;
    int? sharePercent;

    for (final transaction in _transactions) {
      if (transaction.status != 'POSTED') continue;

      final sign = transaction.type == 'DEBIT' ? -1.0 : 1.0;
      branchIncome += transaction.amount * sign;

      if (transaction.totalPrice != null) {
        grossRevenue += transaction.totalPrice! * sign;
      }

      if (sharePercent == null &&
          transaction.type == 'CREDIT' &&
          transaction.revenueSharePercent != null) {
        sharePercent = transaction.revenueSharePercent;
      }

      final ticket = transaction.ticketNumber?.trim();
      if (ticket != null && ticket.isNotEmpty) {
        tickets[ticket] = (tickets[ticket] ?? 0) + sign;
      }
    }

    return _BranchRevenueMetrics(
      grossRevenue: grossRevenue,
      branchIncome: branchIncome,
      completedTickets: tickets.values.where((value) => value > 0).length,
      sharePercent: sharePercent,
    );
  }

  String _money(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  String _dateLabel(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  String _monthLabel(DateTime value) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[value.month - 1]} ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const BranchOwnerLoadingCard(
        message: 'Loading branch wallet...',
      );
    }

    final walletView = _walletView ?? _emptyWalletView;
    final summary = _summary ?? _emptySummary;
    final metrics = _monthlyMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionHero(
          title: 'Branch Wallet',
          description:
              'Track branch balance, monthly income, and revenue-sharing activity in one clear view.',
          icon: Icons.account_balance_wallet_rounded,
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          BranchOwnerMessageCard(
            title: 'Unable to load branch wallet',
            description: _error!,
            actionLabel: 'Try again',
            onAction: _loadWallet,
          ),
          const SizedBox(height: 20),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                walletView.branch.name.isEmpty
                    ? 'Branch Owner Wallet'
                    : '${walletView.branch.name} Wallet',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Current balance',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              Text(
                _money(summary.availableBalance, summary.currency),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                metrics.sharePercent == null
                    ? 'Revenue share is applied automatically when paid branch logistics tickets are created.'
                    : 'Current branch share in this report: ${metrics.sharePercent}%.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Revenue Report',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Review branch revenue, branch income, and completed tickets by month.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<DateTime>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _availableMonths
                          .map(
                            (month) => DropdownMenuItem<DateTime>(
                              value: month,
                              child: Text(_monthLabel(month)),
                            ),
                          )
                          .toList(),
                      onChanged: (month) async {
                        if (month == null) return;
                        setState(
                          () => _selectedMonth = DateTime(
                            month.year,
                            month.month,
                          ),
                        );
                        await _loadWallet();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _RevenueStatCard(
                    label: 'Total Revenue',
                    value: _money(metrics.grossRevenue, summary.currency),
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF1D4ED8),
                  ),
                  _RevenueStatCard(
                    label: 'Branch Income',
                    value: _money(metrics.branchIncome, summary.currency),
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF15803D),
                  ),
                  _RevenueStatCard(
                    label: 'Completed Tickets',
                    value: '${metrics.completedTickets}',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                  _RevenueStatCard(
                    label: 'Branch Share',
                    value: metrics.sharePercent == null
                        ? '-'
                        : '${metrics.sharePercent}%',
                    icon: Icons.pie_chart_rounded,
                    color: const Color(0xFFB45309),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transactions for selected month',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 14),
              if (_transactions.isEmpty)
                const BranchOwnerMessageCard(
                  title: 'No revenue for this month',
                  description:
                      'No wallet transactions were found for the selected month. Try another month or complete more branch logistics deliveries.',
                )
              else
                ..._transactions.map((transaction) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: transaction.type == 'DEBIT'
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            transaction.type == 'DEBIT'
                                ? Icons.call_made_rounded
                                : Icons.call_received_rounded,
                            color: transaction.type == 'DEBIT'
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ticket: ${transaction.ticketNumber ?? '-'} | ${transaction.type} | ${transaction.status}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              if (transaction.revenueShareRole != null ||
                                  transaction.senderName != null ||
                                  transaction.receiverName != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${transaction.revenueShareRole ?? 'SHARE'}${transaction.revenueSharePercent != null ? ' | ${transaction.revenueSharePercent}%' : ''} | ${transaction.senderName ?? '-'} -> ${transaction.receiverName ?? '-'}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                              if (transaction.senderPhone != null ||
                                  transaction.receiverPhone != null ||
                                  transaction.totalPrice != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Sender: ${transaction.senderPhone ?? '-'} | Receiver: ${transaction.receiverPhone ?? '-'} | Paid: ${transaction.totalPrice != null ? _money(transaction.totalPrice!, summary.currency) : '-'}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _money(transaction.amount, summary.currency),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: transaction.type == 'DEBIT'
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF15803D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _dateLabel(transaction.createdAt),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueStatCard extends StatelessWidget {
  const _RevenueStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchRevenueMetrics {
  const _BranchRevenueMetrics({
    required this.grossRevenue,
    required this.branchIncome,
    required this.completedTickets,
    required this.sharePercent,
  });

  final double grossRevenue;
  final double branchIncome;
  final int completedTickets;
  final int? sharePercent;
}

class _MonthRange {
  const _MonthRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}
