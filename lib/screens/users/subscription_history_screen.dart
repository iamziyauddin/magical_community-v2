import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/models/user_model.dart';
import 'package:magical_community/data/services/user_service.dart';

class SubscriptionHistoryScreen extends StatefulWidget {
  final UserModel user;

  const SubscriptionHistoryScreen({super.key, required this.user});

  @override
  State<SubscriptionHistoryScreen> createState() =>
      _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState extends State<SubscriptionHistoryScreen> {
  final UserService _userService = UserService();
  List<SubscriptionRecord> _subscriptions = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  final int _limit = 30;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreSubscriptions();
    }
  }

  Future<void> _loadSubscriptions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _subscriptions.clear();
        _hasMoreData = true;
      });
    }

    setState(() {
      _isLoading = reset || _subscriptions.isEmpty;
      _errorMessage = null;
    });

    try {
      final result = await _userService.getUserSubscriptions(
        userId: widget.user.id,
        page: _currentPage,
        limit: _limit,
      );

      if (!mounted) return;

      result.when(
        success: (data) {
          final subscriptions = data['data'] as List;
          final meta = data['meta'] as Map<String, dynamic>;

          setState(() {
            if (reset) {
              _subscriptions = subscriptions
                  .map((item) => SubscriptionRecord.fromJson(item))
                  .toList();
            } else {
              _subscriptions.addAll(
                subscriptions
                    .map((item) => SubscriptionRecord.fromJson(item))
                    .toList(),
              );
            }

            _currentPage = meta['page'] as int;
            _hasMoreData = meta['page'] < meta['totalPages'];
            _isLoading = false;
            _isLoadingMore = false;
            _errorMessage = null;
          });
        },
        failure: (message, statusCode) {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            _errorMessage = message.isNotEmpty
                ? message
                : 'Failed to load subscription history';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Error loading subscriptions: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMoreSubscriptions() async {
    if (!_hasMoreData || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadSubscriptions();
  }

  Future<void> _refresh() async {
    await _loadSubscriptions(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: Text('${widget.user.name} - Subscription History'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _subscriptions.isEmpty
            ? _buildEmptyState()
            : _buildSubscriptionList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadSubscriptions(reset: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: AppTheme.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Subscription History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No subscription records found for ${widget.user.name}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _subscriptions.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoadingMore && index == _subscriptions.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final subscription = _subscriptions[index];
        return _buildSubscriptionCard(subscription, index);
      },
    );
  }

  Widget _buildSubscriptionCard(SubscriptionRecord subscription, int index) {
    final isActive = subscription.isActive;
    final isTrial = subscription.subscriptionPlan?.isTrial ?? false;

    Color statusColor = isActive
        ? AppTheme.successGreen
        : AppTheme.darkGrey.withOpacity(0.6);

    Color typeColor = isTrial ? AppTheme.accentYellow : AppTheme.infoBlue;

    return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppTheme.successGreen.withOpacity(0.3)
                    : AppTheme.darkGrey.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with status and type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? Icons.check_circle : Icons.history,
                              color: statusColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'Active' : 'Completed',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: typeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          isTrial ? 'Trial' : 'Membership',
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Plan name
                  Text(
                    subscription.subscriptionPlan?.name ?? 'Unknown Plan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlack,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Duration
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppTheme.darkGrey.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(subscription.startDate)} - ${_formatDate(subscription.endDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkGrey.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Financial details
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          'Total',
                          '₹${subscription.totalPayable.toInt()}',
                          AppTheme.infoBlue,
                          Icons.account_balance_wallet,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          'Paid',
                          '₹${subscription.totalPaid.toInt()}',
                          AppTheme.successGreen,
                          Icons.payment,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          'Due',
                          '₹${subscription.dueAmount.toInt()}',
                          subscription.dueAmount > 0
                              ? AppTheme.errorRed
                              : AppTheme.successGreen,
                          Icons.pending_actions,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Shake details
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          'Total Shakes',
                          '${subscription.totalShake}',
                          AppTheme.accentYellow,
                          Icons.local_drink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          'Consumed',
                          '${subscription.totalConsumedShake}',
                          AppTheme.successGreen,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          'Remaining',
                          '${subscription.totalDueShake}',
                          subscription.totalDueShake > 0
                              ? AppTheme.infoBlue
                              : AppTheme.successGreen,
                          Icons.pending,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Created date
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: AppTheme.darkGrey.withOpacity(0.5),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Created: ${_formatDate(subscription.createdAt)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkGrey.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: index * 100))
        .slideX(begin: 0.3, duration: 400.ms)
        .fadeIn();
  }

  Widget _buildInfoChip(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.darkGrey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Model for subscription records
class SubscriptionRecord {
  final String id;
  final String userId;
  final String clubId;
  final String type;
  final String subscriptionPlanId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPayable;
  final double totalPaid;
  final double dueAmount;
  final int totalShake;
  final int totalDueShake;
  final int totalConsumedShake;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SubscriptionPlan? subscriptionPlan;

  SubscriptionRecord({
    required this.id,
    required this.userId,
    required this.clubId,
    required this.type,
    required this.subscriptionPlanId,
    required this.startDate,
    required this.endDate,
    required this.totalPayable,
    required this.totalPaid,
    required this.dueAmount,
    required this.totalShake,
    required this.totalDueShake,
    required this.totalConsumedShake,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionPlan,
  });

  factory SubscriptionRecord.fromJson(Map<String, dynamic> json) {
    return SubscriptionRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      clubId: json['clubId'] as String,
      type: json['type'] as String,
      subscriptionPlanId: json['subscriptionPlanId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalPayable: (json['totalPayable'] as num).toDouble(),
      totalPaid: (json['totalPaid'] as num).toDouble(),
      dueAmount: (json['dueAmount'] as num).toDouble(),
      totalShake: json['totalShake'] as int,
      totalDueShake: json['totalDueShake'] as int,
      totalConsumedShake: json['totalConsumedShake'] as int,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      subscriptionPlan: json['subscriptionPlan'] != null
          ? SubscriptionPlan.fromJson(json['subscriptionPlan'])
          : null,
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final bool isTrial;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.isTrial,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      isTrial: json['isTrial'] as bool,
    );
  }
}
