import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/core/services/api_service.dart';
import 'package:magical_community/screens/accounts/accounts_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late ExpenseModel _expense;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: AppBar(
          title: const Text('Expense Details'),
          backgroundColor: AppTheme.primaryBlack,
          foregroundColor: AppTheme.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated = await _showEditExpenseDialog(context, _expense);
                if (updated != null && mounted) {
                  setState(() {
                    _expense = updated;
                    _changed = true;
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Card with Amount
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.errorRed.withOpacity(0.1),
                          AppTheme.errorRed.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: _getExpenseCategoryColor(
                            _expense.category,
                          ),
                          child: Icon(
                            _getExpenseCategoryIcon(_expense.category),
                            color: AppTheme.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _expense.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${_expense.amount.toInt()}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorRed,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getExpenseCategoryColor(
                              _expense.category,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getExpenseCategoryText(_expense.category),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getExpenseCategoryColor(
                                _expense.category,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().slide(begin: const Offset(0, -0.3), duration: 500.ms),

              // Details Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expense Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description
                        _buildDetailRow(
                          'Description',
                          _expense.description,
                          Icons.description,
                        ),

                        const SizedBox(height: 16),

                        // Expense Date
                        _buildDetailRow(
                          'Expense Date',
                          _formatDate(_expense.expenseDate),
                          Icons.calendar_today,
                        ),

                        const SizedBox(height: 16),

                        // Payment Method (from API)
                        if (_expense.paymentMethod != null)
                          _buildDetailRow(
                            'Payment Method',
                            _getPaymentMethodText(_expense.paymentMethod!),
                            Icons.payment,
                          ),

                        if (_expense.paymentMethod != null)
                          const SizedBox(height: 16),

                        // Created By (from API)
                        if (_expense.createdByName != null)
                          _buildDetailRow(
                            'Added By',
                            _expense.createdByName!,
                            Icons.person,
                          ),

                        if (_expense.createdByName != null)
                          const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ).animate().slide(
                begin: const Offset(0, 0.3),
                duration: 500.ms,
                delay: 200.ms,
              ),

              // Statistics Section (Static for now)
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isMonospace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlack.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryBlack),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkGrey.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryBlack,
                  fontWeight: FontWeight.w600,
                  fontFamily: isMonospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // _buildStatCard removed as it's not referenced in current UI.

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // _formatDateTime removed as it's currently unused.

  String _mapPaymentMethodForEdit(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'cash';
      case 'online':
      case 'upi':
      case 'card':
      case 'netbanking':
        return 'online';
      default:
        return 'cash';
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'online':
      case 'upi':
      case 'card':
        return 'Online';
      case 'netbanking':
        return 'Net Banking';
      default:
        return method.toUpperCase();
    }
  }

  String _getExpenseCategoryText(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.electricity:
        return 'Electricity';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  Color _getExpenseCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return AppTheme.accentYellow;
      case ExpenseCategory.electricity:
        return Colors.blue;
      case ExpenseCategory.rent:
        return AppTheme.errorRed;
      case ExpenseCategory.other:
        return AppTheme.darkGrey;
    }
  }

  IconData _getExpenseCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return Icons.build;
      case ExpenseCategory.electricity:
        return Icons.electrical_services;
      case ExpenseCategory.rent:
        return Icons.home;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    // Use the page-level context to manage dialogs/navigation reliably
    final pageContext = this.context;
    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text('Delete Expense'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_expense.title}"? This action cannot be undone.',
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
              // Close the confirmation dialog first
              Navigator.of(dialogContext).pop();
              // Show blocking progress while deleting
              _showLoadingDialog(pageContext, 'Deleting expense...');
              final ok = await _deleteExpense(pageContext, _expense.id);
              // Close loading dialog
              if (mounted) {
                // Pop the loading dialog
                Navigator.of(pageContext, rootNavigator: true).pop();
              }
              // If success, pop the detail screen and notify parent to refresh
              if (ok && mounted) {
                Navigator.of(pageContext).pop(true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool> _deleteExpense(BuildContext context, String id) async {
    try {
      final res = await ApiService.delete('/expenses/$id', context: context);
      if (res != null && res['success'] == true) {
        // Success message handled globally; optionally show here
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<ExpenseModel?> _showEditExpenseDialog(
    BuildContext context,
    ExpenseModel expense,
  ) async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: expense.title);
    final amountCtrl = TextEditingController(
      text: expense.amount.toInt().toString(),
    );
    final descCtrl = TextEditingController(text: expense.description);
    DateTime date = expense.expenseDate;
    String paymentMethod = _mapPaymentMethodForEdit(
      expense.paymentMethod ?? 'cash',
    );
    bool isSubmitting = false;

    final result = await showDialog<ExpenseModel?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Expense'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Enter a valid title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null || d <= 0) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Date: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => date = picked);
                        },
                        child: Text(
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'online', child: Text('Online')),
                    ],
                    onChanged: (v) =>
                        setState(() => paymentMethod = v ?? 'cash'),
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                    ),
                  ),
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
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isSubmitting = true);
                      final payload = {
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'amount':
                            double.tryParse(amountCtrl.text.trim())?.toInt() ??
                            expense.amount.toInt(),
                        'expenseDate':
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                        'paymentMethod': paymentMethod,
                      };
                      final res = await ApiService.put(
                        '/expenses/${expense.id}',
                        data: payload,
                        context: context,
                        successMessage: 'Expense updated successfully',
                      );
                      if (res != null && res['success'] == true) {
                        final data = res['data'] as Map<String, dynamic>;
                        final updated = ExpenseModel.fromJson(data);
                        if (context.mounted) Navigator.pop(context, updated);
                      } else {
                        if (context.mounted)
                          setState(() => isSubmitting = false);
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  // _updateExpense helper removed; inline PUT used in dialog submit

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
