import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:magical_community/core/error/error_handler.dart';
import 'package:magical_community/core/services/api_service.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/models/payment_model.dart';

class IncomeDetailScreen extends StatefulWidget {
  final PaymentModel income;
  const IncomeDetailScreen({super.key, required this.income});

  @override
  State<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends State<IncomeDetailScreen> {
  late PaymentModel _income;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _income = widget.income;
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
          title: const Text('Income Details'),
          backgroundColor: AppTheme.primaryBlack,
          foregroundColor: AppTheme.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated = await _showEditIncomeDialog(context, _income);
                if (updated != null && mounted) {
                  setState(() {
                    _income = updated;
                    _changed = true;
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
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
                          AppTheme.successGreen.withOpacity(0.1),
                          AppTheme.accentYellow.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.successGreen,
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: AppTheme.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _income.type == PaymentType.membership
                              ? 'Membership Payment'
                              : _income.type == PaymentType.trial
                              ? 'Trial Payment'
                              : 'Other Income',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${_income.amount.toInt()}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().slide(begin: const Offset(0, -0.3), duration: 500.ms),

              // Details
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
                          'Income Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _row(
                          'Date',
                          DateFormat('dd/MM/yyyy').format(_income.date),
                          Icons.calendar_today,
                        ),
                        const SizedBox(height: 16),
                        if (_income.type == PaymentType.expense &&
                            _income.description != null) ...[
                          _row('Title', _income.description!, Icons.title),
                          const SizedBox(height: 16),
                        ],
                        if (_income.linkedUserName != null &&
                            _income.type != PaymentType.expense) ...[
                          _row('User', _income.linkedUserName!, Icons.person),
                          const SizedBox(height: 16),
                        ],
                        _row(
                          'Amount',
                          '₹${_income.amount.toInt()}',
                          Icons.currency_rupee,
                        ),
                        const SizedBox(height: 16),
                        _row(
                          'Payment Method',
                          _getPaymentModeText(_income.mode ?? PaymentMode.cash),
                          Icons.payment,
                        ),
                        // const SizedBox(height: 16),
                        // if (_income.id.isNotEmpty)
                        //   _row('ID', _income.id, Icons.tag, isMono: true),
                      ],
                    ),
                  ),
                ),
              ).animate().slide(
                begin: const Offset(0, 0.3),
                duration: 500.ms,
                delay: 200.ms,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    IconData icon, {
    bool isMono = false,
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
                  fontFamily: isMono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPaymentModeText(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.online:
        return 'Online';
    }
  }

  Future<PaymentModel?> _showEditIncomeDialog(
    BuildContext context,
    PaymentModel income,
  ) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(
      text: income.amount.toInt().toString(),
    );
    final titleCtrl = TextEditingController(
      text: income.type == PaymentType.expense
          ? (income.description ?? 'Other Income')
          : 'UMS',
    );
    final userName = income.linkedUserName;
    DateTime date = income.date;
    PaymentMode paymentMode = income.mode ?? PaymentMode.cash;
    bool isSubmitting = false;
    final isOthersType = income.type == PaymentType.expense;

    final result = await showDialog<PaymentModel?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Income'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (userName != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'User: $userName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isOthersType) ...[
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Enter a valid title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
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
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
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
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PaymentMode>(
                    value: paymentMode,
                    items: const [
                      DropdownMenuItem(
                        value: PaymentMode.cash,
                        child: Text('Cash'),
                      ),
                      DropdownMenuItem(
                        value: PaymentMode.online,
                        child: Text('Online'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => paymentMode = v ?? PaymentMode.cash),
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

                      final paymentModeString = paymentMode == PaymentMode.cash
                          ? 'cash'
                          : 'online';

                      final payload = {
                        'title': isOthersType ? titleCtrl.text.trim() : 'UMS',
                        'amount':
                            double.tryParse(amountCtrl.text.trim())?.toInt() ??
                            income.amount.toInt(),
                        'incomeType': isOthersType ? 'other' : 'membership',
                        'paymentDate':
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                        'paymentMethod': paymentModeString,
                        if (income.userId != null && income.userId!.isNotEmpty)
                          'userId': income.userId,
                      };
                      final res = await ApiService.put(
                        '/income/${income.id}',
                        data: payload,
                        context: context,
                        successMessage: 'Income entry updated successfully',
                      );
                      if (res != null && res['success'] == true) {
                        final map = res['data'] as Map<String, dynamic>;
                        final updated = income.copyWith(
                          amount:
                              (map['amount'] as num?)?.toDouble() ??
                              income.amount,
                          date:
                              DateTime.tryParse(
                                map['paymentDate']?.toString() ?? '',
                              ) ??
                              date,
                          mode: paymentMode,
                          description: isOthersType
                              ? titleCtrl.text.trim()
                              : income.description,
                          linkedUserName:
                              map['userName']?.toString() ??
                              income.linkedUserName,
                        );
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

  void _confirmDelete() {
    final pageContext = context;
    showDialog(
      context: pageContext,
      builder: (dCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text('Delete Income'),
          ],
        ),
        content: Text('Are you sure you want to delete this income entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.white,
            ),
            onPressed: () async {
              Navigator.of(dCtx).pop();
              _showLoadingDialog(pageContext, 'Deleting income...');
              final ok = await _deleteIncome(_income.id);
              if (mounted) {
                Navigator.of(pageContext, rootNavigator: true).pop();
              }
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

  Future<bool> _deleteIncome(String id) async {
    try {
      final res = await ApiService.delete('/income/$id', context: context);
      return res != null && res['success'] == true;
    } catch (e) {
      ErrorHandler.handleError(context, e);
      return false;
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: const [
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Please wait...')),
          ],
        ),
      ),
    );
  }
}
