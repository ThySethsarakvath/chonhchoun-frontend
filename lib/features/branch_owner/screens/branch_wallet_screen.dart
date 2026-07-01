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
      final results = await Future.wait([
        _walletService.getMyWallet(),
        _walletService.getMyWalletSummary(),
        _walletService.getMyTransactions(),
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
        _error = null;
        _walletView = _emptyWalletView;
        _summary = _emptySummary;
        _transactions = const [];
        _loading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const BranchOwnerLoadingCard(
        message: 'Loading branch wallet...',
      );
    }

    final walletView = _walletView ?? _emptyWalletView;
    final summary = _summary ?? _emptySummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionHero(
          title: 'Branch Wallet',
          description:
              'Track your branch logistics balance in one simple wallet view.',
          icon: Icons.account_balance_wallet_rounded,
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
              Text(
                'Current balance',
                style: const TextStyle(color: Color(0xFF64748B)),
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
              const Text(
                'Revenue split note: sender branch receives 70% and receiver branch receives 30% as soon as the paid ticket is created.',
                style: TextStyle(
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
              const Text(
                'Recent wallet transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 14),
              if (_transactions.isEmpty)
                const BranchOwnerMessageCard(
                  title: '0 USD',
                  description:
                      'No wallet transaction yet. Revenue will appear here after completed branch logistics shipments.',
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
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.call_received_rounded,
                            color: Color(0xFF15803D),
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
                                'Ticket: ${transaction.ticketNumber ?? '-'} • ${transaction.type} • ${transaction.status}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              if (transaction.revenueShareRole != null ||
                                  transaction.senderName != null ||
                                  transaction.receiverName != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${transaction.revenueShareRole ?? 'SHARE'}${transaction.revenueSharePercent != null ? ' • ${transaction.revenueSharePercent}%' : ''} • ${transaction.senderName ?? '-'} -> ${transaction.receiverName ?? '-'}',
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
                                  'Sender: ${transaction.senderPhone ?? '-'} • Receiver: ${transaction.receiverPhone ?? '-'} • Paid: ${transaction.totalPrice != null ? _money(transaction.totalPrice!, summary.currency) : '-'}',
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
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
