import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/data/models/subscription_plan.dart';
import 'package:magical_community/data/services/user_service.dart';

class SubscriptionDialogConfig {
  final String userName;
  final String actionType; // 'renewal', 'upgrade', 'trial', 'membership'
  final Color accentColor;
  final String titleText;
  final String descriptionText;
  final String buttonText;
  final Function(SubscriptionPlan plan, double amount, DateTime startDate)
  onConfirm;
  final bool includeStartDate;

  const SubscriptionDialogConfig({
    required this.userName,
    required this.actionType,
    required this.accentColor,
    required this.titleText,
    required this.descriptionText,
    required this.buttonText,
    required this.onConfirm,
    this.includeStartDate = true,
  });

  factory SubscriptionDialogConfig.renewal({
    required String userName,
    required Function(SubscriptionPlan plan, double amount, DateTime startDate)
    onConfirm,
  }) {
    return SubscriptionDialogConfig(
      userName: userName,
      actionType: 'renewal',
      accentColor: AppTheme.accentYellow,
      titleText: 'Renewal Plans',
      descriptionText: 'Select a membership plan to renew $userName:',
      buttonText: 'Renew',
      onConfirm: onConfirm,
      includeStartDate: true,
    );
  }

  factory SubscriptionDialogConfig.trialUpgrade({
    required String userName,
    required Function(SubscriptionPlan plan, double amount, DateTime startDate)
    onConfirm,
  }) {
    return SubscriptionDialogConfig(
      userName: userName,
      actionType: 'upgrade',
      accentColor: AppTheme.successGreen,
      titleText: 'Membership Plans',
      descriptionText: 'Select a membership plan for $userName:',
      buttonText: 'Submit',
      onConfirm: onConfirm,
      includeStartDate: true,
    );
  }

  factory SubscriptionDialogConfig.visitorUpgrade({
    required String userName,
    required Function(SubscriptionPlan plan, double amount, DateTime startDate)
    onConfirm,
  }) {
    return SubscriptionDialogConfig(
      userName: userName,
      actionType: 'membership',
      accentColor: AppTheme.successGreen,
      titleText: 'Membership Plans',
      descriptionText: 'Select a membership plan for $userName:',
      buttonText: 'Submit',
      onConfirm: onConfirm,
      includeStartDate: true,
    );
  }

  factory SubscriptionDialogConfig.trialStart({
    required String userName,
    required Function(SubscriptionPlan plan, double amount, DateTime startDate)
    onConfirm,
  }) {
    return SubscriptionDialogConfig(
      userName: userName,
      actionType: 'trial',
      accentColor: AppTheme.accentYellow,
      titleText: 'Membership Plans',
      descriptionText: 'Select a membership plan for $userName:',
      buttonText: 'Start Trial',
      onConfirm: onConfirm,
      includeStartDate: true,
    );
  }
}

class SubscriptionDialog extends StatefulWidget {
  final SubscriptionDialogConfig config;
  const SubscriptionDialog({super.key, required this.config});

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  final UserService _userService = UserService();
  List<SubscriptionPlan> _subscriptionPlans = [];
  bool _isLoadingPlans = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
  }

  Future<void> _loadSubscriptionPlans() async {
    setState(() => _isLoadingPlans = true);
    try {
      final result = await _userService.getSubscriptionPlans();
      result.when(
        success: (plans) {
          if (!mounted) return;
          // For trial upgrades, hide any Trial plan from selection
          final filtered = widget.config.actionType == 'upgrade'
              ? plans.where((p) => p.isTrial == false).toList()
              : plans;
          setState(() {
            _subscriptionPlans = filtered;
            _isLoadingPlans = false;
          });
        },
        failure: (message, statusCode) {
          if (!mounted) return;
          setState(() => _isLoadingPlans = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading membership plans: $message'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPlans = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading membership plans: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(_getIconForActionType(), color: widget.config.accentColor),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.config.titleText)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.config.descriptionText,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (_isLoadingPlans)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentYellow,
                    ),
                  ),
                ),
              )
            else if (_subscriptionPlans.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No membership plans available',
                  style: TextStyle(color: AppTheme.darkGrey, fontSize: 16),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    children: _subscriptionPlans.asMap().entries.map((entry) {
                      final index = entry.key;
                      final plan = entry.value;
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              // Use the root overlay context to host the next dialog
                              final overlayCtx = Overlay.of(
                                context,
                                rootOverlay: true,
                              ).context;

                              // Close the plans dialog first
                              Navigator.of(context, rootNavigator: true).pop();

                              // Schedule the confirm dialog for the next frame to avoid
                              // "Tried to build dirty widget in the wrong build scope"
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _showConfirmSubscriptionDialog(
                                  overlayCtx,
                                  plan,
                                );
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.config.accentColor.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.config.accentColor.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.workspace_premium,
                                    color: widget.config.accentColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          plan.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.darkGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        plan.displayPrice,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: widget.config.accentColor,
                                        ),
                                      ),
                                      Text(
                                        plan.displayDuration,
                                        style: const TextStyle(
                                          color: AppTheme.darkGrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: widget.config.accentColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (index < _subscriptionPlans.length - 1)
                            const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _showConfirmSubscriptionDialog(BuildContext ctx, SubscriptionPlan plan) {
    final formKey = GlobalKey<FormState>();
    // Default to 0 so zero-payment upgrades/renewals are explicit; user can change to any value up to plan.price
    final amountController = TextEditingController(text: '0');
    DateTime selectedStartDate = DateTime.now();
    bool isSubmitting = false;

    String _formatDate(DateTime date) {
      return '${date.day}/${date.month}/${date.year}';
    }

    final dialogFuture = showDialog(
      context: ctx,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(_getIconForActionType(), color: widget.config.accentColor),
              const SizedBox(width: 8),
              Text(_getConfirmationTitle()),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getConfirmationDescription(plan),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.config.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.config.accentColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: widget.config.accentColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                plan.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              plan.displayPrice,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: widget.config.accentColor,
                              ),
                            ),
                            Text(
                              plan.displayDuration,
                              style: const TextStyle(
                                color: AppTheme.darkGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        color: widget.config.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Payment Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount to Pay',
                      prefixIcon: Icon(
                        Icons.currency_rupee,
                        color: widget.config.accentColor,
                      ),
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.config.accentColor,
                          width: 2,
                        ),
                      ),
                      hintText: 'Enter payment amount',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        // Treat blank as 0 ONLY if plan allows zero? Force explicit 0 to avoid accidental.
                        return 'Enter amount (0 allowed)';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Amount must be 0 or more';
                      }
                      if (amount > plan.price) {
                        return 'Amount cannot exceed ${plan.displayPrice}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getPaymentDescription(),
                    style: TextStyle(fontSize: 14, color: AppTheme.darkGrey),
                  ),

                  // Start Date Selection
                  if (widget.config.includeStartDate) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: widget.config.accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: widget.config.accentColor,
                                  onPrimary:
                                      widget.config.accentColor ==
                                          AppTheme.accentYellow
                                      ? AppTheme.primaryBlack
                                      : AppTheme.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedStartDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.darkGrey.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: widget.config.accentColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _formatDate(selectedStartDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.primaryBlack,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppTheme.darkGrey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select when the subscription should start',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        final amount =
                            double.tryParse(amountController.text) ?? 0.0;
                        setState(() => isSubmitting = true);
                        try {
                          // Await the caller's async work; they handle messaging.
                          await Future.sync(
                            () => widget.config.onConfirm(
                              plan,
                              amount,
                              selectedStartDate,
                            ),
                          );
                        } finally {
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.config.accentColor,
                foregroundColor:
                    widget.config.accentColor == AppTheme.accentYellow
                    ? AppTheme.primaryBlack
                    : AppTheme.white,
              ),
              child: isSubmitting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppTheme.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Processing...'),
                      ],
                    )
                  : Text(widget.config.buttonText),
            ),
          ],
        ),
      ),
    );

    dialogFuture.whenComplete(() {
      // Dispose the controller on the next frame to avoid transient rebuilds
      // referencing a disposed controller during the route's pop animation.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          amountController.dispose();
        } catch (_) {}
      });
    });
  }

  IconData _getIconForActionType() {
    switch (widget.config.actionType) {
      case 'renewal':
        return Icons.refresh;
      case 'trial':
        return Icons.schedule;
      case 'upgrade':
      case 'membership':
        return Icons.upgrade;
      default:
        return Icons.workspace_premium;
    }
  }

  String _getConfirmationTitle() {
    switch (widget.config.actionType) {
      case 'renewal':
        return 'Renew Membership';
      case 'trial':
        return 'Start Trial';
      case 'upgrade':
      case 'membership':
        return 'Upgrade';
      default:
        return 'Membership';
    }
  }

  String _getConfirmationDescription(SubscriptionPlan plan) {
    switch (widget.config.actionType) {
      case 'renewal':
        return 'Renew ${widget.config.userName} with:';
      case 'trial':
        return 'Start trial for ${widget.config.userName} with:';
      case 'upgrade':
      case 'membership':
        return 'Upgrade ${widget.config.userName} to:';
      default:
        return 'Upgrade ${widget.config.userName} with:';
    }
  }

  String _getPaymentDescription() {
    switch (widget.config.actionType) {
      case 'renewal':
        return 'Enter the amount to be paid for this membership renewal.';
      case 'trial':
        return 'Enter the amount to be paid for this trial membership.';
      case 'upgrade':
      case 'membership':
        return 'Enter the amount to be paid for this membership.';
      default:
        return 'Enter the amount to be paid for this membership.';
    }
  }
}
