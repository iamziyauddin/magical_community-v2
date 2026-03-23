import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/models/inventory_model.dart';
import 'package:magical_community/models/consumption_group_model.dart';
import 'package:magical_community/models/shake_entry_model.dart';
import 'package:magical_community/models/api_product_model.dart';
import 'package:magical_community/screens/inventory/consumption_detail_screen.dart';
import 'package:magical_community/screens/inventory/shake_consumption_detail_screen.dart';
import 'package:magical_community/core/services/api_service.dart';
import 'package:magical_community/data/models/member_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedProductMonth = DateTime.now();

  // Dialog preferences
  static const String _hideInfoDialogKey = 'hide_shake_info_dialog';

  // Demo data for products and consumptions
  final List<InventoryModel> _products = [];
  final List<ConsumptionGroupModel> _consumptions = [];
  final List<ShakeEntryModel> _shakeEntries = [];

  // API integration variables
  bool _isLoadingConsumptions = false;
  bool _isLoadingProducts = false;
  // Submission guard to prevent double submits
  bool _isSubmittingConsumption = false;
  // Refresh states to avoid double spinners with RefreshIndicator
  bool _isRefreshingShakes = false;
  bool _isRefreshingConsumptions = false;

  // Shakes list pagination and loading state
  final ScrollController _shakesScrollController = ScrollController();
  int _shakesPage = 1;
  bool _isLoadingShakes = false;
  bool _isLoadingMoreShakes = false;
  bool _hasMoreShakes = true;
  String? _shakesErrorMessage; // Inline error (no snackbars) for shakes GET
  // Shakes totals (from stats API)
  int _shakeTotalTrial = 0;
  int _shakeTotalUms = 0;
  int _shakeTotalAll = 0;

  // Consumptions list pagination and loading state
  final ScrollController _consumptionScrollController = ScrollController();
  int _consumptionPage = 1;
  final int _consumptionLimit = 20;
  bool _isLoadingMoreConsumptions = false;
  bool _hasMoreConsumptions = true;
  String?
  _consumptionsErrorMessage; // Inline error (no snackbars) for consumptions GET

  // Filter state for consumption
  DateTime _selectedConsumptionMonth = DateTime.now();
  bool _isConsumptionFilterEnabled = false;

  // New filter states (parity with Accounts): date vs month for both tabs
  DateTime? _selectedShakesDate;
  bool _isShakesFilterByDate = false;
  DateTime? _selectedConsumptionDate;
  bool _isConsumptionFilterByDate = false;

  // Getters for consumption totals
  int get totalConsumptions => _consumptions.length;
  int get filteredConsumptionsTotal {
    final filtered = _getFilteredConsumptions();
    return filtered.length;
  }

  // Filter consumptions by selected month (only if filter is enabled)
  List<ConsumptionGroupModel> _getFilteredConsumptions() {
    if (!_isConsumptionFilterEnabled) {
      return _consumptions; // Return all consumptions when filter is disabled
    }

    return _consumptions
        .where(
          (consumption) =>
              consumption.date.year == _selectedConsumptionMonth.year &&
              consumption.date.month == _selectedConsumptionMonth.month,
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProducts(); // Fetch products from API
    // Infinite scroll listeners for pagination
    _shakesScrollController.addListener(() {
      if (_shakesScrollController.position.pixels >=
          _shakesScrollController.position.maxScrollExtent - 200) {
        _loadMoreShakes();
      }
    });
    _consumptionScrollController.addListener(() {
      if (_consumptionScrollController.position.pixels >=
          _consumptionScrollController.position.maxScrollExtent - 200) {
        _loadMoreConsumptions();
      }
    });
    // Defaults
    final today = DateTime.now();
    // Shakes: default to current month
    _selectedMonth = DateTime(today.year, today.month, 1);
    _selectedShakesDate = null;
    _isShakesFilterByDate = false;
    // Products: default to current month (same as shakes)
    _selectedConsumptionMonth = DateTime(today.year, today.month, 1);
    _selectedConsumptionDate = null;
    _isConsumptionFilterByDate = false;
    _isConsumptionFilterEnabled = true;

    // Initial products usage load for current month
    final prodStart = DateTime(today.year, today.month, 1);
    final prodEnd = DateTime(today.year, today.month + 1, 0);
    _fetchConsumptionUsage(
      page: 1,
      reset: true,
      startDate: prodStart,
      endDate: prodEnd,
    );
    // Initial shakes load for current month
    final start = DateTime(today.year, today.month, 1);
    final end = DateTime(today.year, today.month + 1, 0);
    _fetchShakeConsumptions(
      page: 1,
      reset: true,
      startDate: start,
      endDate: end,
    );
  }

  Future<void> _fetchShakeConsumptions({
    int page = 1,
    bool reset = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      setState(() {
        if (reset || page == 1) {
          // During pull-to-refresh, avoid showing inline loader
          _isLoadingShakes = !_isRefreshingShakes;
        } else {
          _isLoadingMoreShakes = true;
        }
      });

      // Build stats endpoint query
      final String base = '/shakes/consumption/stats';
      assert(
        startDate != null,
        'startDate is required for stats endpoint (date or month range).',
      );
      final s = startDate == null
          ? ''
          : '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final e = endDate == null
          ? null
          : '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      final query = e == null
          ? '$base?startDate=$s'
          : '$base?startDate=$s&endDate=$e';

      final response = await ApiService.get(query, context: context);

      if (response != null && response['success'] == true) {
        final Map<String, dynamic> stats =
            (response['data'] as Map<String, dynamic>?) ?? {};
        final totals = (stats['breakdown'] as Map<String, dynamic>?) ?? {};
        final int totalUsage = (stats['totalShakeUsage'] as num?)?.toInt() ?? 0;
        final List<dynamic> dateWise =
            (stats['dateWiseData'] as List?) ?? const [];

        final List<ShakeEntryModel> fetched = dateWise.map((item) {
          final String dateStr = item['date']?.toString() ?? '';
          final DateTime date = DateTime.tryParse(dateStr) ?? DateTime.now();
          final int trial = (item['trial_shake'] as num?)?.toInt() ?? 0;
          final int ums = (item['ums_shake'] as num?)?.toInt() ?? 0;
          return ShakeEntryModel(
            id: dateStr.isNotEmpty
                ? dateStr
                : date.millisecondsSinceEpoch.toString(),
            date: DateTime(date.year, date.month, date.day),
            memberShakes: ums,
            trialShakes: trial,
            addedBy: 'Stats',
            createdAt: date,
            updatedAt: date,
          );
        }).toList();

        fetched.sort((a, b) => b.date.compareTo(a.date));
        final sumTrial = fetched.fold(0, (sum, e) => sum + e.trialShakes);
        final sumUms = fetched.fold(0, (sum, e) => sum + e.memberShakes);
        final sumAll = fetched.fold(0, (sum, e) => sum + e.totalShakes);

        setState(() {
          _shakeEntries
            ..clear()
            ..addAll(fetched);
          _shakeTotalTrial =
              (totals['total_trial_shake'] as num?)?.toInt() ?? sumTrial;
          _shakeTotalUms =
              (totals['total_ms_shake'] as num?)?.toInt() ??
              (totals['total_ums_shake'] as num?)?.toInt() ??
              sumUms;
          _shakeTotalAll = totalUsage != 0 ? totalUsage : sumAll;
          _shakesPage = 1;
          _hasMoreShakes = false; // stats has no pagination
          _shakesErrorMessage = null;
        });
      }
    } catch (e) {
      // Record error for inline display; avoid snackbars for GET lists
      _shakesErrorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingShakes = false;
          _isLoadingMoreShakes = false;
        });
      } else {
        _isLoadingShakes = false;
        _isLoadingMoreShakes = false;
      }
    }
  }

  Future<void> _refreshShakes() async {
    _shakesPage = 1;
    _hasMoreShakes = true;
    _isRefreshingShakes = true;
    try {
      // Maintain current filter when refreshing
      final range = _currentShakesFilterRange();
      final startDate = range.start;
      final endDate = range.end;
      await _fetchShakeConsumptions(
        page: 1,
        reset: true,
        startDate: startDate,
        endDate: endDate,
      );
    } finally {
      if (mounted)
        setState(() => _isRefreshingShakes = false);
      else
        _isRefreshingShakes = false;
    }
  }

  // Confirm and delete a shake entry for a specific date by resolving its id
  void _confirmDeleteShake(ShakeEntryModel entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text('Delete Shake Entry'),
          ],
        ),
        content: Text(
          'Delete shake entry for ${DateFormat('MMM dd, yyyy').format(entry.date)}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              _showProgressDialog('Deleting shake entry...');
              final ok = await _deleteShakeEntryByDate(entry.date);
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              if (ok) {
                final range = _currentShakesFilterRange();
                await _fetchShakeConsumptions(
                  page: 1,
                  reset: true,
                  startDate: range.start,
                  endDate: range.end,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shake entry deleted'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete shake entry'),
                      backgroundColor: AppTheme.errorRed,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Delete shake entry by date using startDate=endDate (no id resolution)
  Future<bool> _deleteShakeEntryByDate(DateTime date) async {
    try {
      final d = DateFormat('yyyy-MM-dd').format(date);
      // Delete entries for the specific date using single date parameter
      final del = await ApiService.delete(
        '/shakes/consumption?date=' + d,
        context: context,
      );
      return del != null && del['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // Navigate to shake consumption detail screen
  void _navigateToShakeDetail(ShakeEntryModel entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShakeConsumptionDetailScreen(shakeEntry: entry),
      ),
    );
  }

  void _showProgressDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMoreShakes() async {
    // Prevent triggering while already loading more, or during initial load, or when no more pages
    if (_isLoadingMoreShakes || _isLoadingShakes || !_hasMoreShakes) return;
    final range = _currentShakesFilterRange();
    final startDate = range.start;
    final endDate = range.end;
    await _fetchShakeConsumptions(
      page: _shakesPage + 1,
      reset: false,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Fetch products from API
  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _isLoadingProducts = true;
      });

      final response = await ApiService.get(
        '/products/?page=1&limit=20',
        context: context,
      );

      if (response != null && response['success'] == true) {
        final apiResponse = ApiProductsResponse.fromJson(response);

        setState(() {
          // Clear existing products and add API products
          _products.clear();
          _products.addAll(
            apiResponse.data.data
                .where((product) => product.isActive) // Only active products
                .map((apiProduct) => apiProduct.toInventoryModel())
                .toList(),
          );
        });
      }
    } catch (e) {
      // Errors are handled globally by ApiService/ErrorHandler; keep silent here
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  // Fetch consumption usage from API
  Future<void> _fetchConsumptionUsage({
    int page = 1,
    bool reset = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      setState(() {
        if (reset || page == 1) {
          // During pull-to-refresh, avoid showing inline loader
          _isLoadingConsumptions = !_isRefreshingConsumptions;
        } else {
          _isLoadingMoreConsumptions = true;
        }
      });

      // Build query with optional date filters
      String query = '/products/usage?page=$page&limit=$_consumptionLimit';
      if (startDate != null) {
        final s =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        query += '&startDate=' + s;
      }
      if (endDate != null) {
        final e =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        query += '&endDate=' + e;
      }

      final response = await ApiService.get(query, context: context);

      if (response != null && response['success'] == true) {
        final List<dynamic> usageData =
            (response['data']?['data'] as List?) ?? const [];
        final Map<String, dynamic> pagination =
            (response['data']?['pagination'] as Map<String, dynamic>?) ?? {};

        // Group API items by date (day) to build Multi-Product Consumption entries
        final Map<String, ConsumptionGroupModel> groupsByDate = {};
        for (var item in usageData) {
          final DateTime date =
              DateTime.tryParse(
                item['consumedAt'] ?? item['usageDate'] ?? '',
              ) ??
              DateTime.now();
          final String dateKey = _dateKey(date);

          final newItem = ConsumptionItem(
            productId:
                item['productId']?.toString() ?? item['id']?.toString() ?? '',
            productName:
                item['product']?['name'] ??
                item['productName'] ??
                'Unknown Product',
            quantity: (item['quantity'] as num?)?.toInt() ?? 0,
          );

          final addedBy =
              item['consumedBy']?['name'] ??
              item['createdByName'] ??
              'Unknown User';
          final createdAt =
              DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now();

          if (groupsByDate.containsKey(dateKey)) {
            final existing = groupsByDate[dateKey]!;
            final mergedItems = _mergeItemsByProductId([
              ...existing.items,
              newItem,
            ]);
            final mergedAddedBy = existing.addedBy == addedBy
                ? existing.addedBy
                : 'Multiple Users';
            groupsByDate[dateKey] = existing.copyWith(
              items: mergedItems,
              // Keep earliest createdAt for the day
              createdAt: existing.createdAt.isBefore(createdAt)
                  ? existing.createdAt
                  : createdAt,
              addedBy: mergedAddedBy,
            );
          } else {
            groupsByDate[dateKey] = ConsumptionGroupModel(
              id: dateKey, // Use date as stable group id
              items: [newItem],
              date: DateTime(date.year, date.month, date.day),
              addedBy: addedBy,
              createdAt: createdAt,
              notes: 'Product consumption from API',
            );
          }
        }

        final List<ConsumptionGroupModel> fetched = groupsByDate.values
            .toList();

        setState(() {
          if (reset || page == 1) {
            _consumptions
              ..clear()
              ..addAll(fetched);
          } else {
            // Merge groups into existing list by date key
            for (final group in fetched) {
              _mergeGroupIntoList(_consumptions, group);
            }
          }
          _consumptions.sort((a, b) => b.date.compareTo(a.date));
          _consumptionPage = page;
          // Prefer explicit pagination.hasNext; fallback to length check
          _hasMoreConsumptions =
              pagination['hasNext'] == true ||
              fetched.length >= _consumptionLimit;
          _consumptionsErrorMessage = null;
        });
      }
    } catch (error) {
      // Record error for inline display; avoid snackbars for GET lists
      _consumptionsErrorMessage = error.toString();
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConsumptions = false;
          _isLoadingMoreConsumptions = false;
        });
      } else {
        _isLoadingConsumptions = false;
        _isLoadingMoreConsumptions = false;
      }
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<ConsumptionItem> _mergeItemsByProductId(List<ConsumptionItem> items) {
    final Map<String, ConsumptionItem> byId = {};
    for (final it in items) {
      final existing = byId[it.productId];
      if (existing == null) {
        byId[it.productId] = it;
      } else {
        byId[it.productId] = existing.copyWith(
          quantity: existing.quantity + it.quantity,
        );
      }
    }
    return byId.values.toList();
  }

  void _mergeGroupIntoList(
    List<ConsumptionGroupModel> list,
    ConsumptionGroupModel newGroup,
  ) {
    final key = _dateKey(newGroup.date);
    final idx = list.indexWhere((g) => _dateKey(g.date) == key);
    if (idx == -1) {
      list.add(newGroup);
      return;
    }
    final existing = list[idx];
    final mergedItems = _mergeItemsByProductId([
      ...existing.items,
      ...newGroup.items,
    ]);
    final mergedAddedBy = existing.addedBy == newGroup.addedBy
        ? existing.addedBy
        : 'Multiple Users';
    list[idx] = existing.copyWith(
      items: mergedItems,
      createdAt: existing.createdAt.isBefore(newGroup.createdAt)
          ? existing.createdAt
          : newGroup.createdAt,
      addedBy: mergedAddedBy,
    );
  }

  Future<void> _refreshConsumptions() async {
    _consumptionPage = 1;
    _hasMoreConsumptions = true;
    _isRefreshingConsumptions = true;
    try {
      DateTime? startDate;
      DateTime? endDate;
      if (_isConsumptionFilterByDate && _selectedConsumptionDate != null) {
        startDate = _selectedConsumptionDate;
      } else if (_isConsumptionFilterEnabled) {
        startDate = DateTime(
          _selectedConsumptionMonth.year,
          _selectedConsumptionMonth.month,
          1,
        );
        endDate = DateTime(
          _selectedConsumptionMonth.year,
          _selectedConsumptionMonth.month + 1,
          0,
        );
      }
      await _fetchConsumptionUsage(
        page: 1,
        reset: true,
        startDate: startDate,
        endDate: endDate,
      );
    } finally {
      if (mounted)
        setState(() => _isRefreshingConsumptions = false);
      else
        _isRefreshingConsumptions = false;
    }
  }

  Future<void> _loadMoreConsumptions() async {
    if (_isLoadingConsumptions ||
        _isLoadingMoreConsumptions ||
        !_hasMoreConsumptions)
      return;
    await _fetchConsumptionUsage(page: _consumptionPage + 1, reset: false);
  }

  @override
  void dispose() {
    _shakesScrollController.dispose();
    _consumptionScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Filter',
            icon: const Icon(Icons.filter_list),
            onPressed: _onToolbarFilterPressed,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentYellow,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.darkGrey,
          tabs: const [
            // Swapped order: Shakes first, Products second
            Tab(icon: Icon(Icons.local_drink), text: 'Shakes'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Products'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // Maintain same order as tabs above
        children: [_buildShakesView(), _buildProductsView()],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      heroTag: 'inventoryFab', // Avoid duplicate hero tag conflicts
      onPressed: () {
        // Index 0 is now Shakes, 1 is Products
        if (_tabController.index == 0) {
          _showAddShakeDialog();
        } else {
          _showAddConsumptionDialog();
        }
      },
      backgroundColor: AppTheme.errorRed,
      foregroundColor: AppTheme.white,
      child: const Icon(Icons.add),
    );
  }

  Widget _buildProductsView() {
    return _buildConsumptionView();
  }

  void _onToolbarFilterPressed() {
    // Index 0 is Shakes after reordering
    if (_tabController.index == 0) {
      _showShakesFilterOptions();
    } else {
      _showConsumptionFilterOptions();
    }
  }

  Widget _buildShakesView() {
    return RefreshIndicator(
      onRefresh: _refreshShakes,
      color: AppTheme.infoBlue,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.local_drink, color: AppTheme.infoBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shake Tracking',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlack,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.infoBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _isShakesFilterByDate && _selectedShakesDate != null
                            ? DateFormat(
                                'dd MMM yyyy',
                              ).format(_selectedShakesDate!)
                            : DateFormat('MMM yyyy').format(_selectedMonth),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.infoBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactSummaryCard(
                        'UMS',
                        _shakeTotalUms,
                        AppTheme.successGreen,
                        Icons.fitness_center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactSummaryCard(
                        'Trials',
                        _shakeTotalTrial,
                        AppTheme.infoBlue,
                        Icons.sports_gymnastics,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactSummaryCard(
                        'Total',
                        _shakeTotalAll,
                        AppTheme.primaryBlack,
                        Icons.analytics,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(child: _buildShakeEntriesList()),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryCard(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShakeEntriesList() {
    final filteredEntries =
        (_isShakesFilterByDate && _selectedShakesDate != null)
        ? _shakeEntries
              .where(
                (e) =>
                    e.date.year == _selectedShakesDate!.year &&
                    e.date.month == _selectedShakesDate!.month &&
                    e.date.day == _selectedShakesDate!.day,
              )
              .toList()
        : _shakeEntries
              .where(
                (entry) =>
                    entry.date.year == _selectedMonth.year &&
                    entry.date.month == _selectedMonth.month,
              )
              .toList();

    if (_isLoadingShakes && filteredEntries.isEmpty) {
      return ListView(
        controller: _shakesScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: const [
          SizedBox(height: 32),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 12),
          Center(child: Text('Loading shakes...')),
        ],
      );
    }

    if (filteredEntries.isEmpty) {
      // Keep it scrollable so pull-to-refresh works even with no items
      return ListView(
        controller: _shakesScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        children: [
          if (_shakesErrorMessage != null)
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
                  Text(
                    'Failed to load shakes',
                    style: TextStyle(
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _shakesErrorMessage!,
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
                ],
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_drink_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _isShakesFilterByDate && _selectedShakesDate != null
                    ? 'No shake entries for ${DateFormat('dd MMM yyyy').format(_selectedShakesDate!)}'
                    : 'No shake entries for ${DateFormat('MMM yyyy').format(_selectedMonth)}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pull to refresh or tap + to add daily shake counts',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _shakesScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredEntries.length + (_isLoadingMoreShakes ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoadingMoreShakes && index == filteredEntries.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final entry = filteredEntries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _navigateToShakeDetail(entry),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.infoBlue,
                        child: Text(
                          DateFormat('dd').format(entry.date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(entry.date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to view individual records',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.infoBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total: ${entry.totalShakes}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppTheme.infoBlue,
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _confirmDeleteShake(entry),
                                borderRadius: BorderRadius.circular(6),
                                child: const Icon(
                                  Icons.delete,
                                  color: AppTheme.errorRed,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.successGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 14,
                                color: AppTheme.successGreen,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'M: ${entry.memberShakes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.successGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.infoBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.infoBlue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sports_gymnastics,
                                size: 14,
                                color: AppTheme.infoBlue,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'T: ${entry.trialShakes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.infoBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Delete is disabled in stats view; keeping APIs removed to avoid unused warnings.

  Widget _buildConsumptionView() {
    return RefreshIndicator(
      onRefresh: _refreshConsumptions,
      child: Column(
        children: [
          // Total Consumption Card (shows selected date or month; filter moved to toolbar)
          Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 84,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.errorRed.withOpacity(0.1),
                      AppTheme.errorRed.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    // Left: Icon and consumption info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.trending_down,
                        color: AppTheme.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Center: Consumption details (flexible)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Consumptions',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          Text(
                            _isConsumptionFilterEnabled
                                ? '$filteredConsumptionsTotal items'
                                : '$totalConsumptions items',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlack,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Right: Passive date/month label only
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.errorRed.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        _isConsumptionFilterByDate &&
                                _selectedConsumptionDate != null
                            ? DateFormat(
                                'dd MMM yyyy',
                              ).format(_selectedConsumptionDate!)
                            : (_isConsumptionFilterEnabled
                                  ? DateFormat(
                                      'MMM yy',
                                    ).format(_selectedConsumptionMonth)
                                  : DateFormat(
                                      'dd MMM yyyy',
                                    ).format(DateTime.now())),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Consumption List
          Expanded(child: _buildConsumptionsList()),
        ],
      ),
    );
  }

  void _showConsumptionFilterOptions() {
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
            Row(
              children: const [
                Icon(Icons.filter_list, color: AppTheme.errorRed),
                SizedBox(width: 8),
                Text(
                  'Filter Products Usage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: AppTheme.errorRed,
              ),
              title: const Text('Select Date'),
              subtitle: const Text('Filter by specific date'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _pickDate(AppTheme.errorRed);
                if (picked != null) {
                  setState(() {
                    _selectedConsumptionDate = picked;
                    _isConsumptionFilterByDate = true;
                    _isConsumptionFilterEnabled = false;
                  });
                  await _fetchConsumptionUsage(
                    page: 1,
                    reset: true,
                    startDate: picked,
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: AppTheme.errorRed,
              ),
              title: const Text('Select Month'),
              subtitle: const Text('Filter by entire month'),
              onTap: () async {
                Navigator.pop(context);
                final pickedMonth = await _showConsumptionMonthFilter();
                if (pickedMonth != null) {
                  setState(() {
                    _selectedConsumptionMonth = pickedMonth;
                    _isConsumptionFilterEnabled = true;
                    _isConsumptionFilterByDate = false;
                  });
                  final start = DateTime(
                    pickedMonth.year,
                    pickedMonth.month,
                    1,
                  );
                  final end = DateTime(
                    pickedMonth.year,
                    pickedMonth.month + 1,
                    0,
                  );
                  await _fetchConsumptionUsage(
                    page: 1,
                    reset: true,
                    startDate: start,
                    endDate: end,
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.clear, color: AppTheme.darkGrey),
              title: const Text('Clear Filter'),
              subtitle: const Text('Show current month'),
              onTap: () async {
                Navigator.pop(context);
                final today = DateTime.now();
                final start = DateTime(today.year, today.month, 1);
                final end = DateTime(today.year, today.month + 1, 0);
                setState(() {
                  _isConsumptionFilterByDate = false;
                  _isConsumptionFilterEnabled = true;
                  _selectedConsumptionDate = null;
                  _selectedConsumptionMonth = DateTime(
                    today.year,
                    today.month,
                    1,
                  );
                });
                await _fetchConsumptionUsage(
                  page: 1,
                  reset: true,
                  startDate: start,
                  endDate: end,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionsList() {
    final filteredConsumptions = _getFilteredConsumptions();

    if (_isLoadingConsumptions && filteredConsumptions.isEmpty) {
      return ListView(
        controller: _consumptionScrollController,
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
              'Loading consumptions...',
              style: TextStyle(color: AppTheme.darkGrey),
            ),
          ),
        ],
      );
    }

    if (filteredConsumptions.isEmpty) {
      // Keep scrollable for RefreshIndicator and show inline error if any
      return ListView(
        controller: _consumptionScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        children: [
          if (_consumptionsErrorMessage != null)
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
                  Text(
                    'Failed to load consumptions',
                    style: TextStyle(
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _consumptionsErrorMessage!,
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
                ],
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_drink_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _isConsumptionFilterEnabled
                    ? 'No consumptions for ${DateFormat('MMM yyyy').format(_selectedConsumptionMonth)}'
                    : 'No consumptions yet',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull to refresh or tap + to add consumption',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _consumptionScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount:
          filteredConsumptions.length + (_isLoadingMoreConsumptions ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoadingMoreConsumptions &&
            index == filteredConsumptions.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final consumption = filteredConsumptions[index];
        return _buildConsumptionCard(consumption, index);
      },
    );
  }

  // Add the filter method
  Future<DateTime?> _showConsumptionMonthFilter() async {
    return showDialog<DateTime>(
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
                value: _selectedConsumptionMonth.year,
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
                      _selectedConsumptionMonth = DateTime(
                        year,
                        _selectedConsumptionMonth.month,
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
                    final isSelected = _selectedConsumptionMonth.month == month;
                    return InkWell(
                      onTap: () {
                        final selected = DateTime(
                          _selectedConsumptionMonth.year,
                          month,
                        );
                        Navigator.pop(context, selected);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.errorRed
                              : AppTheme.lightGrey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.errorRed
                                : AppTheme.darkGrey.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('MMM').format(DateTime(2023, month)),
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.white
                                  : AppTheme.primaryBlack,
                              fontWeight: FontWeight.bold,
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
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isConsumptionFilterEnabled = false;
              });
              Navigator.pop(context, null);
            },
            child: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }

  // Bottom sheet for Shakes filter options
  void _showShakesFilterOptions() {
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
            Row(
              children: const [
                Icon(Icons.filter_list, color: AppTheme.infoBlue),
                SizedBox(width: 8),
                Text(
                  'Filter Shakes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: AppTheme.infoBlue,
              ),
              title: const Text('Select Date'),
              subtitle: const Text('Filter by specific date'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _pickDate(AppTheme.infoBlue);
                if (picked != null) {
                  setState(() {
                    _selectedShakesDate = picked;
                    _isShakesFilterByDate = true;
                  });
                  await _fetchShakeConsumptions(
                    page: 1,
                    reset: true,
                    startDate: picked,
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: AppTheme.infoBlue,
              ),
              title: const Text('Select Month'),
              subtitle: const Text('Filter by entire month'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _showMonthFilter();
                if (picked != null) {
                  setState(() {
                    _isShakesFilterByDate = false;
                    _selectedMonth = DateTime(picked.year, picked.month, 1);
                  });
                  final start = DateTime(picked.year, picked.month, 1);
                  final end = DateTime(picked.year, picked.month + 1, 0);
                  await _fetchShakeConsumptions(
                    page: 1,
                    reset: true,
                    startDate: start,
                    endDate: end,
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.clear, color: AppTheme.darkGrey),
              title: const Text('Clear Filter'),
              subtitle: const Text('Show current month'),
              onTap: () async {
                Navigator.pop(context);
                final today = DateTime.now();
                final start = DateTime(today.year, today.month, 1);
                final end = DateTime(today.year, today.month + 1, 0);
                setState(() {
                  _selectedShakesDate = null;
                  _isShakesFilterByDate = false;
                  _selectedMonth = DateTime(today.year, today.month, 1);
                });
                await _fetchShakeConsumptions(
                  page: 1,
                  reset: true,
                  startDate: start,
                  endDate: end,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(Color primary) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: AppTheme.white,
              surface: AppTheme.white,
              onSurface: AppTheme.primaryBlack,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Widget _buildConsumptionCard(ConsumptionGroupModel consumption, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppTheme.white, AppTheme.errorRed.withOpacity(0.03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          onTap: () => _showConsumptionDetail(consumption),
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: AppTheme.errorRed,
            radius: 24,
            child: Text(
              consumption.totalProducts.toString(),
              style: const TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            consumption.totalProducts == 1
                ? consumption.items.first.productName
                : 'Multi-Product Consumption',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.primaryBlack,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Show concise info for multi-product, detailed for single product
              if (consumption.totalProducts == 1)
                // Single product: show product details
                Row(
                  children: [
                    Icon(
                      Icons.remove_circle,
                      size: 14,
                      color: AppTheme.errorRed,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Quantity: ${consumption.items.first.quantity}',
                        style: const TextStyle(
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Multi-product: show concise summary
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.infoBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 14,
                        color: AppTheme.infoBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${consumption.totalProducts} products',
                        style: const TextStyle(
                          color: AppTheme.infoBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppTheme.darkGrey.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(consumption.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkGrey.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (consumption.totalProducts == 1)
                // Single product: show quantity badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Qty: ${consumption.totalQuantity}',
                    style: const TextStyle(
                      color: AppTheme.errorRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.darkGrey.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConsumptionDetail(ConsumptionGroupModel consumption) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ConsumptionDetailScreen(consumption: consumption),
      ),
    );

    if (changed == true) {
      // Reload the consumption list to reflect edits/deletions
      await _fetchConsumptionUsage(page: 1, reset: true);
    }
  }

  void _showAddConsumptionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      useSafeArea: false,
      builder: (context) => ConsumptionBottomSheet(
        products: _products,
        isLoadingProducts: _isLoadingProducts,
        onSubmitted: () async {
          // Refresh consumption list after adding
          await _fetchConsumptionUsage(page: 1, reset: true);
        },
        onValidateAndSubmit: _validateAndSubmitProductQuantities,
      ),
    );
  }

  bool _validateAndSubmitProductQuantities(
    Map<String, int> productQuantities,
    DateTime selectedDate,
  ) {
    // Allow multiple entries per date; duplicates will be shown separately or can be merged later.

    // Get products with quantities > 0
    List<MapEntry<String, int>> validEntries = productQuantities.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (validEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product with quantity > 0'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return false;
    }

    // Show preview dialog before submitting
    _showConsumptionPreview(validEntries, selectedDate);
    return true;
  }

  void _showConsumptionPreview(
    List<MapEntry<String, int>> entries,
    DateTime selectedDate,
  ) {
    bool isSubmitting = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPreviewState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.preview, color: AppTheme.infoBlue),
              SizedBox(width: 8),
              Text('Consumptions'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Products to consume:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final product = _products.firstWhere(
                        (p) => p.id == entry.key,
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            product.productName,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Qty: ${entry.value}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorRed,
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
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setPreviewState(() => isSubmitting = true);
                      final success = await _addConsumptionFromQuantities(
                        entries,
                        selectedDate,
                      );
                      if (success) {
                        // Close preview and the underlying add dialog
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      } else {
                        setPreviewState(() => isSubmitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Submitting...'),
                      ],
                    )
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _addConsumptionFromQuantities(
    List<MapEntry<String, int>> entries,
    DateTime selectedDate,
  ) async {
    // Prevent double submission
    if (_isSubmittingConsumption) return false;
    setState(() {
      _isSubmittingConsumption = true;
    });
    try {
      // Prepare API request
      final usageRequest = ApiUsageRequest(
        usageDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        products: entries
            .map(
              (entry) =>
                  ApiUsageProduct(productId: entry.key, quantity: entry.value),
            )
            .toList(),
      );

      // Submit to API
      final response = await ApiService.post(
        '/products/usage',
        data: usageRequest.toJson(),
        context: context,
        successMessage: 'Consumption recorded successfully!',
      );

      if (response != null && response['success'] == true) {
        final apiResponse = ApiUsageResponse.fromJson(response);
        // Refresh from API to reflect server truth and keep list sorted
        await _fetchConsumptionUsage();
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${apiResponse.data.count} products consumption recorded successfully!',
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        return true;
      } else {
        throw Exception('API response was not successful');
      }
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record consumption: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingConsumption = false;
        });
      } else {
        _isSubmittingConsumption = false;
      }
    }
  }

  void _showAddShakeDialog([ShakeEntryModel? existingEntry]) {
    if (existingEntry != null) {
      // For editing existing entries, use the new bottom sheet
      _showEditShakeBottomSheet(existingEntry);
    } else {
      // For new entries, show the bottom sheet
      _showShakeBottomSheet();
    }
  }

  void _showEditShakeBottomSheet(ShakeEntryModel existingEntry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      useSafeArea: false,
      builder: (context) => EditShakeBottomSheet(
        existingEntry: existingEntry,
        onSubmitted: () async {
          // After editing shakes, refetch stats with the active filter range
          final range = _currentShakesFilterRange();
          await _fetchShakeConsumptions(
            page: 1,
            reset: true,
            startDate: range.start,
            endDate: range.end,
          );
        },
        onUpdateShake: _putShakeConsumption,
      ),
    );
  }

  void _showShakeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      useSafeArea: false,
      builder: (context) => ShakeEntryBottomSheet(
        onSubmitted: () async {
          // After adding shakes, refetch stats with the active filter range
          final range = _currentShakesFilterRange();
          await _fetchShakeConsumptions(
            page: 1,
            reset: true,
            startDate: range.start,
            endDate: range.end,
          );
        },
      ),
    );

    // Move info dialog check to after the bottom sheet is shown to avoid conflict
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowInfoDialog();
    });
  }

  Future<bool> _putShakeConsumption({
    required String id,
    required DateTime date,
    required int memberShakes,
    required int trialShakes,
  }) async {
    try {
      final res = await ApiService.put(
        '/shakes/consumption/$id',
        data: {
          'consumptionDate': DateFormat('yyyy-MM-dd').format(date),
          'trialShakes': trialShakes,
          'memberShakes': memberShakes,
        },
        context: context,
        successMessage: 'Consumption updated',
      );
      return res != null && res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // (Legacy) Check if a product consumption group exists for a date.
  // Retained for potential future use (no longer blocks adding new entries).
  // ignore: unused_element
  bool _hasConsumptionOnDate(DateTime date) {
    return _consumptions.any(
      (c) =>
          c.date.year == date.year &&
          c.date.month == date.month &&
          c.date.day == date.day,
    );
  }

  // ignore: unused_element
  void _addShakeEntry(DateTime date, int memberShakes, int trialShakes) {
    final now = DateTime.now();

    // Check for existing entry and update or add new
    final existingIndex = _shakeEntries.indexWhere(
      (entry) =>
          entry.date.year == date.year &&
          entry.date.month == date.month &&
          entry.date.day == date.day,
    );

    if (existingIndex >= 0) {
      // Update existing entry
      setState(() {
        _shakeEntries[existingIndex] = _shakeEntries[existingIndex].copyWith(
          memberShakes: memberShakes,
          trialShakes: trialShakes,
          updatedAt: now,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shake entry updated for ${DateFormat('MMM dd').format(date)}',
          ),
          backgroundColor: AppTheme.infoBlue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Add new entry
      final newEntry = ShakeEntryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: date,
        memberShakes: memberShakes,
        trialShakes: trialShakes,
        addedBy: 'admin',
        createdAt: now,
        updatedAt: now,
      );

      setState(() {
        _shakeEntries.add(newEntry);
        _shakeEntries.sort((a, b) => b.date.compareTo(a.date));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shake entry added for ${DateFormat('MMM dd').format(date)}',
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<DateTime?> _showMonthFilter() async {
    return showDialog<DateTime?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_month, color: AppTheme.infoBlue),
            const SizedBox(width: 8),
            const Text('Select Month'),
          ],
        ),
        content: SizedBox(
          height: 280,
          width: 300,
          child: Column(
            children: [
              // Year selector
              DropdownButton<int>(
                value: _selectedMonth.year,
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
                      _selectedMonth = DateTime(year, _selectedMonth.month);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Month grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = month == _selectedMonth.month;
                    return InkWell(
                      onTap: () {
                        // Keep selected year from dropdown state
                        final picked = DateTime(_selectedMonth.year, month, 1);
                        Navigator.pop(context, picked);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.infoBlue
                              : AppTheme.infoBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.infoBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('MMM').format(DateTime(2024, month)),
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.white
                                  : AppTheme.infoBlue,
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
        ],
      ),
    );
  }

  // Compute current start/end date for shakes based on active filter
  ({DateTime? start, DateTime? end}) _currentShakesFilterRange() {
    if (_isShakesFilterByDate && _selectedShakesDate != null) {
      return (start: _selectedShakesDate, end: null);
    }
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    return (start: start, end: end);
  }

  // ignore: unused_element
  void _showProductMonthFilter() {
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
          height: 280,
          width: 300,
          child: Column(
            children: [
              // Year selector
              DropdownButton<int>(
                value: _selectedProductMonth.year,
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
                      _selectedProductMonth = DateTime(
                        year,
                        _selectedProductMonth.month,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Month grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected =
                        month == _selectedProductMonth.month &&
                        _selectedProductMonth.year ==
                            _selectedProductMonth.year;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedProductMonth = DateTime(
                            _selectedProductMonth.year,
                            month,
                          );
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
        ],
      ),
    );
  }

  Future<void> _checkAndShowInfoDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hideDialog = prefs.getBool(_hideInfoDialogKey) ?? false;

    if (!hideDialog && mounted) {
      _showShakeInfoDialog();
    }
  }

  void _showShakeInfoDialog() {
    bool dontShowAgain = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.infoBlue, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'User Visibility Info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please note that only users with the following criteria will be visible in the shake entry list:',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildInfoPoint('🔹', 'Users with remaining shake count > 0'),
              const SizedBox(height: 8),
              _buildInfoPoint('🔹', 'Active users only'),
              const SizedBox(height: 8),
              _buildInfoPoint('🔹', 'Users with valid membership/trial status'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentYellow.withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'Users with zero shake count or inactive status will not appear in this list.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryBlack,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: dontShowAgain,
                    onChanged: (value) {
                      setDialogState(() {
                        dontShowAgain = value ?? false;
                      });
                    },
                    activeColor: AppTheme.successGreen,
                  ),
                  const Expanded(
                    child: Text(
                      "Don't show this message again",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (dontShowAgain) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(_hideInfoDialogKey, true);
                }
                if (mounted) Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String bullet, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(bullet, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.3)),
        ),
      ],
    );
  }
}

// New Bottom Sheet for Consumption Entry
class ConsumptionBottomSheet extends StatefulWidget {
  final List<InventoryModel> products;
  final bool isLoadingProducts;
  final VoidCallback? onSubmitted;
  final bool Function(Map<String, int>, DateTime) onValidateAndSubmit;

  const ConsumptionBottomSheet({
    super.key,
    required this.products,
    required this.isLoadingProducts,
    this.onSubmitted,
    required this.onValidateAndSubmit,
  });

  @override
  State<ConsumptionBottomSheet> createState() => _ConsumptionBottomSheetState();
}

class _ConsumptionBottomSheetState extends State<ConsumptionBottomSheet> {
  DateTime _selectedDate = DateTime.now();
  Map<String, int> _productQuantities = {};

  @override
  void initState() {
    super.initState();
    // Initialize quantities for each product
    for (var product in widget.products) {
      _productQuantities[product.id] = 0;
    }
  }

  int get _totalSelectedProducts =>
      _productQuantities.values.where((qty) => qty > 0).length;

  int get _totalQuantity =>
      _productQuantities.values.fold(0, (sum, qty) => sum + qty);

  bool get _canSubmit => _totalQuantity > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: AppTheme.white),
      child: Column(
        children: [
          // Header with close button and title
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.darkGrey),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.remove_circle, color: AppTheme.errorRed),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Add Consumption',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                ),
                if (_canSubmit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$_totalSelectedProducts products',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Date selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.darkGrey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppTheme.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consumption Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkGrey.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.darkGrey.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Products section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Text(
                  'Select Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const Spacer(),
                if (_totalQuantity > 0)
                  Text(
                    'Total: $_totalQuantity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.errorRed,
                    ),
                  ),
              ],
            ),
          ),

          // Products list
          Expanded(
            child: widget.isLoadingProducts
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.errorRed),
                        SizedBox(height: 16),
                        Text(
                          'Loading products...',
                          style: TextStyle(color: AppTheme.darkGrey),
                        ),
                      ],
                    ),
                  )
                : widget.products.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppTheme.darkGrey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No products available',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: widget.products.length,
                    itemBuilder: (context, index) {
                      final product = widget.products[index];
                      final quantity = _productQuantities[product.id] ?? 0;
                      return _buildProductCard(product, quantity);
                    },
                  ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? AppTheme.errorRed
                        : AppTheme.darkGrey,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _canSubmit
                        ? 'Add Consumption ($_totalSelectedProducts products)'
                        : 'Select products to continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(InventoryModel product, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quantity > 0
              ? AppTheme.errorRed.withOpacity(0.3)
              : AppTheme.darkGrey.withOpacity(0.1),
          width: quantity > 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product avatar
          CircleAvatar(
            backgroundColor: quantity > 0
                ? AppTheme.errorRed.withOpacity(0.1)
                : AppTheme.darkGrey.withOpacity(0.1),
            child: Icon(
              Icons.inventory_2,
              color: quantity > 0 ? AppTheme.errorRed : AppTheme.darkGrey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minus button
                IconButton(
                  onPressed: quantity > 0
                      ? () => _updateQuantity(product.id, quantity - 1)
                      : null,
                  icon: const Icon(Icons.remove, size: 18),
                  style: IconButton.styleFrom(
                    foregroundColor: quantity > 0
                        ? AppTheme.errorRed
                        : AppTheme.darkGrey.withOpacity(0.5),
                  ),
                ),

                // Quantity display
                Container(
                  constraints: const BoxConstraints(minWidth: 40),
                  alignment: Alignment.center,
                  child: Text(
                    quantity.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: quantity > 0
                          ? AppTheme.primaryBlack
                          : AppTheme.darkGrey.withOpacity(0.5),
                    ),
                  ),
                ),

                // Plus button
                IconButton(
                  onPressed: () => _updateQuantity(product.id, quantity + 1),
                  icon: const Icon(Icons.add, size: 18),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(String productId, int newQuantity) {
    setState(() {
      _productQuantities[productId] = newQuantity.clamp(0, 999);
    });
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
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

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  void _handleSubmit() {
    // Close bottom sheet first
    Navigator.of(context).pop();

    // Call the validation and submit function
    final success = widget.onValidateAndSubmit(
      _productQuantities,
      _selectedDate,
    );

    if (success) {
      // Callback for parent to refresh data
      widget.onSubmitted?.call();
    }
  }
}

class ShakeEntryBottomSheet extends StatefulWidget {
  final VoidCallback? onSubmitted;

  const ShakeEntryBottomSheet({super.key, this.onSubmitted});

  @override
  State<ShakeEntryBottomSheet> createState() => _ShakeEntryBottomSheetState();
}

class _ShakeEntryBottomSheetState extends State<ShakeEntryBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  // Trail data
  List<Member> _trailUsers = [];
  Map<String, int> _trailShakeQuantities = {};
  Map<String, String?> _trailMembershipHistoryIds =
      {}; // userId -> membershipHistoryId
  bool _isLoadingTrail = false;
  bool _isLoadingMoreTrail = false;
  final ScrollController _trailScrollController = ScrollController();

  // UMS data
  List<Member> _umsUsers = [];
  Map<String, int> _umsShakeQuantities = {};
  Map<String, String?> _umsMembershipHistoryIds =
      {}; // userId -> membershipHistoryId
  bool _isLoadingUms = false;
  bool _isLoadingMoreUms = false;
  final ScrollController _umsScrollController = ScrollController();

  // Pagination support
  int _currentPage = 1;
  bool _hasMoreUsers = true;
  final int _pageLimit = 100;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Delay the initial fetch to next frame when context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsersForDate(page: 1, reset: true);
    });
    _setupInfiniteScroll();
  }

  void _onTabChanged() {
    // No need for separate tab-based loading since we use unified API
  }

  void _setupInfiniteScroll() {
    _trailScrollController.addListener(() {
      if (_trailScrollController.position.pixels >=
          _trailScrollController.position.maxScrollExtent - 200) {
        _loadMoreUsers();
      }
    });

    _umsScrollController.addListener(() {
      if (_umsScrollController.position.pixels >=
          _umsScrollController.position.maxScrollExtent - 200) {
        _loadMoreUsers();
      }
    });
  }

  Future<void> _fetchUsersForDate({int page = 1, bool reset = false}) async {
    if ((_isLoadingTrail || _isLoadingUms) && !reset) return;

    setState(() {
      if (reset || page == 1) {
        _isLoadingTrail = true;
        _isLoadingUms = true;
        _currentPage = 1;
        _hasMoreUsers = true;
        _trailUsers.clear();
        _umsUsers.clear();
        _trailShakeQuantities.clear();
        _umsShakeQuantities.clear();
      } else {
        _isLoadingMoreTrail = true;
        _isLoadingMoreUms = true;
      }
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await ApiService.get(
        '/shakes/consumption/users?consumptionDate=$formattedDate&page=$page&limit=$_pageLimit',
        context: context,
      );

      if (response != null && response['success'] == true) {
        final List<dynamic> usersData =
            (response['data']?['data'] as List?) ?? [];
        final Map<String, dynamic> pagination =
            (response['data']?['pagination'] as Map<String, dynamic>?) ?? {};

        final List<Member> newTrailUsers = [];
        final List<Member> newUmsUsers = [];

        for (var userData in usersData) {
          final membershipHistory =
              userData['membershipHistory'] as Map<String, dynamic>? ?? {};
          final subscription =
              userData['subscription'] as Map<String, dynamic>? ?? {};
          final bool isTrial = subscription['isTrial'] as bool? ?? false;

          // Extract the id from API response
          final String userId =
              userData['id']?.toString() ??
              '${userData['firstName']}_${userData['lastName']}_${DateTime.now().millisecondsSinceEpoch}';

          // Extract membershipHistory ID for shake consumption tracking
          // Try multiple possible field names
          final String? membershipHistoryId =
              membershipHistory['id']?.toString() ??
              membershipHistory['membershipId']?.toString() ??
              membershipHistory['_id']?.toString();

          // Debug: Log membershipHistory data
          print('DEBUG: userId=$userId');
          print('DEBUG: membershipHistory keys: ${membershipHistory.keys}');
          print('DEBUG: membershipHistory full: $membershipHistory');
          print('DEBUG: membershipHistoryId=$membershipHistoryId');

          final member = Member(
            userId:
                userId, // Use the API-provided ID or fallback to generated ID
            firstName: userData['firstName']?.toString() ?? '',
            lastName: userData['lastName']?.toString() ?? '',
            email: '',
            phoneNumber: '',
            role: '',
            memberRole: isTrial ? 'trial' : 'membership',
            isActive: true,
            membershipStatus: '',
            membershipStartDate: DateTime.now(),
            membershipEndDate: DateTime.now(),
            totalPayable: 0,
            totalPaid: 0,
            dueAmount: 0,
            membershipType: isTrial ? 'trial' : 'membership',
            totalDueShake:
                (membershipHistory['totalDueShake'] as num?)?.toInt() ?? 0,
            totalConsumedShake:
                (membershipHistory['totalConsumedShake'] as num?)?.toInt() ?? 0,
            membershipHistoryId: membershipHistoryId,
          );

          // Only add users with totalDueShake > 0
          if (member.totalDueShake > 0) {
            if (isTrial) {
              newTrailUsers.add(member);
              if (membershipHistoryId != null) {
                _trailMembershipHistoryIds[userId] = membershipHistoryId;
              }
            } else {
              newUmsUsers.add(member);
              if (membershipHistoryId != null) {
                _umsMembershipHistoryIds[userId] = membershipHistoryId;
              }
            }
          }
        }

        setState(() {
          if (reset || page == 1) {
            _trailUsers.clear();
            _umsUsers.clear();
            _trailShakeQuantities.clear();
            _umsShakeQuantities.clear();
            _trailMembershipHistoryIds.clear();
            _umsMembershipHistoryIds.clear();
            _currentPage = 1;
          }

          // Add new users to existing lists
          _trailUsers.addAll(newTrailUsers);
          _umsUsers.addAll(newUmsUsers);

          // Initialize quantities for new users
          for (var user in newTrailUsers) {
            if (!_trailShakeQuantities.containsKey(user.userId)) {
              _trailShakeQuantities[user.userId] = 0;
            }
          }
          for (var user in newUmsUsers) {
            if (!_umsShakeQuantities.containsKey(user.userId)) {
              _umsShakeQuantities[user.userId] = 0;
            }
          }

          // Update pagination info
          _currentPage = page;
          _hasMoreUsers =
              pagination['hasNext'] == true || usersData.length >= _pageLimit;
        });
      }
    } catch (e) {
      // Handle error silently or show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTrail = false;
          _isLoadingUms = false;
          _isLoadingMoreTrail = false;
          _isLoadingMoreUms = false;
        });
      }
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMoreTrail || _isLoadingMoreUms || !_hasMoreUsers) return;

    await _fetchUsersForDate(page: _currentPage + 1, reset: false);
  }

  int get _totalTrailShakes =>
      _trailShakeQuantities.values.fold(0, (sum, qty) => sum + qty);
  int get _totalUmsShakes =>
      _umsShakeQuantities.values.fold(0, (sum, qty) => sum + qty);

  @override
  void dispose() {
    _tabController.dispose();
    _trailScrollController.dispose();
    _umsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: AppTheme.white),
      child: Column(
        children: [
          // Header with date picker
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.local_drink, color: AppTheme.successGreen),
                    const SizedBox(width: 12),
                    const Text(
                      'Add Shake Entry',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Date Picker
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppTheme.successGreen,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.white,
              unselectedLabelColor: AppTheme.primaryBlack,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successGreen,
                    AppTheme.successGreen.withOpacity(0.8),
                  ],
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_gymnastics, size: 18),
                      const SizedBox(width: 6),
                      const Text('Trail'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center, size: 18),
                      const SizedBox(width: 6),
                      const Text('UMS'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildTrailTab(), _buildUmsTab()],
            ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submitShakeEntry : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting...'),
                          ],
                        )
                      : Text(
                          'Submit Shake Entry (${_totalTrailShakes + _totalUmsShakes} shakes)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSubmit =>
      (_totalTrailShakes + _totalUmsShakes) > 0 && !_isSubmitting;

  Widget _buildTrailTab() {
    // Filter: hide users whose total due shakes <= 0
    final visibleTrailUsers = _trailUsers
        .where((u) => u.totalDueShake > 0)
        .toList();

    if (_isLoadingTrail && visibleTrailUsers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.successGreen),
      );
    }
    if (visibleTrailUsers.isEmpty && !_isLoadingTrail) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_gymnastics,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No trail users with remaining shakes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh or check back later',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchUsersForDate(page: 1, reset: true),
      child: ListView.builder(
        controller: _trailScrollController,
        padding: const EdgeInsets.all(20),
        itemCount:
            visibleTrailUsers.length +
            (_isLoadingMoreTrail && _hasMoreUsers ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isLoadingMoreTrail && index == visibleTrailUsers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Loading more users...',
                      style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = visibleTrailUsers[index];
          final quantity = _trailShakeQuantities[user.userId] ?? 0;

          return _buildUserShakeCard(
            user: user,
            quantity: quantity,
            onQuantityChanged: (newQuantity) {
              setState(() {
                _trailShakeQuantities[user.userId] = newQuantity;
              });
            },
            isTrail: true,
          );
        },
      ),
    );
  }

  Widget _buildUmsTab() {
    // Filter: hide users whose total due shakes <= 0
    final visibleUmsUsers = _umsUsers
        .where((u) => u.totalDueShake > 0)
        .toList();

    if (_isLoadingUms && visibleUmsUsers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.successGreen),
      );
    }
    if (visibleUmsUsers.isEmpty && !_isLoadingUms) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No UMS members with remaining shakes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh or check back later',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchUsersForDate(page: 1, reset: true),
      child: ListView.builder(
        controller: _umsScrollController,
        padding: const EdgeInsets.all(20),
        itemCount:
            visibleUmsUsers.length +
            (_isLoadingMoreUms && _hasMoreUsers ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isLoadingMoreUms && index == visibleUmsUsers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Loading more users...',
                      style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = visibleUmsUsers[index];
          final quantity = _umsShakeQuantities[user.userId] ?? 0;

          return _buildUserShakeCard(
            user: user,
            quantity: quantity,
            onQuantityChanged: (newQuantity) {
              setState(() {
                _umsShakeQuantities[user.userId] = newQuantity;
              });
            },
            isTrail: false,
          );
        },
      ),
    );
  }

  Widget _buildUserShakeCard({
    required Member user,
    required int quantity,
    required Function(int) onQuantityChanged,
    required bool isTrail,
  }) {
    final cardColor = AppTheme.successGreen;
    // Allow increment up to totalDueShake (user already filtered to have > 0)
    final bool canIncrement =
        user.totalDueShake > 0 && quantity < user.totalDueShake;
    final bool canDecrement = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quantity > 0
              ? cardColor.withOpacity(0.3)
              : Colors.grey.shade200,
          width: quantity > 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: quantity > 0
                ? cardColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: cardColor.withOpacity(0.1),
            child: Text(
              '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}',
              style: TextStyle(
                color: cardColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: AppTheme.userNameTextStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Show shakes counters: due and consumed (wrap to avoid overlap)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Due: ${user.totalDueShake}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Consumed: ${user.totalConsumedShake}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            constraints: const BoxConstraints(minWidth: 112),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minus Button
                IconButton(
                  onPressed: canDecrement
                      ? () => onQuantityChanged(quantity - 1)
                      : null,
                  icon: const Icon(Icons.remove, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: canDecrement
                        ? AppTheme.errorRed.withOpacity(0.1)
                        : Colors.transparent,
                    foregroundColor: canDecrement
                        ? AppTheme.errorRed
                        : Colors.grey,
                    minimumSize: const Size(32, 32),
                  ),
                ),

                // Quantity Display
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    quantity.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: quantity > 0 ? cardColor : Colors.grey.shade600,
                    ),
                  ),
                ),

                // Plus Button
                IconButton(
                  onPressed: canIncrement
                      ? () => onQuantityChanged(quantity + 1)
                      : null,
                  icon: const Icon(Icons.add, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: (canIncrement ? cardColor : Colors.grey)
                        .withOpacity(0.1),
                    foregroundColor: canIncrement ? cardColor : Colors.grey,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.successGreen,
              onPrimary: AppTheme.white,
              surface: AppTheme.white,
              onSurface: AppTheme.primaryBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });

      // Fetch users for the new selected date (reset pagination)
      await _fetchUsersForDate(page: 1, reset: true);
    }
  }

  void _showProgressDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitShakeEntry() async {
    if (_isSubmitting || !_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Pre-submit validation: ensure no user exceeds their total due shakes
      bool invalid = false;
      String? invalidUserName;
      // Helper to validate a map against its user list
      bool validate(Map<String, int> quantities, List<Member> users) {
        for (final entry in quantities.entries) {
          Member? user;
          for (final u in users) {
            if (u.userId == entry.key) {
              user = u;
              break;
            }
          }
          if (user == null) continue; // skip if not found
          // Allow up to totalDueShake (matching UI button logic)
          if (entry.value > user.totalDueShake) {
            invalidUserName = '${user.firstName} ${user.lastName}'.trim();
            return false;
          }
        }
        return true;
      }

      if (!validate(_trailShakeQuantities, _trailUsers) ||
          !validate(_umsShakeQuantities, _umsUsers)) {
        invalid = true;
      }

      if (invalid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                invalidUserName == null
                    ? 'One or more users exceed their total due shakes.'
                    : 'Cannot exceed total due shakes for $invalidUserName.',
              ),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
      // Calculate totals
      final totalTrialShakes = _totalTrailShakes;
      final totalMemberShakes = _totalUmsShakes;
      final totalShakes = totalTrialShakes + totalMemberShakes;

      // Show progress dialog for large submissions (5+ shakes)
      if (totalShakes >= 5 && mounted) {
        _showProgressDialog(
          totalShakes >= 20
              ? 'Processing $totalShakes shakes...\nThanks for your patience, we\'re working on it! 🚀'
              : totalShakes >= 10
              ? 'Processing $totalShakes shakes...\nAlmost done, please wait a moment! ⏳'
              : 'Processing $totalShakes shakes...\nHang tight, this will just take a moment! ✨',
        );
      }

      // Submit the shake entry (will aggregate if date already exists)
      final success = await _postShakeConsumption(
        date: _selectedDate,
        trialShakes: totalTrialShakes,
        memberShakes: totalMemberShakes,
      );

      // Hide progress dialog if shown
      if (totalShakes >= 5 && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSubmitted?.call();
          // Prefer backend-provided message if present (pass-through policy)
          String serverMsg = '';
          try {
            // No direct response here because _postShakeConsumption only returns bool.
            // Optionally could be extended to return response map.
          } catch (_) {}
          final msg = serverMsg.isNotEmpty
              ? serverMsg
              : 'Trail: $totalTrialShakes, UMS: $totalMemberShakes';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Hide progress dialog if shown
      final totalShakes = _totalTrailShakes + _totalUmsShakes;
      if (totalShakes >= 5 && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool> _postShakeConsumption({
    required DateTime date,
    required int trialShakes,
    required int memberShakes,
  }) async {
    try {
      // Build consumption array from individual user selections
      List<Map<String, dynamic>> consumptions = [];

      // Add trail user consumptions
      for (var entry in _trailShakeQuantities.entries) {
        if (entry.value > 0) {
          final consumption = {'userId': entry.key, 'totalShake': entry.value};
          // Add membershipId if available
          String? membershipId = _trailMembershipHistoryIds[entry.key];
          if (membershipId == null) {
            // Fallback: find from in-memory users list
            Member? m;
            for (final u in _trailUsers) {
              if (u.userId == entry.key) {
                m = u;
                break;
              }
            }
            membershipId = m?.membershipHistoryId;
          }
          // Always include membershipId key for backend visibility
          consumption['membershipId'] = membershipId ?? '';
          consumptions.add(consumption);
        }
      }

      // Add UMS user consumptions
      for (var entry in _umsShakeQuantities.entries) {
        if (entry.value > 0) {
          final consumption = {'userId': entry.key, 'totalShake': entry.value};
          // Add membershipId if available
          String? membershipId = _umsMembershipHistoryIds[entry.key];
          if (membershipId == null) {
            // Fallback: find from in-memory users list
            Member? m;
            for (final u in _umsUsers) {
              if (u.userId == entry.key) {
                m = u;
                break;
              }
            }
            membershipId = m?.membershipHistoryId;
          }
          // Always include membershipId key for backend visibility
          consumption['membershipId'] = membershipId ?? '';
          consumptions.add(consumption);
        }
      }

      if (consumptions.isEmpty) {
        return false; // Silent: UI should not call submit when none selected
      }

      final payload = {
        'consumptionDate': DateFormat('yyyy-MM-dd').format(date),
        'consumptions': consumptions,
      };

      // Debug: Log the payload being sent
      print('DEBUG: Shake consumption payload: $payload');

      final response = await ApiService.post(
        '/shakes/consumption',
        data: payload,
        context: context,
      );

      if (response != null && response['success'] == true) {
        return true;
      }
      // Pass through server message if any
      final serverMsg = response != null && response['message'] is String
          ? response['message'] as String
          : '';
      throw Exception(serverMsg.isNotEmpty ? serverMsg : '');
    } catch (e) {
      // Show raw server/exception message only (policy: no static prefix)
      if (mounted) {
        final msg = e.toString();
        if (msg.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      return false;
    }
  }
}

// Helper class for product slots (keeping for compatibility but not used)
class ProductSlot {
  InventoryModel? selectedProduct;
  int quantity = 0;

  ProductSlot({this.selectedProduct, this.quantity = 0});
}

// Bottom Sheet for Editing Shake Entries
class EditShakeBottomSheet extends StatefulWidget {
  final ShakeEntryModel existingEntry;
  final VoidCallback? onSubmitted;
  final Future<bool> Function({
    required String id,
    required DateTime date,
    required int memberShakes,
    required int trialShakes,
  })
  onUpdateShake;

  const EditShakeBottomSheet({
    super.key,
    required this.existingEntry,
    this.onSubmitted,
    required this.onUpdateShake,
  });

  @override
  State<EditShakeBottomSheet> createState() => _EditShakeBottomSheetState();
}

class _EditShakeBottomSheetState extends State<EditShakeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _memberShakesController = TextEditingController();
  final _trialShakesController = TextEditingController();
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingEntry.date;
    // Pre-fill fields
    _memberShakesController.text = widget.existingEntry.memberShakes.toString();
    _trialShakesController.text = widget.existingEntry.trialShakes.toString();
  }

  @override
  void dispose() {
    _memberShakesController.dispose();
    _trialShakesController.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: AppTheme.white),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.infoBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top Row with Close Button
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.white,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Edit Shake Entry',
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the close button
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date Display (read-only for edit)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppTheme.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entry Date',
                                style: TextStyle(
                                  color: AppTheme.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'EEEE, MMMM dd, yyyy',
                                ).format(_selectedDate),
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form Content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // UMS Shakes Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.successGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: AppTheme.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'UMS Shakes Served',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlack,
                                      ),
                                    ),
                                    Text(
                                      'Number of shakes served to UMS members',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.darkGrey.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _memberShakesController,
                            decoration: InputDecoration(
                              labelText: 'UMS Shakes Count',
                              hintText:
                                  'Enter number of shakes for UMS members',
                              prefixIcon: const Icon(
                                Icons.fitness_center,
                                color: AppTheme.successGreen,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.successGreen,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter UMS shakes count';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              if (int.parse(value) < 0) {
                                return 'Number cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Trial Shakes Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.infoBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.infoBlue,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.sports_gymnastics,
                                  color: AppTheme.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Trial Shakes Served',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlack,
                                      ),
                                    ),
                                    Text(
                                      'Number of shakes served to trial users',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.darkGrey.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _trialShakesController,
                            decoration: InputDecoration(
                              labelText: 'Trial Shakes Count',
                              hintText:
                                  'Enter number of shakes for trial users',
                              prefixIcon: const Icon(
                                Icons.sports_gymnastics,
                                color: AppTheme.infoBlue,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.infoBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter trial shakes count';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              if (int.parse(value) < 0) {
                                return 'Number cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.white,
              border: Border(
                top: BorderSide(color: AppTheme.lightGrey.withOpacity(0.5)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.infoBlue,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Updating Entry...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Update Shake Entry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final memberShakes = int.parse(_memberShakesController.text);
      final trialShakes = int.parse(_trialShakesController.text);

      final success = await widget.onUpdateShake(
        id: widget.existingEntry.id,
        date: _selectedDate,
        memberShakes: memberShakes,
        trialShakes: trialShakes,
      );

      if (mounted) {
        Navigator.of(context).pop();
        if (success && widget.onSubmitted != null) {
          widget.onSubmitted!();
        }
      }
    } catch (e) {
      // Error handling is done by the API service
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
