import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/models/user_model.dart';
import 'package:magical_community/data/services/user_service.dart';
import 'package:magical_community/screens/users/edit_user_details_screen.dart';
import 'package:magical_community/widgets/subscription_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class VisitorDetailScreen extends StatefulWidget {
  final UserModel visitor;

  const VisitorDetailScreen({super.key, required this.visitor});

  @override
  State<VisitorDetailScreen> createState() => _VisitorDetailScreenState();
}

class _VisitorDetailScreenState extends State<VisitorDetailScreen> {
  final UserService _userService = UserService();
  UserModel? _currentVisitor; // Nullable since we fetch from API first
  bool _detailsUpdated = false; // track if details were updated
  bool _isLoading = false;
  String? _loadError;

  // TODO: Provide actual clubId from session/context. For now keeping a placeholder.
  // This should eventually be injected via a Session/Club provider.
  final String _clubId = 'cmeqz2jnu001x12qwdziw2vm3';

  @override
  void initState() {
    super.initState();
    // API-first approach: don't initialize with widget.visitor, fetch fresh data
    _isLoading = true;
    _fetchLatestDetail();
  }

  Future<void> _fetchLatestDetail() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final result = await _userService.getUserDetail(
      userId: widget
          .visitor
          .id, // Use widget.visitor.id since _currentVisitor might be null initially
      clubId: _clubId,
    );
    if (!mounted) return;
    result.when(
      success: (user) {
        setState(() {
          _currentVisitor = user;
          _isLoading = false;
        });
      },
      failure: (msg, int? statusCode) {
        setState(() {
          _isLoading = false;
          _loadError = msg.isNotEmpty ? msg : 'Failed to load details';
          // Fallback to list data only if API fails completely
          _currentVisitor = widget.visitor;
        });
      },
    );
  }

  Future<void> _openEditDetailsScreen() async {
    final currentVisitor = _currentVisitor ?? widget.visitor;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditUserDetailsScreen(user: currentVisitor),
      ),
    );
    if (result != null && result['detailsUpdated'] == true) {
      final updated = result['updatedUser'] as UserModel;
      // Replace the entire _currentVisitor object to ensure all fields are properly updated
      setState(() {
        _currentVisitor = updated;
        _detailsUpdated = true;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle null visitor during API loading
    final visitor = _currentVisitor ?? widget.visitor;
    // Refined membership check: only treat as membership when upcoming OR active has real membershipType == 'membership'
    final upcoming = visitor.upcomingSubscription;
    final active = visitor.activeMembership;
    // MembershipType-driven UI: if membershipType == 'visitor' => show Upgrade, else show Membership
    final String membershipType =
        (visitor.membershipType ?? widget.visitor.membershipType ?? '')
            .toLowerCase()
            .trim();
    final bool _hasMembershipUI =
        membershipType.isNotEmpty && membershipType != 'visitor';

    // Debug to trace decisions
    // ignore: avoid_print
    print(
      'DEBUG(build): membershipType=$membershipType => _hasMembershipUI=$_hasMembershipUI',
    );

    // Debug build-time log to trace false positives
    // (Remove or gate behind a debug flag if too noisy later.)
    // These prints help when label shows Membership unexpectedly.
    // Shows raw membershipType + status values.
    // ignore: avoid_print
    print(
      'DEBUG(build): upcoming=${upcoming != null} upcomingType=${upcoming?.membershipType} active=${active != null} activeType=${active?.membershipType} activeStatus=${active?.status} -> _hasMembershipUI=$_hasMembershipUI',
    );

    return WillPopScope(
      onWillPop: () async {
        // Always return updated visitor data to refresh the list
        Navigator.of(context).pop(_detailsUpdated ? _currentVisitor : null);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: AppBar(
          title: Text('${visitor.name} - Visitor Details'),
          backgroundColor: AppTheme.darkGrey,
          foregroundColor: AppTheme.white,
          elevation: 0,
          leading: BackButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pop(_detailsUpdated ? _currentVisitor : null);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Details',
              onPressed: _currentVisitor != null
                  ? _openEditDetailsScreen
                  : null,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _loadError != null
              ? Column(
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _fetchLatestDetail,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Profile Header
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.white,
                              AppTheme.darkGrey.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.darkGrey,
                              child: Text(
                                visitor.name.isNotEmpty
                                    ? visitor.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              visitor.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlack,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.darkGrey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Visitor',
                                style: TextStyle(
                                  color: AppTheme.primaryBlack,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().scale(duration: 600.ms),

                    const SizedBox(height: 16),

                    // Contact Information
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlack,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildClickablePhoneRow(
                              Icons.phone,
                              'Mobile',
                              visitor.mobileNumber,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.location_on,
                              'Address',
                              visitor.address,
                            ),
                            const SizedBox(height: 12),

                            _buildInfoRow(
                              Icons.group,
                              'Referred By',
                              (visitor.referredByName != null &&
                                      visitor.referredByName!.isNotEmpty)
                                  ? visitor.referredByName!
                                  : 'Direct',
                            ),
                          ],
                        ),
                      ),
                    ).animate().slide(
                      begin: const Offset(-1, 0),
                      delay: 200.ms,
                    ),

                    const SizedBox(height: 16),

                    // Visit Information
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Visit Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlack,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Visit Date',
                              _formatDate(visitor.visitDate),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.person_outline,
                              'Status',
                              'Visitor - Not Enrolled',
                            ),
                          ],
                        ),
                      ),
                    ).animate().slide(begin: const Offset(1, 0), delay: 300.ms),

                    const SizedBox(height: 16),

                    // Interest Assessment
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Interest & Follow-up',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlack,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.accentYellow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.accentYellow.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Potential UMS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This visitor showed interest in our wellness programs. Consider following up for UMS conversion.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.darkGrey.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().slide(
                      begin: const Offset(-1, 0),
                      delay: 400.ms,
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlack,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Debug: Check membership status (upcoming or active)
                                      print(
                                        'DEBUG: visitor.hasUpcomingSubscription = ${visitor.hasUpcomingSubscription}',
                                      );
                                      print(
                                        'DEBUG: visitor.upcomingSubscription != null => ${visitor.upcomingSubscription != null}',
                                      );
                                      print(
                                        'DEBUG: visitor.activeMembership != null => ${visitor.activeMembership != null}',
                                      );

                                      if (_hasMembershipUI) {
                                        // Show membership details (upcoming or active)
                                        _showMembershipDetailsDialog();
                                      } else {
                                        // Always allow upgrade - no membership checks
                                        final screenContext = context;
                                        showDialog(
                                          context: context,
                                          builder: (context) => SubscriptionDialog(
                                            config: SubscriptionDialogConfig.visitorUpgrade(
                                              userName: visitor.name,
                                              onConfirm: (plan, amount, startDate) async {
                                                if (!mounted) return;
                                                try {
                                                  // Format the start date for API (YYYY-MM-DD)
                                                  final formattedStartDate =
                                                      '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

                                                  final result = await _userService
                                                      .renewSubscription(
                                                        memberId: visitor.id,
                                                        subscriptionPlanId:
                                                            plan.id,
                                                        amount: amount,
                                                        startDate:
                                                            formattedStartDate,
                                                      );

                                                  if (!mounted) return;

                                                  result.when(
                                                    success: (_) {
                                                      // Update current visitor with subscription success
                                                      setState(() {
                                                        _detailsUpdated = true;
                                                      });

                                                      ScaffoldMessenger.of(
                                                        screenContext,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '${visitor.name} upgraded to ${plan.name} with ₹${amount.toStringAsFixed(2)} payment!',
                                                          ),
                                                          backgroundColor:
                                                              AppTheme
                                                                  .successGreen,
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          duration:
                                                              const Duration(
                                                                seconds: 4,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    failure: (message, statusCode) {
                                                      ScaffoldMessenger.of(
                                                        screenContext,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Failed to upgrade subscription: $message',
                                                          ),
                                                          backgroundColor:
                                                              AppTheme.errorRed,
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          duration:
                                                              const Duration(
                                                                seconds: 5,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                } catch (e) {
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(
                                                    screenContext,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Unexpected error: ${e.toString()}',
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.errorRed,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      duration: const Duration(
                                                        seconds: 5,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      _hasMembershipUI
                                          ? Icons.card_membership
                                          : Icons.person_add,
                                      size: 20,
                                    ),
                                    label: Text(
                                      _hasMembershipUI
                                          ? 'Membership'
                                          : 'Upgrade',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _hasMembershipUI
                                          ? AppTheme.successGreen
                                          : AppTheme.accentYellow,
                                      foregroundColor: _hasMembershipUI
                                          ? AppTheme.white
                                          : AppTheme.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().slide(begin: const Offset(0, 1), delay: 500.ms),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.darkGrey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkGrey.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClickablePhoneRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.darkGrey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkGrey.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => _makePhoneCall(value),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.accentYellow,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.phone, color: AppTheme.accentYellow, size: 18),
      ],
    );
  }

  void _showMembershipDetailsDialog() {
    final visitor = _currentVisitor ?? widget.visitor;
    final upcomingSub = visitor.upcomingSubscription;
    final active = visitor.activeMembership;
    // Do not early-return; if both are null, show a simple fallback message.

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.card_membership, color: AppTheme.successGreen, size: 24),
            const SizedBox(width: 8),
            const Text('Membership Details'),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (upcomingSub != null) ...[
                Text(
                  '${visitor.name} has an upcoming membership:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 16),

                // Membership Type
                _buildMembershipDetailRow(
                  'Membership Type',
                  (upcomingSub.membershipType ?? 'N/A').toUpperCase(),
                  Icons.star,
                  AppTheme.successGreen,
                ),
                const SizedBox(height: 12),

                // Total Payable
                _buildMembershipDetailRow(
                  'Total Amount',
                  '₹${upcomingSub.totalPayable.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  AppTheme.infoBlue,
                ),
                const SizedBox(height: 12),

                // Amount Paid
                _buildMembershipDetailRow(
                  'Amount Paid',
                  '₹${upcomingSub.totalPaid.toStringAsFixed(0)}',
                  Icons.payment,
                  AppTheme.successGreen,
                ),
                const SizedBox(height: 12),

                // Due Amount
                if (upcomingSub.dueAmount > 0) ...[
                  _buildMembershipDetailRow(
                    'Amount Due',
                    '₹${upcomingSub.dueAmount.toStringAsFixed(0)}',
                    Icons.pending_actions,
                    AppTheme.errorRed,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.successGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.successGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payment complete! Membership will be activated soon.',
                            style: TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (active != null) ...[
                Text(
                  '${visitor.name} has an active membership:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 16),

                _buildMembershipDetailRow(
                  'Membership Type',
                  (active.membershipType.isNotEmpty
                          ? active.membershipType
                          : 'N/A')
                      .toUpperCase(),
                  Icons.star,
                  AppTheme.successGreen,
                ),
                const SizedBox(height: 12),

                _buildMembershipDetailRow(
                  'Status',
                  (active.status.isNotEmpty ? active.status : 'active')
                      .toUpperCase(),
                  Icons.verified,
                  AppTheme.infoBlue,
                ),
                const SizedBox(height: 12),

                _buildMembershipDetailRow(
                  'Period',
                  '${_formatDate(active.startDate)} - ${_formatDate(active.endDate)}',
                  Icons.date_range,
                  AppTheme.darkGrey,
                ),
                const SizedBox(height: 12),

                _buildMembershipDetailRow(
                  'Total Amount',
                  '₹${active.totalPayable.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  AppTheme.infoBlue,
                ),
                const SizedBox(height: 12),

                _buildMembershipDetailRow(
                  'Amount Paid',
                  '₹${active.totalPaid.toStringAsFixed(0)}',
                  Icons.payment,
                  AppTheme.successGreen,
                ),
                const SizedBox(height: 12),

                if (active.dueAmount > 0) ...[
                  _buildMembershipDetailRow(
                    'Amount Due',
                    '₹${active.dueAmount.toStringAsFixed(0)}',
                    Icons.pending_actions,
                    AppTheme.errorRed,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.successGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.successGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No dues. Membership is active.',
                            style: TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  'Membership information is not available yet.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The user has a non-visitor membershipType, but detailed membership data is missing. Try refreshing the details.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkGrey.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkGrey.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Removed old _getReferralText; API provides referredByName when available.
}

// Reuse the same EditDetailsDialog
class _EditDetailsDialog extends StatefulWidget {
  final UserModel member;
  final Function(UserModel) onDetailsUpdated;

  const _EditDetailsDialog({
    required this.member,
    required this.onDetailsUpdated,
  });

  @override
  State<_EditDetailsDialog> createState() => _EditDetailsDialogState();
}

class _EditDetailsDialogState extends State<_EditDetailsDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.mobileNumber);
    _addressController = TextEditingController(text: widget.member.address);
    _notesController = TextEditingController(text: widget.member.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit, color: AppTheme.darkGrey),
          const SizedBox(width: 8),
          const Text('Edit Visitor Details'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  hintText: 'Health details, special requirements, etc.',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveDetails,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successGreen,
            foregroundColor: AppTheme.white,
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  void _saveDetails() {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name is required'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number is required'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Create updated member
    final updatedMember = widget.member.copyWith(
      name: _nameController.text.trim(),
      mobileNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    // Call the callback
    widget.onDetailsUpdated(updatedMember);

    // Close dialog
    Navigator.pop(context);
  }
}
