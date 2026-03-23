import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/models/payment_model.dart';
import 'package:magical_community/models/user_model.dart';
import 'package:magical_community/core/services/api_service.dart';
import 'package:magical_community/core/error/error_handler.dart';
import 'package:magical_community/screens/accounts/expense_detail_screen.dart';
import 'package:magical_community/screens/accounts/income_detail_screen.dart';
import 'package:magical_community/data/services/auth_service.dart';
import 'package:magical_community/data/services/user_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;

  // Sample data - will be replaced with Hive database queries
  final List<PaymentModel> _incomeList = [];
  final List<ExpenseModel> _expensesList = [];
  final List<UserModel> _users = []; // Users for linking income

  // Loading states
  bool _isLoadingExpenses = true;
  bool _hasExpenseError = false;
  bool _isLoadingMoreExpenses = false;
  bool _hasMoreExpenses = true;
  int _expensesPage = 1;
  final int _expensesLimit = 20;
  String? _expensesErrorMessage;
  bool _isRefreshingExpenses = false;
  // Income loading state
  bool _isLoadingIncome = true;
  bool _isLoadingMoreIncome = false;
  int _incomePage = 1;
  final int _incomeLimit = 20;
  bool _hasMoreIncome = true;

  // Track which list items have already animated to avoid re-animating on scroll
  final Set<String> _animatedIncomeItems = {};
  final Set<String> _animatedExpenseItems = {};

  // Filter state
  DateTime _selectedExpenseMonth = DateTime.now();
  bool _isExpenseFilterEnabled = false;
  // Income filter state
  DateTime _selectedIncomeMonth = DateTime.now();
  bool _isIncomeFilterEnabled = false;

  // New filter states for date/month selection
  DateTime? _selectedIncomeDate;
  DateTime? _selectedExpenseDate;
  bool _isIncomeFilterByDate = false;
  bool _isExpenseFilterByDate = false;

  // Loading state for filter changes
  bool _isFilterLoading = false;

  double get totalIncome =>
      _incomeList.fold(0, (sum, payment) => sum + payment.amount);
  double get totalExpenses =>
      _expensesList.fold(0, (sum, expense) => sum + expense.amount);

  // Get total of filtered expenses (used for display)
  double get filteredExpensesTotal {
    final filteredExpenses = _getFilteredExpenses();
    return filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  double get netBalance => totalIncome - totalExpenses;

  // Get total of filtered income (used for display)
  double get filteredIncomeTotal {
    final filteredIncome = _getFilteredIncome();
    return filteredIncome.fold(0, (sum, inc) => sum + inc.amount);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSampleData();

    // Default both tabs to current month
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, 1);
    final end = DateTime(today.year, today.month + 1, 0);

    setState(() {
      // Income -> month mode
      _isIncomeFilterByDate = false;
      _isIncomeFilterEnabled = true;
      _selectedIncomeMonth = DateTime(today.year, today.month, 1);
      _selectedIncomeDate = null;

      // Expenses -> month mode
      _isExpenseFilterByDate = false;
      _isExpenseFilterEnabled = true;
      _selectedExpenseMonth = DateTime(today.year, today.month, 1);
      _selectedExpenseDate = null;
    });

    _fetchIncome(page: 1, reset: true, startDate: start, endDate: end);
    _fetchExpenses(page: 1, reset: true, startDate: start, endDate: end);
  }

  // Fetch income from API
  Future<void> _fetchIncome({
    int page = 1,
    bool reset = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (mounted) {
        setState(() {
          if (reset || page == 1) {
            _isLoadingIncome = true;
          } else {
            _isLoadingMoreIncome = true;
          }
        });
      }

      // Build query parameters
      String query =
          '/income?page=' +
          page.toString() +
          '&limit=' +
          _incomeLimit.toString();
      if (startDate != null) {
        final formattedStartDate =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        query += '&startDate=' + formattedStartDate;
      }
      if (endDate != null) {
        final formattedEndDate =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        query += '&endDate=' + formattedEndDate;
      }

      final responseData = await ApiService.get(
        query,
        context: context,
        showSuccessMessage: false,
      );
      if (responseData != null && responseData['success'] == true) {
        final list = (responseData['data']?['data'] as List?) ?? const [];
        final fetched = list.map((json) {
          final map = json as Map<String, dynamic>;
          // Map API income item to PaymentModel used by UI
          final String incomeType = (map['incomeType'] ?? 'membership')
              .toString();
          final PaymentType type = incomeType.toLowerCase() == 'other'
              ? PaymentType.expense
              : PaymentType
                    .membership; // backend uses 'membership' even for trials
          return PaymentModel(
            id: map['id']?.toString() ?? '',
            amount: (map['amount'] as num?)?.toDouble() ?? 0,
            userId: map['userId']?.toString(),
            linkedUserName: map['userName']?.toString(),
            date:
                DateTime.tryParse(map['paymentDate']?.toString() ?? '') ??
                DateTime.now(),
            type: type,
            mode: null, // mode not provided by API
            description: map['title']?.toString(), // Capture title from API
            isIncome: true,
            createdAt:
                DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
                DateTime.now(),
          );
        }).toList();

        // Ensure unique items by id to avoid duplicates if API triggered multiple times
        List<PaymentModel> _uniqueById(List<PaymentModel> items) {
          final seen = <String>{};
          return items.where((p) => seen.add(p.id)).toList();
        }

        final fetchedUnique = _uniqueById(fetched);

        if (!mounted) return;
        setState(() {
          if (reset || page == 1) {
            _incomeList
              ..clear()
              ..addAll(fetchedUnique);
          } else {
            final merged = [..._incomeList, ...fetchedUnique];
            final uniqueMerged = _uniqueById(merged);
            _incomeList
              ..clear()
              ..addAll(uniqueMerged);
          }
          _incomeList.sort((a, b) => b.date.compareTo(a.date));
          _incomePage = page;
          _hasMoreIncome = fetchedUnique.length >= _incomeLimit;
          _isLoadingIncome = false;
          _isLoadingMoreIncome = false;
        });
      }
    } catch (_) {
      // Errors handled globally by ApiService
      if (mounted) {
        setState(() {
          _isLoadingIncome = false;
          _isLoadingMoreIncome = false;
        });
      } else {
        _isLoadingIncome = false;
        _isLoadingMoreIncome = false;
      }
    }
  }

  // Fetch expenses from API
  Future<void> _fetchExpenses({
    int page = 1,
    bool reset = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      setState(() {
        if (reset || page == 1) {
          _isLoadingExpenses = true;
          _hasExpenseError = false;
        } else {
          _isLoadingMoreExpenses = true;
        }
      });

      // Build query parameters
      String query =
          '/expenses?page=' +
          page.toString() +
          '&limit=' +
          _expensesLimit.toString();
      if (startDate != null) {
        final formattedStartDate =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        query += '&startDate=' + formattedStartDate;
      }
      if (endDate != null) {
        final formattedEndDate =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        query += '&endDate=' + formattedEndDate;
      }

      final responseData = await ApiService.get(
        query,
        context: context,
        showSuccessMessage:
            false, // Don't show success message for data fetching
      );

      if (responseData != null && responseData['success'] == true) {
        if (!mounted) return; // Guard against setState after dispose
        final expensesData =
            (responseData['data']?['data'] as List?) ?? const [];
        final fetched = expensesData
            .map((json) => ExpenseModel.fromJson(json))
            .toList();

        setState(() {
          if (reset || page == 1) {
            _expensesList
              ..clear()
              ..addAll(fetched);
          } else {
            _expensesList.addAll(fetched);
          }
          _expensesList.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
          _isLoadingExpenses = false;
          _isLoadingMoreExpenses = false;
          _expensesPage = page;
          _hasMoreExpenses = fetched.length >= _expensesLimit;
          _expensesErrorMessage = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingExpenses = false;
          _isLoadingMoreExpenses = false;
          _hasExpenseError = true;
          _expensesErrorMessage = error.toString();
        });
      }

      // Error handling is already managed by ApiService and ErrorHandler
      print('Error fetching expenses: $error');
    }
  }

  Future<void> _refreshExpenses() async {
    _expensesPage = 1;
    _hasMoreExpenses = true;
    _isRefreshingExpenses = true;
    try {
      // Maintain current filter when refreshing
      DateTime? startDate;
      DateTime? endDate;

      if (_isExpenseFilterByDate && _selectedExpenseDate != null) {
        startDate = _selectedExpenseDate;
      } else if (_isExpenseFilterEnabled) {
        startDate = DateTime(
          _selectedExpenseMonth.year,
          _selectedExpenseMonth.month,
          1,
        );
        endDate = DateTime(
          _selectedExpenseMonth.year,
          _selectedExpenseMonth.month + 1,
          0,
        );
      }

      await _fetchExpenses(
        page: 1,
        reset: true,
        startDate: startDate,
        endDate: endDate,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingExpenses = false;
        });
      } else {
        _isRefreshingExpenses = false;
      }
    }
  }

  // Show filter options bottom sheet
  void _showFilterOptions() {
    final isIncomeTab = _tabController.index == 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: isIncomeTab
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filter ${isIncomeTab ? 'Income' : 'Expenses'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter options
            ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: isIncomeTab ? AppTheme.successGreen : AppTheme.errorRed,
              ),
              title: const Text('Select Date'),
              subtitle: const Text('Filter by specific date'),
              onTap: () {
                Navigator.pop(context);
                _showDatePicker(isIncomeTab);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.calendar_month,
                color: isIncomeTab ? AppTheme.successGreen : AppTheme.errorRed,
              ),
              title: const Text('Select Month'),
              subtitle: const Text('Filter by entire month'),
              onTap: () {
                Navigator.pop(context);
                _showMonthPicker(isIncomeTab);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.clear, color: AppTheme.darkGrey),
              title: const Text('Clear Filter'),
              subtitle: const Text('Show current month'),
              onTap: () {
                Navigator.pop(context);
                _clearFilter(isIncomeTab);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Show date picker for specific date filtering
  void _showDatePicker(bool isIncomeTab) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isIncomeTab ? AppTheme.successGreen : AppTheme.errorRed,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Show loading indicator
      setState(() {
        _isFilterLoading = true;
        if (isIncomeTab) {
          _selectedIncomeDate = picked;
          _isIncomeFilterByDate = true;
          _isIncomeFilterEnabled = false; // Disable month filter
        } else {
          _selectedExpenseDate = picked;
          _isExpenseFilterByDate = true;
          _isExpenseFilterEnabled = false; // Disable month filter
        }
      });

      // Fetch data with date filter
      try {
        if (isIncomeTab) {
          await _fetchIncome(page: 1, reset: true, startDate: picked);
        } else {
          await _fetchExpenses(page: 1, reset: true, startDate: picked);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isFilterLoading = false;
          });
        }
      }
    }
  } // Show month picker for month filtering

  void _showMonthPicker(bool isIncomeTab) {
    // Local state for the dialog
    DateTime localSelectedMonth = isIncomeTab
        ? _selectedIncomeMonth
        : _selectedExpenseMonth;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: isIncomeTab ? AppTheme.successGreen : AppTheme.errorRed,
              ),
              const SizedBox(width: 8),
              const Text('Select Month'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year selector
                DropdownButton<int>(
                  value: localSelectedMonth.year,
                  items: List.generate(6, (index) {
                    final year = DateTime.now().year - index;
                    return DropdownMenuItem(value: year, child: Text('$year'));
                  }),
                  onChanged: (year) {
                    if (year != null) {
                      setDialogState(() {
                        localSelectedMonth = DateTime(
                          year,
                          localSelectedMonth.month,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Month grid
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final monthName = DateFormat.MMM().format(
                        DateTime(2025, month),
                      );
                      final isSelected = localSelectedMonth.month == month;

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            localSelectedMonth = DateTime(
                              localSelectedMonth.year,
                              month,
                            );
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isIncomeTab
                                      ? AppTheme.successGreen
                                      : AppTheme.errorRed)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              monthName,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.primaryBlack,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                // Update main screen state with selected month
                setState(() {
                  if (isIncomeTab) {
                    _selectedIncomeMonth = localSelectedMonth;
                    _isIncomeFilterEnabled = true;
                    _isIncomeFilterByDate = false; // Disable date filter
                  } else {
                    _selectedExpenseMonth = localSelectedMonth;
                    _isExpenseFilterEnabled = true;
                    _isExpenseFilterByDate = false; // Disable date filter
                  }
                  _isFilterLoading = true;
                });

                try {
                  // Calculate start and end date for the selected month
                  final startDate = DateTime(
                    localSelectedMonth.year,
                    localSelectedMonth.month,
                    1,
                  );
                  final endDate = DateTime(
                    localSelectedMonth.year,
                    localSelectedMonth.month + 1,
                    0,
                  );

                  // Fetch data with month filter
                  if (isIncomeTab) {
                    await _fetchIncome(
                      page: 1,
                      reset: true,
                      startDate: startDate,
                      endDate: endDate,
                    );
                  } else {
                    await _fetchExpenses(
                      page: 1,
                      reset: true,
                      startDate: startDate,
                      endDate: endDate,
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isFilterLoading = false;
                    });
                  }
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  // Clear all filters and set today's date as default
  void _clearFilter(bool isIncomeTab) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, 1);
    final end = DateTime(today.year, today.month + 1, 0);

    setState(() {
      if (isIncomeTab) {
        // Reset to current month for income
        _isIncomeFilterEnabled = true;
        _isIncomeFilterByDate = false;
        _selectedIncomeMonth = DateTime(today.year, today.month, 1);
        _selectedIncomeDate = null;
      } else {
        // Reset to current month for expenses
        _isExpenseFilterEnabled = true;
        _isExpenseFilterByDate = false;
        _selectedExpenseMonth = DateTime(today.year, today.month, 1);
        _selectedExpenseDate = null;
      }
    });

    // Fetch current month's data
    if (isIncomeTab) {
      await _fetchIncome(page: 1, reset: true, startDate: start, endDate: end);
    } else {
      await _fetchExpenses(
        page: 1,
        reset: true,
        startDate: start,
        endDate: end,
      );
    }
  }

  // Filter income by selected month (only if filter is enabled)
  List<PaymentModel> _getFilteredIncome() {
    if (!_isIncomeFilterEnabled && !_isIncomeFilterByDate) {
      return _incomeList;
    }

    if (_isIncomeFilterByDate && _selectedIncomeDate != null) {
      // Filter by specific date
      return _incomeList
          .where(
            (inc) =>
                inc.date.year == _selectedIncomeDate!.year &&
                inc.date.month == _selectedIncomeDate!.month &&
                inc.date.day == _selectedIncomeDate!.day,
          )
          .toList();
    }

    if (_isIncomeFilterEnabled) {
      // Filter by month
      return _incomeList
          .where(
            (inc) =>
                inc.date.year == _selectedIncomeMonth.year &&
                inc.date.month == _selectedIncomeMonth.month,
          )
          .toList();
    }

    return _incomeList;
  }

  // Filter expenses by selected month (only if filter is enabled)
  List<ExpenseModel> _getFilteredExpenses() {
    if (!_isExpenseFilterEnabled && !_isExpenseFilterByDate) {
      return _expensesList; // Return all expenses when filter is disabled
    }

    if (_isExpenseFilterByDate && _selectedExpenseDate != null) {
      // Filter by specific date
      return _expensesList
          .where(
            (expense) =>
                expense.expenseDate.year == _selectedExpenseDate!.year &&
                expense.expenseDate.month == _selectedExpenseDate!.month &&
                expense.expenseDate.day == _selectedExpenseDate!.day,
          )
          .toList();
    }

    if (_isExpenseFilterEnabled) {
      // Filter by month
      return _expensesList
          .where(
            (expense) =>
                expense.expenseDate.year == _selectedExpenseMonth.year &&
                expense.expenseDate.month == _selectedExpenseMonth.month,
          )
          .toList();
    }

    return _expensesList;
  }

  // Method to fetch UMS or Trial users based on type
  Future<List<Map<String, dynamic>>> _fetchFilteredUsers(
    String query,
    IncomeType incomeType,
  ) async {
    try {
      String membershipType;
      switch (incomeType) {
        case IncomeType.ums:
          membershipType = 'membership';
          break;
        case IncomeType.trial:
          membershipType = 'trial';
          break;
        case IncomeType.others:
          // For others, use existing general user search
          final userService = UserService();
          final filterResult = await userService.filterUsers(
            search: query.trim(),
            page: 1,
            limit: 20,
            activeOnly: false,
          );
          return filterResult.when(
            success: (list) => list,
            failure: (message, statusCode) => [],
          );
      }

      // Maintain required parameter order:
      // page, limit, search (if present), membershipTypes, activeOnly, ignoreClubFilter
      // Base URL already includes /api/rest, so we only append /club/... here
      final base = '/club/users/filter?page=1&limit=20';
      final searchPart = query.isNotEmpty
          ? '&search=${Uri.encodeQueryComponent(query)}'
          : '';
      final finalUrl =
          '$base$searchPart&membershipTypes=$membershipType&activeOnly=true&ignoreClubFilter=false';

      final responseData = await ApiService.get(
        finalUrl,
        context: context,
        showSuccessMessage: false,
      );

      if (responseData != null && responseData['success'] == true) {
        final users = (responseData['data']?['data'] as List?) ?? [];
        return users.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching filtered users: $e');
      return [];
    }
  }

  // Beautiful Add Income Bottom Sheet with Live Search
  void _showAddIncomeBottomSheet() {
    final _formKey = GlobalKey<FormState>();
    IncomeType _selectedIncomeType = IncomeType.ums; // Default to UMS
    PaymentMode _selectedMode = PaymentMode.cash;
    final _amountController = TextEditingController();
    final _incomeTitleController = TextEditingController();
    DateTime _selectedDate = DateTime.now();
    bool _isSubmitting = false;

    // Live search state
    final TextEditingController _userSearchController = TextEditingController();
    Timer? _userSearchDebounce;
    bool _isSearchingUsers = false;
    String _lastUserQuery = '';
    List<Map<String, dynamic>> _userSuggestions = [];
    Map<String, dynamic>? _selectedUserMap;

    void triggerSearch(StateSetter setSheetState, String query) {
      _lastUserQuery = query;
      _userSearchDebounce?.cancel();
      if (query.trim().length < 3) {
        setSheetState(() {
          _isSearchingUsers = false;
          _userSuggestions = [];
        });
        return;
      }
      _userSearchDebounce = Timer(const Duration(milliseconds: 400), () async {
        setSheetState(() => _isSearchingUsers = true);
        try {
          // Use the new unified method for all income types
          final result = await _fetchFilteredUsers(
            query.trim(),
            _selectedIncomeType,
          );

          if (!mounted) return;
          if (query.trim() != _lastUserQuery) return;

          setSheetState(() {
            _userSuggestions = result;
            _isSearchingUsers = false;
          });
        } catch (e) {
          if (!mounted) return;
          setSheetState(() => _isSearchingUsers = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Search failed: ' + e.toString()),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final viewInsets = MediaQuery.of(context).viewInsets.bottom;
            return AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: viewInsets),
              child: SafeArea(
                top: false,
                child: DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.85,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (ctx, controller) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          controller: controller,
                          padding: const EdgeInsets.all(0),
                          children: [
                            // Header with drag handle and title
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                16,
                                24,
                                20,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.successGreen.withOpacity(0.1),
                                    AppTheme.successGreen.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 6,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreen.withOpacity(
                                        0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.successGreen
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Add Income',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryBlack,
                                              ),
                                            ),
                                            Text(
                                              'Record new income entry',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Form content
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Income Type Section
                                  _buildSectionTitle(
                                    'Income Type',
                                    Icons.category_rounded,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStyledDropdown<IncomeType>(
                                    value: _selectedIncomeType,
                                    icon: Icons.category_rounded,
                                    color: AppTheme.successGreen,
                                    items: [
                                      DropdownMenuItem(
                                        value: IncomeType.ums,
                                        child: Text(
                                          'UMS',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: IncomeType.trial,
                                        child: Text(
                                          'Trial',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: IncomeType.others,
                                        child: Text(
                                          'Others',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setSheetState(() {
                                        _selectedIncomeType = value!;
                                        _selectedUserMap = null;
                                        _userSearchController.clear();
                                        _userSuggestions = [];
                                        _incomeTitleController.clear();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // For 'Others' income type, show a Title input
                                  if (_selectedIncomeType ==
                                      IncomeType.others) ...[
                                    _buildSectionTitle(
                                      'Income Title',
                                      Icons.title_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStyledTextField(
                                      controller: _incomeTitleController,
                                      hintText:
                                          'Enter income title (e.g., Sponsorship, Sale)',
                                      icon: Icons.title_rounded,
                                      color: AppTheme.primaryBlack,
                                      validator: (v) {
                                        if (_selectedIncomeType ==
                                            IncomeType.others) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Please enter income title';
                                          }
                                          if (v.trim().length < 3) {
                                            return 'Title must be at least 3 characters';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  if (_selectedIncomeType == IncomeType.ums ||
                                      _selectedIncomeType ==
                                          IncomeType.trial) ...[
                                    _buildSectionTitle(
                                      'Select User',
                                      Icons.person_search_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStyledTextField(
                                      controller: _userSearchController,
                                      hintText: 'Enter name',
                                      icon: Icons.person_search_rounded,
                                      color: AppTheme.infoBlue,
                                      onChanged: (v) {
                                        _selectedUserMap = null;
                                        triggerSearch(setSheetState, v);
                                      },
                                      validator: (v) {
                                        if (_selectedIncomeType ==
                                                IncomeType.ums ||
                                            _selectedIncomeType ==
                                                IncomeType.trial) {
                                          if (_selectedUserMap == null) {
                                            return 'Please select a user';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 8),

                                    if (_isSearchingUsers)
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: LinearProgressIndicator(
                                          minHeight: 3,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.successGreen,
                                              ),
                                        ),
                                      ),

                                    // Only show suggestions when we have results or are searching
                                    if (_userSuggestions.isNotEmpty ||
                                        _isSearchingUsers)
                                      _buildUserSuggestionsList(
                                        userSuggestions: _userSuggestions,
                                        isSearching: _isSearchingUsers,
                                        searchText: _userSearchController.text,
                                        onUserSelected: (item) {
                                          setSheetState(() {
                                            _selectedUserMap = item;
                                            _userSuggestions = [];
                                            final first =
                                                (item['firstName'] ?? '')
                                                    .toString()
                                                    .trim();
                                            final last =
                                                (item['lastName'] ?? '')
                                                    .toString()
                                                    .trim();
                                            final fullName =
                                                (first + ' ' + last).trim();
                                            _userSearchController.text =
                                                fullName.isEmpty
                                                ? (item['name']?.toString() ??
                                                      '')
                                                : fullName;
                                          });
                                        },
                                      ),

                                    // Show selected user's Total Due
                                    if (_selectedUserMap != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.infoBlue.withOpacity(
                                            0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.infoBlue
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.infoBlue
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons
                                                    .account_balance_wallet_rounded,
                                                color: AppTheme.infoBlue,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Total Outstanding',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.darkGrey
                                                          .withOpacity(0.8),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '₹${_getDueAmountFrom(_selectedUserMap!).toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          _getDueAmountFrom(
                                                                _selectedUserMap!,
                                                              ) >
                                                              0
                                                          ? AppTheme.errorRed
                                                          : AppTheme
                                                                .successGreen,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (_getDueAmountFrom(
                                                  _selectedUserMap!,
                                                ) >
                                                0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.errorRed
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Due',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.errorRed,
                                                  ),
                                                ),
                                              )
                                            else
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successGreen
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Clear',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.successGreen,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 24),
                                  ],

                                  // Amount Section
                                  _buildSectionTitle(
                                    'Amount',
                                    Icons.currency_rupee_rounded,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStyledTextField(
                                    controller: _amountController,
                                    hintText: 'Enter amount',
                                    icon: Icons.currency_rupee_rounded,
                                    color: AppTheme.successGreen,
                                    prefixText: '₹ ',
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Please enter amount';
                                      if (double.tryParse(value) == null)
                                        return 'Please enter valid amount';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Payment Mode Section
                                  _buildSectionTitle(
                                    'Payment Mode',
                                    Icons.payment_rounded,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStyledDropdown<PaymentMode>(
                                    value: _selectedMode,
                                    icon: Icons.payment_rounded,
                                    color: AppTheme.infoBlue,
                                    items: const [
                                      DropdownMenuItem(
                                        value: PaymentMode.cash,
                                        child: Text(
                                          'Cash',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: PaymentMode.online,
                                        child: Text(
                                          'Online',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) => setSheetState(
                                      () => _selectedMode = value!,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Date Selection Section
                                  _buildSectionTitle(
                                    'Payment Date',
                                    Icons.calendar_today_rounded,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDatePicker(
                                    _selectedDate,
                                    (newDate) => setSheetState(
                                      () => _selectedDate = newDate,
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Action Buttons
                                  _buildActionButtons(
                                    onCancel: () => Navigator.pop(context),
                                    onSubmit: _isSubmitting
                                        ? null
                                        : () async {
                                            if (!_formKey.currentState!
                                                .validate())
                                              return;
                                            if ((_selectedIncomeType ==
                                                        IncomeType.ums ||
                                                    _selectedIncomeType ==
                                                        IncomeType.trial) &&
                                                _selectedUserMap == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please select a user',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            // Prevent overpayment for selected user
                                            final enteredAmount = double.parse(
                                              _amountController.text,
                                            );
                                            if ((_selectedIncomeType ==
                                                        IncomeType.ums ||
                                                    _selectedIncomeType ==
                                                        IncomeType.trial) &&
                                                _selectedUserMap != null) {
                                              final due = _getDueAmountFrom(
                                                _selectedUserMap!,
                                              );
                                              if (due > 0 &&
                                                  enteredAmount > due) {
                                                await showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text(
                                                      'Amount exceeds Due',
                                                    ),
                                                    content: Text(
                                                      'Entered amount (₹${enteredAmount.toStringAsFixed(0)}) is greater than the outstanding due (₹${due.toStringAsFixed(0)}). Please enter an amount up to the due.',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(ctx),
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                return;
                                              }
                                            }
                                            setSheetState(
                                              () => _isSubmitting = true,
                                            );

                                            // build a minimal UserModel
                                            UserModel? selectedUser;
                                            if (_selectedUserMap != null) {
                                              final id =
                                                  (_selectedUserMap!['id'] ??
                                                          _selectedUserMap!['_id'] ??
                                                          _selectedUserMap!['userId'] ??
                                                          '')
                                                      .toString();
                                              final name = [
                                                (_selectedUserMap!['firstName'] ??
                                                        '')
                                                    .toString(),
                                                (_selectedUserMap!['lastName'] ??
                                                        '')
                                                    .toString(),
                                              ].join(' ').trim();
                                              selectedUser = UserModel(
                                                id: id,
                                                name: name.isEmpty
                                                    ? (_selectedUserMap!['name']
                                                              ?.toString() ??
                                                          '')
                                                    : name,
                                                mobileNumber:
                                                    (_selectedUserMap!['mobile'] ??
                                                            _selectedUserMap!['phone'] ??
                                                            '')
                                                        .toString(),
                                                address: '',
                                                referredBy:
                                                    ReferralSource.other,
                                                visitDate: DateTime.now(),
                                                userType:
                                                    (_selectedIncomeType ==
                                                            IncomeType.ums ||
                                                        _selectedIncomeType ==
                                                            IncomeType.trial)
                                                    ? UserType
                                                          .member // Default to member for UMS/Trial
                                                    : UserType.member,
                                                createdAt: DateTime.now(),
                                                updatedAt: DateTime.now(),
                                              );
                                            }

                                            final success =
                                                await _createIncomeEntry(
                                                  type:
                                                      _selectedIncomeType ==
                                                          IncomeType.ums
                                                      ? PaymentType.membership
                                                      : _selectedIncomeType ==
                                                            IncomeType.trial
                                                      ? PaymentType.trial
                                                      : PaymentType.expense,
                                                  amount: enteredAmount,
                                                  date: _selectedDate,
                                                  mode: _selectedMode,
                                                  customTitle:
                                                      _selectedIncomeType ==
                                                          IncomeType.others
                                                      ? _incomeTitleController
                                                            .text
                                                            .trim()
                                                      : null,
                                                  selectedUser: selectedUser,
                                                );

                                            setSheetState(
                                              () => _isSubmitting = false,
                                            );
                                            if (success && context.mounted) {
                                              Navigator.pop(context);
                                              await _fetchIncome(
                                                page: 1,
                                                reset: true,
                                              );
                                            }
                                          },
                                    isLoading: _isSubmitting,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _userSearchDebounce?.cancel();
    });
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlack),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledDropdown<T>({
    required T value,
    required IconData icon,
    required Color color,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color color,
    String? prefixText,
    TextInputType? keyboardType,
    TextStyle? style,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixText: prefixText,
          prefixStyle: const TextStyle(
            color: AppTheme.successGreen,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        keyboardType: keyboardType,
        style: style,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildUserSuggestionsList({
    required List<Map<String, dynamic>> userSuggestions,
    required bool isSearching,
    required String searchText,
    required void Function(Map<String, dynamic>) onUserSelected,
  }) {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: userSuggestions.isEmpty
          ? (searchText.trim().length >= 3 && !isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No matches found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start typing to search users',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ))
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: userSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = userSuggestions[index];
                final first = (item['firstName'] ?? '').toString().trim();
                final last = (item['lastName'] ?? '').toString().trim();
                final fullName = (first + ' ' + last).trim();
                // Use membershipType from API to decide designation label
                final membershipType = (item['membershipType'] ?? '')
                    .toString()
                    .toLowerCase();

                String designation;
                Color roleColor;
                IconData roleIcon;

                switch (membershipType) {
                  case 'coach':
                    designation = 'Coach';
                    roleColor = AppTheme.warningOrange;
                    roleIcon = Icons.sports_rounded;
                    break;
                  case 'senior_coach':
                  case 'seniorcoach':
                    designation = 'Senior Coach';
                    roleColor = AppTheme.errorRed;
                    roleIcon = Icons.military_tech_rounded;
                    break;
                  case 'trial':
                  case 'trail': // handle possible typo
                    designation = 'Trial';
                    roleColor = AppTheme.accentYellow;
                    roleIcon = Icons.hourglass_bottom_rounded;
                    break;
                  case 'member':
                    designation = 'UMS';
                    roleColor = AppTheme.successGreen;
                    roleIcon = Icons.person_rounded;
                    break;
                  default:
                    designation = 'UMS';
                    roleColor = AppTheme.successGreen;
                    roleIcon = Icons.person_rounded;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(roleIcon, color: roleColor, size: 24),
                    ),
                    title: Text(
                      fullName.isEmpty ? 'Unknown Name' : fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        designation,
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    onTap: () => onUserSelected(item),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildActionButtons({
    required VoidCallback onCancel,
    required VoidCallback? onSubmit,
    required bool isLoading,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successGreen,
                  AppTheme.successGreen.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    DateTime selectedDate,
    void Function(DateTime) onDateChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: Colors.black87, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppTheme.infoBlue,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black87,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != selectedDate) {
                onDateChanged(picked);
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.edit_calendar_rounded,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Extract due amount for a user suggestion map from API fields.
  // Prefers 'dueAmount'; falls back to (totalPayable - totalPaid);
  // then to legacy fields 'totalDue' or 'pendingDues'. Never negative.
  double _getDueAmountFrom(Map<String, dynamic> m) {
    double parseNum(dynamic v) {
      if (v == null) return 0;
      final s = v.toString();
      final d = double.tryParse(s);
      return d ?? 0;
    }

    final due = parseNum(m['dueAmount']);
    if (due > 0) return due;

    final totalPayable = parseNum(m['totalPayable']);
    final totalPaid = parseNum(m['totalPaid']);
    final computed = totalPayable - totalPaid;
    if (computed > 0) return computed;

    final legacy = parseNum(m['totalDue'] ?? m['pendingDues']);
    return legacy > 0 ? legacy : 0;
  }

  void _loadSampleData() {
    final now = DateTime.now();

    // Load sample users for linking income (20+ diverse payment scenarios)
    _users.addAll([
      // FULLY PAID MEMBERS
      UserModel(
        id: '1',
        name: 'John Smith',
        mobileNumber: '9876543210',
        address: '123 Wellness Street',
        referredBy: ReferralSource.friend,
        visitDate: now.subtract(const Duration(days: 15)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 15)),
        membershipEndDate: now.add(const Duration(days: 15)),
        totalPaid: 7500.0,
        pendingDues: 0.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),

      // PARTIALLY PAID MEMBERS
      UserModel(
        id: '2',
        name: 'Sarah Wilson',
        mobileNumber: '9876543211',
        address: '456 Health Avenue',
        referredBy: ReferralSource.google,
        visitDate: now.subtract(const Duration(days: 10)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 10)),
        membershipEndDate: now.add(const Duration(days: 20)),
        totalPaid: 5000.0,
        pendingDues: 2500.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      UserModel(
        id: '3',
        name: 'Robert Brown',
        mobileNumber: '9876543212',
        address: '789 Fitness Road',
        referredBy: ReferralSource.family,
        visitDate: now.subtract(const Duration(days: 20)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 20)),
        membershipEndDate: now.add(const Duration(days: 10)),
        totalPaid: 3000.0,
        pendingDues: 4500.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 20)),
      ),

      // TRIAL MEMBERS WITH NO PAYMENT
      UserModel(
        id: '4',
        name: 'Mike Johnson',
        mobileNumber: '9876543213',
        address: '321 Community Lane',
        referredBy: ReferralSource.other,
        visitDate: now.subtract(const Duration(days: 1)),
        userType: UserType.trial,
        trialStartDate: now.subtract(const Duration(days: 1)),
        trialEndDate: now.add(const Duration(days: 2)),
        totalPaid: 0.0,
        pendingDues: 750.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      UserModel(
        id: '5',
        name: 'Lisa White',
        mobileNumber: '9876543214',
        address: '567 Health Plaza',
        referredBy: ReferralSource.google,
        visitDate: now.subtract(const Duration(days: 2)),
        userType: UserType.trial,
        trialStartDate: now.subtract(const Duration(days: 2)),
        trialEndDate: now.add(const Duration(days: 1)),
        totalPaid: 0.0,
        pendingDues: 750.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),

      // TRIAL MEMBERS WITH PARTIAL PAYMENT
      UserModel(
        id: '6',
        name: 'Emma Davis',
        mobileNumber: '9876543215',
        address: '890 Wellness Center',
        referredBy: ReferralSource.friend,
        visitDate: now.subtract(const Duration(days: 3)),
        userType: UserType.trial,
        trialStartDate: now.subtract(const Duration(days: 3)),
        trialEndDate: now.add(const Duration(days: 0)),
        totalPaid: 500.0,
        pendingDues: 250.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      UserModel(
        id: '7',
        name: 'David Miller',
        mobileNumber: '9876543216',
        address: '234 Gym Street',
        referredBy: ReferralSource.family,
        visitDate: now.subtract(const Duration(days: 2)),
        userType: UserType.trial,
        trialStartDate: now.subtract(const Duration(days: 2)),
        trialEndDate: now.add(const Duration(days: 1)),
        totalPaid: 400.0,
        pendingDues: 350.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),

      // VISITORS (EXCLUDED FROM INCOME)
      UserModel(
        id: '8',
        name: 'Jennifer Green',
        mobileNumber: '9876543217',
        address: '345 Visitor Lane',
        referredBy: ReferralSource.google,
        visitDate: now.subtract(const Duration(days: 1)),
        userType: UserType.visitor,
        totalPaid: 0.0,
        pendingDues: 0.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      UserModel(
        id: '9',
        name: 'Mark Taylor',
        mobileNumber: '9876543218',
        address: '456 Guest Road',
        referredBy: ReferralSource.other,
        visitDate: now.subtract(const Duration(days: 0)),
        userType: UserType.visitor,
        totalPaid: 0.0,
        pendingDues: 0.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 0)),
        updatedAt: now.subtract(const Duration(days: 0)),
      ),

      // COACHES WITH PENDING FEES
      UserModel(
        id: '10',
        name: 'Alex Johnson',
        mobileNumber: '9876543219',
        address: '567 Coach Avenue',
        referredBy: ReferralSource.friend,
        visitDate: now.subtract(const Duration(days: 30)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 90)),
        membershipEndDate: now.add(const Duration(days: 270)),
        totalPaid: 20000.0,
        pendingDues: 2500.0,
        role: UserRole.coach,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),

      // COACHES WITH CLEARED FEES
      UserModel(
        id: '11',
        name: 'Sarah Wilson',
        mobileNumber: '9876543220',
        address: '678 Senior Coach Street',
        referredBy: ReferralSource.google,
        visitDate: now.subtract(const Duration(days: 60)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 180)),
        membershipEndDate: now.add(const Duration(days: 180)),
        totalPaid: 45000.0,
        pendingDues: 0.0,
        role: UserRole.seniorCoach,
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),

      // EDGE CASES: DUPLICATE NAMES
      UserModel(
        id: '12',
        name: 'John Smith', // Duplicate name
        mobileNumber: '9876543221', // Different phone
        address: '789 Duplicate Lane',
        referredBy: ReferralSource.family,
        visitDate: now.subtract(const Duration(days: 5)),
        userType: UserType.trial,
        trialStartDate: now.subtract(const Duration(days: 5)),
        trialEndDate: now.subtract(const Duration(days: 2)), // Expired trial
        totalPaid: 0.0,
        pendingDues: 750.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),

      // MORE DIVERSE SCENARIOS
      UserModel(
        id: '13',
        name: 'Maria Garcia',
        mobileNumber: '9876543222',
        address: '890 Latin Quarter',
        referredBy: ReferralSource.friend,
        visitDate: now.subtract(const Duration(days: 12)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 12)),
        membershipEndDate: now.add(const Duration(days: 18)),
        totalPaid: 7500.0,
        pendingDues: 0.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 12)),
      ),
      UserModel(
        id: '14',
        name: 'James Anderson',
        mobileNumber: '9876543223',
        address: '123 Anderson Street',
        referredBy: ReferralSource.google,
        visitDate: now.subtract(const Duration(days: 25)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 25)),
        membershipEndDate: now.add(const Duration(days: 5)),
        totalPaid: 1500.0,
        pendingDues: 6000.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 25)),
      ),
      UserModel(
        id: '15',
        name: 'Kelly Thompson',
        mobileNumber: '9876543224',
        address: '456 Thompson Road',
        referredBy: ReferralSource.other,
        visitDate: now.subtract(const Duration(days: 1)),
        userType: UserType.trial,
        trialStartDate: now.subtract(const Duration(days: 1)),
        trialEndDate: now.add(const Duration(days: 2)),
        totalPaid: 750.0,
        pendingDues: 0.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      UserModel(
        id: '16',
        name: 'Ryan Mitchell',
        mobileNumber: '9876543225',
        address: '789 Mitchell Lane',
        referredBy: ReferralSource.friend,
        visitDate: now.subtract(const Duration(days: 8)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 8)),
        membershipEndDate: now.add(const Duration(days: 22)),
        totalPaid: 4000.0,
        pendingDues: 3500.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
      UserModel(
        id: '17',
        name: 'Amy Chen',
        mobileNumber: '9876543226',
        address: '234 Chen Avenue',
        referredBy: ReferralSource.family,
        visitDate: now.subtract(const Duration(days: 3)),
        userType: UserType.trial,
        trialStartDate: now.subtract(const Duration(days: 3)),
        trialEndDate: now.add(const Duration(days: 0)),
        totalPaid: 300.0,
        pendingDues: 450.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      UserModel(
        id: '18',
        name: 'Brian Lee',
        mobileNumber: '9876543227',
        address: '567 Lee Street',
        referredBy: ReferralSource.google,
        visitDate: now.subtract(const Duration(days: 18)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 18)),
        membershipEndDate: now.add(const Duration(days: 12)),
        totalPaid: 7500.0,
        pendingDues: 0.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 18)),
        updatedAt: now.subtract(const Duration(days: 18)),
      ),
      UserModel(
        id: '19',
        name: 'Laura Wilson', // Similar name to coach
        mobileNumber: '9876543228',
        address: '890 Wilson Plaza',
        referredBy: ReferralSource.other,
        visitDate: now.subtract(const Duration(days: 2)),
        userType: UserType.trial,
        trialStartDate: now.subtract(const Duration(days: 2)),
        trialEndDate: now.add(const Duration(days: 1)),
        totalPaid: 600.0,
        pendingDues: 150.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      UserModel(
        id: '20',
        name: 'Steven Clark',
        mobileNumber: '9876543229',
        address: '123 Clark Boulevard',
        referredBy: ReferralSource.friend,
        visitDate: now.subtract(const Duration(days: 14)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 14)),
        membershipEndDate: now.add(const Duration(days: 16)),
        totalPaid: 6000.0,
        pendingDues: 1500.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 14)),
      ),
      UserModel(
        id: '21',
        name: 'Hannah Davis',
        mobileNumber: '9876543230',
        address: '456 Davis Court',
        referredBy: ReferralSource.family,
        visitDate: now.subtract(const Duration(days: 4)),
        userType: UserType.trial,
        trialStartDate: now.subtract(const Duration(days: 4)),
        trialEndDate: now.subtract(const Duration(days: 1)), // Expired
        totalPaid: 200.0,
        pendingDues: 550.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      UserModel(
        id: '22',
        name: 'Kevin Rodriguez',
        mobileNumber: '9876543231',
        address: '789 Rodriguez Way',
        referredBy: ReferralSource.google,
        visitDate: now.subtract(const Duration(days: 7)),
        userType: UserType.member,
        membershipStartDate: now.subtract(const Duration(days: 7)),
        membershipEndDate: now.add(const Duration(days: 23)),
        totalPaid: 7500.0,
        pendingDues: 0.0,
        role: UserRole.member,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
    ]);

    // Note: Sample income/expenses are not seeded here; real data is loaded via API.
  }

  // (legacy) Dialog-based Add Income was removed in favor of a unified bottom sheet UI.

  Future<bool> _createIncomeEntry({
    required PaymentType type,
    required double amount,
    required DateTime date,
    required PaymentMode mode,
    String? customTitle,
    UserModel? selectedUser,
  }) async {
    try {
      // Map type to API fields
      final String incomeType = (type == PaymentType.expense)
          ? 'other'
          : 'membership';
      final String title = type == PaymentType.expense
          ? (customTitle == null || customTitle.isEmpty
                ? 'Other Income'
                : customTitle)
          : 'Membership Payment';

      // Resolve userId
      String? userId;
      if (type == PaymentType.membership || type == PaymentType.trial) {
        userId = selectedUser?.id;
      } else {
        final currentUser = await AuthService().getCurrentUser();
        userId = currentUser?.id;
      }

      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final res = await ApiService.post(
        '/income',
        data: {
          'title': title,
          'amount': amount.toInt(),
          'incomeType': incomeType,
          'paymentDate': formattedDate,
          'paymentMethod': mode == PaymentMode.cash ? 'cash' : 'online',
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
        context: context,
        successMessage: 'Income entry created successfully',
      );
      return res != null && res['success'] == true;
    } catch (e) {
      ErrorHandler.handleError(context, e);
      return false;
    }
  }

  // (legacy) Searchable member selection dialog removed; bottom sheet has integrated search.

  // New: Beautiful bottom sheet for adding an expense (no category field)
  void _showAddExpenseBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var selectedMode = PaymentMode.cash;
    var selectedDate = DateTime.now();
    var isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.6,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, controller) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlack,
                                AppTheme.errorRed,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.remove_circle,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Add Expense',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: SingleChildScrollView(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            child: Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: titleCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Expense Title',
                                      hintText:
                                          'Enter expense title (e.g., Rent, Electricity)',
                                      prefixIcon: Icon(Icons.title),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Please enter expense title'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: descCtrl,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Description (optional)',
                                      prefixIcon: Icon(Icons.description),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: amountCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Amount',
                                      prefixText: '₹',
                                      prefixIcon: Icon(Icons.currency_rupee),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Please enter amount';
                                      final d = double.tryParse(v);
                                      if (d == null)
                                        return 'Please enter valid amount';
                                      if (d <= 0)
                                        return 'Amount must be greater than 0';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<PaymentMode>(
                                    value: selectedMode,
                                    decoration: const InputDecoration(
                                      labelText: 'Payment Mode',
                                      prefixIcon: Icon(Icons.payment),
                                      border: OutlineInputBorder(),
                                    ),
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
                                        setSheetState(() => selectedMode = v!),
                                  ),
                                  const SizedBox(height: 14),
                                  // Date picker row (black icon, no background)
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime.now().subtract(
                                          const Duration(days: 365),
                                        ),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setSheetState(
                                          () => selectedDate = picked,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.edit_calendar_rounded,
                                            color: Colors.black87,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Payment Date: ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.errorRed,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: isSubmitting
                                              ? null
                                              : () async {
                                                  if (!formKey.currentState!
                                                      .validate())
                                                    return;
                                                  setSheetState(
                                                    () => isSubmitting = true,
                                                  );
                                                  final amount = double.parse(
                                                    amountCtrl.text,
                                                  );
                                                  await _addSimpleExpenseEntry(
                                                    titleCtrl.text.trim(),
                                                    amount,
                                                    selectedDate,
                                                    selectedMode,
                                                    descCtrl.text.trim().isEmpty
                                                        ? titleCtrl.text.trim()
                                                        : descCtrl.text.trim(),
                                                  );
                                                  if (context.mounted)
                                                    Navigator.of(context).pop();
                                                  setSheetState(
                                                    () => isSubmitting = false,
                                                  );
                                                },
                                          child: isSubmitting
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Text('Add'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // (removed) _getFilteredUsers was unused

  Future<void> _addSimpleExpenseEntry(
    String expenseType,
    double amount,
    DateTime date,
    PaymentMode mode,
    String description,
  ) async {
    // Format date as ISO 8601 (YYYY-MM-DD) for API
    final formattedDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Convert PaymentMode to API format (API accepts only 'cash' or 'online')
    final paymentMethod = mode == PaymentMode.cash ? 'cash' : 'online';

    // Make API call using centralized service
    final responseData = await ApiService.post(
      '/expenses',
      data: {
        'title': expenseType,
        'description': description,
        'amount': amount.toInt(),
        'paymentMethod': paymentMethod,
        'expenseDate': formattedDate,
      },
      context: context,
      showSuccessMessage: true,
    );

    // Handle success - refresh the expenses list to get real data
    if (responseData != null && responseData['success'] == true) {
      // Refresh the expenses list from API to get the latest data
      await _fetchExpenses();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Financial Management'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filter Options',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.trending_up),
              text: 'Income (₹${filteredIncomeTotal.toInt()})',
            ),
            Tab(
              icon: const Icon(Icons.trending_down),
              text: 'Expenses (₹${filteredExpensesTotal.toInt()})',
            ),
          ],
          indicatorColor: AppTheme.accentYellow,
          labelColor: AppTheme.accentYellow,
          unselectedLabelColor: AppTheme.white.withOpacity(0.7),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildIncomeTab(), _buildExpensesTab()],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      backgroundColor: AppTheme.primaryBlack,
      foregroundColor: AppTheme.white,
      overlayColor: AppTheme.primaryBlack,
      overlayOpacity: 0.4,
      spacing: 12,
      spaceBetweenChildren: 12,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.add, color: AppTheme.white),
          backgroundColor: AppTheme.successGreen,
          label: 'Add Income',
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlack,
          ),
          onTap: () => _showAddIncomeBottomSheet(),
        ),
        SpeedDialChild(
          child: const Icon(Icons.remove, color: AppTheme.white),
          backgroundColor: AppTheme.errorRed,
          label: 'Add Expense',
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlack,
          ),
          onTap: () => _showAddExpenseBottomSheet(),
        ),
      ],
    ).animate().slide(
      begin: const Offset(0, 1),
      duration: 500.ms,
      delay: 300.ms,
    );
  }

  Widget _buildIncomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // Maintain current filter when refreshing
        DateTime? startDate;
        DateTime? endDate;

        if (_isIncomeFilterByDate && _selectedIncomeDate != null) {
          startDate = _selectedIncomeDate;
        } else if (_isIncomeFilterEnabled) {
          startDate = DateTime(
            _selectedIncomeMonth.year,
            _selectedIncomeMonth.month,
            1,
          );
          endDate = DateTime(
            _selectedIncomeMonth.year,
            _selectedIncomeMonth.month + 1,
            0,
          );
        }

        await _fetchIncome(
          page: 1,
          reset: true,
          startDate: startDate,
          endDate: endDate,
        );
      },
      child: Column(
        children: [
          // Show loading indicator when filtering
          if (_isFilterLoading)
            Container(
              margin: const EdgeInsets.all(16),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.successGreen,
                ),
              ),
            ),

          // Income list area
          Builder(
            builder: (context) {
              final filtered = _getFilteredIncome();
              if (_isLoadingIncome && filtered.isEmpty) {
                return Expanded(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: const [
                      SizedBox(height: 32),
                      Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Loading income...',
                          style: TextStyle(color: AppTheme.darkGrey),
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (filtered.isEmpty) {
                return Expanded(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 48,
                    ),
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isIncomeFilterEnabled
                                ? 'No income for ' +
                                      DateFormat(
                                        'MMM yyyy',
                                      ).format(_selectedIncomeMonth)
                                : 'No income yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pull to refresh or tap + to add income',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              return Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  itemCount: filtered.length + (_hasMoreIncome ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_hasMoreIncome && index == filtered.length) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: _isLoadingMoreIncome
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: () {
                                  // Maintain current filter when loading more
                                  DateTime? startDate;
                                  DateTime? endDate;

                                  if (_isIncomeFilterByDate &&
                                      _selectedIncomeDate != null) {
                                    startDate = _selectedIncomeDate;
                                  } else if (_isIncomeFilterEnabled) {
                                    startDate = DateTime(
                                      _selectedIncomeMonth.year,
                                      _selectedIncomeMonth.month,
                                      1,
                                    );
                                    endDate = DateTime(
                                      _selectedIncomeMonth.year,
                                      _selectedIncomeMonth.month + 1,
                                      0,
                                    );
                                  }

                                  _fetchIncome(
                                    page: _incomePage + 1,
                                    reset: false,
                                    startDate: startDate,
                                    endDate: endDate,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successGreen,
                                  foregroundColor: AppTheme.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Load More'),
                              ),
                      );
                    }

                    final payment = filtered[index];
                    final id = payment.id;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _animatedIncomeItems.add(id);
                    });
                    Widget item = _buildIncomeCard(payment, index);
                    item = KeyedSubtree(
                      key: ValueKey('income_$id'),
                      child: item,
                    );
                    return item; // Animations disabled temporarily
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    return RefreshIndicator(
      onRefresh: _refreshExpenses,
      child: Column(
        children: [
          // Show loading indicator when filtering
          if (_isFilterLoading)
            Container(
              margin: const EdgeInsets.all(16),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.errorRed),
              ),
            ),

          // Expenses List
          Expanded(child: _buildExpensesList()),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    final filteredExpenses = _getFilteredExpenses();

    if (_isLoadingExpenses && filteredExpenses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: const [
          SizedBox(height: 32),
          Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlack),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Loading expenses...',
              style: TextStyle(color: AppTheme.darkGrey),
            ),
          ),
        ],
      );
    }

    if (_hasExpenseError && filteredExpenses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.08),
              border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Failed to load expenses',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (_expensesErrorMessage != null)
                  Text(
                    _expensesErrorMessage!,
                    style: const TextStyle(color: AppTheme.errorRed),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _fetchExpenses(page: 1, reset: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: AppTheme.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (filteredExpenses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _isExpenseFilterEnabled
                    ? 'No expenses for ${DateFormat('MMM yyyy').format(_selectedExpenseMonth)}'
                    : 'No expenses yet',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pull to refresh or tap + to add expense',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount:
          filteredExpenses.length +
          ((_hasMoreExpenses && !_isRefreshingExpenses) ? 1 : 0),
      itemBuilder: (context, index) {
        if (_hasMoreExpenses &&
            !_isRefreshingExpenses &&
            index == filteredExpenses.length) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: _isLoadingMoreExpenses
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () {
                      // Maintain current filter when loading more
                      DateTime? startDate;
                      DateTime? endDate;

                      if (_isExpenseFilterByDate &&
                          _selectedExpenseDate != null) {
                        startDate = _selectedExpenseDate;
                      } else if (_isExpenseFilterEnabled) {
                        startDate = DateTime(
                          _selectedExpenseMonth.year,
                          _selectedExpenseMonth.month,
                          1,
                        );
                        endDate = DateTime(
                          _selectedExpenseMonth.year,
                          _selectedExpenseMonth.month + 1,
                          0,
                        );
                      }

                      _fetchExpenses(
                        page: _expensesPage + 1,
                        reset: false,
                        startDate: startDate,
                        endDate: endDate,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Load More'),
                  ),
          );
        }
        final expense = filteredExpenses[index];
        final id = expense.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animatedExpenseItems.add(id);
        });
        Widget item = _buildExpenseCard(expense, index);
        item = KeyedSubtree(key: ValueKey('expense_$id'), child: item);
        return item; // Animations disabled temporarily
      },
    );
  }

  Widget _buildIncomeCard(PaymentModel payment, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => IncomeDetailScreen(income: payment),
            ),
          );
          if (changed == true && mounted) {
            await _fetchIncome(page: 1, reset: true);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppTheme.white, AppTheme.successGreen.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: payment.type == PaymentType.trial
                  ? AppTheme.accentYellow
                  : payment.type == PaymentType.membership
                  ? AppTheme.successGreen
                  : AppTheme.infoBlue,
              child: Icon(
                payment.type == PaymentType.trial
                    ? Icons.schedule
                    : payment.type == PaymentType.membership
                    ? Icons.star
                    : Icons.receipt,
                color: AppTheme.white,
              ),
            ),
            title: Text(
              _getIncomeTitle(payment),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlack,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show linked user for membership/trial payments only
                if (payment.linkedUserName != null &&
                    payment.type != PaymentType.expense) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: AppTheme.accentYellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        payment.linkedUserName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                // Show title for other income in place of username
                if (payment.type == PaymentType.expense &&
                    payment.description != null) ...[
                  Row(
                    children: [
                      Icon(Icons.title, size: 14, color: AppTheme.accentYellow),
                      const SizedBox(width: 4),
                      Text(
                        payment.description!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  '${_formatDate(payment.date)} • ${_getPaymentModeText(payment.mode ?? PaymentMode.cash)}',
                  style: TextStyle(color: AppTheme.darkGrey.withOpacity(0.8)),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+₹${payment.amount.toInt()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successGreen,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getIncomeTitle(PaymentModel payment) {
    switch (payment.type) {
      case PaymentType.trial:
        return payment.linkedUserName != null
            ? 'Trial Payment'
            : 'Trial Payment';
      case PaymentType.membership:
        return payment.linkedUserName != null
            ? 'Membership Payment'
            : 'Membership Payment';
      case PaymentType.expense:
        return 'Other Income';
    }
  }

  Widget _buildExpenseCard(ExpenseModel expense, int index) {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseDetailScreen(expense: expense),
          ),
        );
        if (changed == true && mounted) {
          await _fetchExpenses();
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppTheme.white, AppTheme.errorRed.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getExpenseCategoryColor(expense.category),
              child: Icon(
                _getExpenseCategoryIcon(expense.category),
                color: AppTheme.white,
              ),
            ),
            title: Text(
              expense.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlack,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: TextStyle(color: AppTheme.darkGrey.withOpacity(0.8)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppTheme.darkGrey.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(expense.expenseDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkGrey.withOpacity(0.6),
                      ),
                    ),
                    if (expense.paymentMethod != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.payment,
                        size: 12,
                        color: AppTheme.darkGrey.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getPaymentMethodText(expense.paymentMethod!),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.darkGrey.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
                // if (expense.createdByName != null) ...[
                //   const SizedBox(height: 2),
                //   Row(
                //     children: [
                //       Icon(
                //         Icons.person,
                //         size: 12,
                //         color: AppTheme.accentYellow,
                //       ),
                //       const SizedBox(width: 4),
                //       Text(
                //         'Added by ${expense.createdByName}',
                //         style: TextStyle(
                //           fontSize: 11,
                //           color: AppTheme.accentYellow.withOpacity(0.8),
                //           fontWeight: FontWeight.w500,
                //         ),
                //       ),
                //     ],
                //   ),
                // ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${expense.amount.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.darkGrey.withOpacity(0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getExpenseCategoryColor(
                      expense.category,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getExpenseCategoryText(expense.category),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getExpenseCategoryColor(expense.category),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getPaymentModeText(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.online:
        return 'Online';
      // case PaymentMode.upi:
      //   return 'UPI';
      // case PaymentMode.netBanking:
      //   return 'Net Banking';
      // case PaymentMode.other:
      //   return 'Other';
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'online':
      case 'upi':
      case 'card': // Backend may send "Card" while we show it as Online
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

  // ignore: unused_element
  void _showExpenseMonthFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_month, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            const Text('Select Month'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year selector
              DropdownButton<int>(
                value: _selectedExpenseMonth.year,
                isExpanded: true,
                items: List.generate(6, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (year) {
                  if (year != null) {
                    setState(() {
                      _selectedExpenseMonth = DateTime(
                        year,
                        _selectedExpenseMonth.month,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Month grid
              SizedBox(
                height: 200,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected =
                        month == _selectedExpenseMonth.month &&
                        _selectedExpenseMonth.year ==
                            _selectedExpenseMonth.year;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedExpenseMonth = DateTime(
                            _selectedExpenseMonth.year,
                            month,
                          );
                          _isExpenseFilterEnabled = true;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.errorRed
                              : AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.errorRed.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('MMM').format(DateTime(2024, month)),
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.white
                                  : AppTheme.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
          TextButton(
            onPressed: () {
              final today = DateTime.now();
              setState(() {
                _isExpenseFilterEnabled = false;
                _isExpenseFilterByDate = true;
                _selectedExpenseDate = today;
              });
              Navigator.pop(context);
              _fetchExpenses(page: 1, reset: true, startDate: today);
            },
            child: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showIncomeMonthFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_month, color: AppTheme.successGreen),
            const SizedBox(width: 8),
            const Text('Select Month'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: _selectedIncomeMonth.year,
                isExpanded: true,
                items: List.generate(6, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (year) {
                  if (year != null) {
                    setState(() {
                      _selectedIncomeMonth = DateTime(
                        year,
                        _selectedIncomeMonth.month,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected =
                        month == _selectedIncomeMonth.month &&
                        _selectedIncomeMonth.year == _selectedIncomeMonth.year;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIncomeMonth = DateTime(
                            _selectedIncomeMonth.year,
                            month,
                          );
                          _isIncomeFilterEnabled = true;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.successGreen
                              : AppTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.successGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('MMM').format(DateTime(2024, month)),
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.white
                                  : AppTheme.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
          TextButton(
            onPressed: () {
              final today = DateTime.now();
              setState(() {
                _isIncomeFilterEnabled = false;
                _isIncomeFilterByDate = true;
                _selectedIncomeDate = today;
              });
              Navigator.pop(context);
              _fetchIncome(page: 1, reset: true, startDate: today);
            },
            child: const Text('Clear Filter'),
          ),
        ],
      ),
    );
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
}

// Expense Model matching API response
class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final String description;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? createdByName;
  final String? paymentMethod;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.description,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.createdByName,
    this.paymentMethod,
  });

  // Factory constructor to create ExpenseModel from API response
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      category: _getCategoryFromDescription(json['description']),
      description: json['description'],
      expenseDate: DateTime.parse(json['expenseDate']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
      createdByName: json['createdByName'],
      paymentMethod: json['paymentMethod'],
    );
  }

  // Helper method to map description/title to category
  static ExpenseCategory _getCategoryFromDescription(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('electric') ||
        desc.contains('power') ||
        desc.contains('bill')) {
      return ExpenseCategory.electricity;
    } else if (desc.contains('maintenance') ||
        desc.contains('repair') ||
        desc.contains('service')) {
      return ExpenseCategory.maintenance;
    } else if (desc.contains('rent') || desc.contains('rental')) {
      return ExpenseCategory.rent;
    }
    return ExpenseCategory.other;
  }
}

enum ExpenseCategory { maintenance, electricity, rent, other }
