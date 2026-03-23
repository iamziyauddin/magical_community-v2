import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/models/user_model.dart';
import 'package:magical_community/models/payment_model.dart';
import 'package:magical_community/data/services/user_service.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final UserModel user;
  const PaymentHistoryScreen({super.key, required this.user});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final UserService _userService = UserService();
  final List<PaymentModel> _payments = [];
  bool _isLoading = false;
  bool _isInitialLoaded = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();
  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');
  final Set<String> _seenIds = {}; // suppress duplicates across pages

  @override
  void initState() {
    super.initState();
    _fetchPage(initial: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage({bool initial = false}) async {
    if (_isLoading || _isLoadingMore) return;
    if (!_hasMore && !initial) return;
    setState(() {
      if (initial) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });
    try {
      final result = await _userService.getUserTransactions(
        userId: widget.user.id,
        page: _currentPage,
        limit: _limit,
      );
      if (!mounted) return;
      result.when(
        success: (list) {
          int added = 0;
          for (final p in list) {
            if (_seenIds.add(p.id)) {
              _payments.add(p);
              added++;
            }
          }
          if (list.length < _limit) {
            _hasMore = false;
          } else {
            _currentPage += 1;
          }
        },
        failure: (msg, status) {
          _hasMore = false; // stop further attempts on failure for now
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load transactions: $msg')),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isInitialLoaded = true;
        });
      }
    }
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    _hasMore = true;
    _payments.clear();
    _seenIds.clear();
    await _fetchPage(initial: true);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    final threshold = 200.0; // px before the bottom
    if (_scrollController.position.maxScrollExtent -
            _scrollController.position.pixels <=
        threshold) {
      _fetchPage();
    }
  }

  double get _totalPaid => widget.user.totalPaid; // server-provided aggregate
  double get _totalDue => widget.user.dueAmount; // server-provided aggregate

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.name}\'s Payments'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
      ),
      backgroundColor: AppTheme.lightGrey,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSummaryCards(),
              ),
            ),
            if (_isLoading && !_isInitialLoaded)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_payments.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        size: 56,
                        color: AppTheme.darkGrey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions found',
                        style: TextStyle(
                          color: AppTheme.darkGrey.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pull down to refresh',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.darkGrey.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == _payments.length) {
                    return _buildLoadMore();
                  }
                  final p = _payments[index];
                  return _buildPaymentTile(p);
                }, childCount: _payments.length + 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            title: 'Total Paid',
            value: '₹${_totalPaid.toStringAsFixed(0)}',
            icon: Icons.check_circle,
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            title: 'Total Due',
            value: '₹${_totalDue.toStringAsFixed(0)}',
            icon: Icons.pending_actions,
            color: _totalDue > 0 ? AppTheme.errorRed : AppTheme.successGreen,
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkGrey.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(PaymentModel p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkGrey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              p.type == PaymentType.trial ? Icons.schedule : Icons.star,
              color: AppTheme.successGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.description?.isNotEmpty == true
                      ? p.description!
                      : (p.type == PaymentType.trial
                            ? 'Trial Payment'
                            : 'Membership Payment'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateFmt.format(p.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGrey.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${p.amount.toInt()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successGreen,
                ),
              ),
              const SizedBox(height: 2),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppTheme.darkGrey.withOpacity(0.6),
                  size: 16,
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDeletePayment(p);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppTheme.errorRed, size: 16),
                        SizedBox(width: 6),
                        Text('Delete', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeletePayment(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text('Delete Payment'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this payment of ₹${payment.amount.toInt()}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _deletePayment(payment);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePayment(PaymentModel payment) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Deleting payment...'),
          ],
        ),
      ),
    );

    try {
      final result = await _userService.deleteMemberPayment(
        memberId: widget.user.id,
        paymentId: payment.id,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      result.when(
        success: (_) {
          // Remove from local list
          setState(() {
            _payments.removeWhere((p) => p.id == payment.id);
            _seenIds.remove(payment.id);
          });

          // Update user totals (optimistic update)
          widget.user.totalPaid = widget.user.totalPaid - payment.amount;
          widget.user.dueAmount = widget.user.dueAmount + payment.amount;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.white),
                  SizedBox(width: 8),
                  Text('Payment deleted successfully'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        },
        failure: (message, statusCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete payment: $message'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Widget _buildLoadMore() {
    if (!_hasMore) {
      return const SizedBox(height: 80); // end padding
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator()
            : TextButton.icon(
                onPressed: _fetchPage,
                icon: const Icon(Icons.expand_more),
                label: const Text('Load More'),
              ),
      ),
    );
  }
}
