import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/core/services/api_service.dart';
import 'package:magical_community/core/error/error_handler.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.maintenance;
  DateTime _expenseDate = DateTime.now();
  String _paymentMethod = 'cash'; // 'cash' | 'online'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
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
                            AppTheme.errorRed.withOpacity(0.1),
                            AppTheme.errorRed.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              size: 40,
                              color: AppTheme.errorRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Add New Expense',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Record and track your club expenses',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkGrey.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slide(begin: const Offset(0, -0.2)),

              const SizedBox(height: 28),

              // Expense Title Section
              Text(
                'Expense Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlack,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),

              // Expense Title
              _buildAnimatedTextField(
                controller: _titleController,
                label: 'Expense Title',
                icon: Icons.title,
                delay: 200,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter expense title';
                  }
                  if (value.length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Amount and Date Row
              Row(
                children: [
                  // Amount
                  Expanded(
                    flex: 2,
                    child: _buildAnimatedTextField(
                      controller: _amountController,
                      label: 'Amount (₹)',
                      icon: Icons.currency_rupee,
                      delay: 300,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Please enter valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Date Selection
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _expenseDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppTheme.errorRed,
                                        onPrimary: AppTheme.white,
                                        surface: AppTheme.white,
                                        onSurface: AppTheme.primaryBlack,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() {
                                  _expenseDate = date;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppTheme.errorRed,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDateShort(_expenseDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlack,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().slide(
                          begin: const Offset(1, 0),
                          delay: 300.ms,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Payment Method
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlack,
                ),
              ).animate().fadeIn(delay: 380.ms),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.payment, color: AppTheme.errorRed),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'online', child: Text('Online')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value ?? 'cash';
                      });
                    },
                  ),
                ),
              ).animate().slide(begin: const Offset(1, 0), delay: 380.ms),

              const SizedBox(height: 16),

              // Category Selection
              Text(
                'Expense Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlack,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 8),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<ExpenseCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.category,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    items: ExpenseCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              _getExpenseCategoryIcon(category),
                              color: _getExpenseCategoryColor(category),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(_getExpenseCategoryText(category)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ).animate().slide(begin: const Offset(1, 0), delay: 400.ms),

              const SizedBox(height: 16),

              // Description
              _buildAnimatedTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                icon: Icons.description,
                delay: 600,
                maxLines: 3,
                validator: null, // Made optional
              ),

              const SizedBox(height: 32),

              // Save Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.errorRed,
                      AppTheme.errorRed.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.errorRed.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppTheme.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.white,
                          ),
                        )
                      else
                        const Icon(Icons.save_alt, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        _isSubmitting ? 'Saving...' : 'Save Expense',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(delay: 700.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int delay,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: AppTheme.errorRed),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppTheme.white,
          ),
        ),
      ),
    ).animate().slide(begin: const Offset(-1, 0), delay: delay.ms);
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day}\n${months[date.month - 1]}';
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final formattedDate =
        '${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}';

    final payload = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? _titleController.text.trim()
          : _descriptionController.text.trim(),
      'amount': double.tryParse(_amountController.text.trim())?.toInt() ?? 0,
      'paymentMethod': _paymentMethod, // 'cash' or 'online'
      'expenseDate': formattedDate,
    };

    try {
      final res = await ApiService.post(
        '/expenses',
        data: payload,
        context: context,
        showSuccessMessage: true,
      );
      if (res != null && res['success'] == true) {
        if (mounted) Navigator.pop(context, true); // signal list to refresh
      }
    } catch (e) {
      // Centralized error handling
      await ErrorHandler.handleError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

enum ExpenseCategory { maintenance, electricity, rent, other }
