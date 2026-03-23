import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/core/services/api_service.dart';
import 'package:magical_community/models/shake_entry_model.dart';

class ShakeConsumptionRecord {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final int totalShakes;
  final bool isTrial;
  final DateTime consumptionDate;
  final DateTime createdAt;

  ShakeConsumptionRecord({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.totalShakes,
    required this.isTrial,
    required this.consumptionDate,
    required this.createdAt,
  });

  factory ShakeConsumptionRecord.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return ShakeConsumptionRecord(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      firstName: user['firstName']?.toString() ?? '',
      lastName: user['lastName']?.toString() ?? '',
      totalShakes: (json['totalShakes'] as num?)?.toInt() ?? 0,
      isTrial: json['isTrial'] as bool? ?? false,
      consumptionDate:
          DateTime.tryParse(json['consumptionDate']?.toString() ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get userType => isTrial ? 'Trial' : 'UMS';
  Color get userTypeColor =>
      isTrial ? AppTheme.infoBlue : AppTheme.successGreen;
}

enum FilterType { all, trial, ums }

class ShakeConsumptionDetailScreen extends StatefulWidget {
  final ShakeEntryModel shakeEntry;

  const ShakeConsumptionDetailScreen({super.key, required this.shakeEntry});

  @override
  State<ShakeConsumptionDetailScreen> createState() =>
      _ShakeConsumptionDetailScreenState();
}

class _ShakeConsumptionDetailScreenState
    extends State<ShakeConsumptionDetailScreen> {
  List<ShakeConsumptionRecord> _consumptionRecords = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _limit = 100;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  // Filter state - default to All
  FilterType _currentFilter = FilterType.all;

  @override
  void initState() {
    super.initState();
    _setupInfiniteScroll();
    _fetchConsumptionDetails();
  }

  void _setupInfiniteScroll() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreData();
      }
    });
  }

  Future<void> _fetchConsumptionDetails({bool reset = false}) async {
    if (_isLoading && !reset) return;

    setState(() {
      if (reset) {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
        _consumptionRecords.clear();
        _errorMessage = null;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final dateString = DateFormat(
        'yyyy-MM-dd',
      ).format(widget.shakeEntry.date);

      final response = await ApiService.get(
        '/shakes/consumption?startDate=$dateString&endDate=$dateString&page=$_currentPage&limit=$_limit',
        context: context,
      );

      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final recordsData = data['data'] as List<dynamic>;
        final pagination = data['pagination'] as Map<String, dynamic>;

        final newRecords = recordsData
            .map((json) => ShakeConsumptionRecord.fromJson(json))
            .toList();

        setState(() {
          if (reset) {
            _consumptionRecords = newRecords;
          } else {
            _consumptionRecords.addAll(newRecords);
          }

          // Update pagination
          _currentPage = pagination['page'] as int;
          _hasMoreData = pagination['hasNext'] as bool? ?? false;

          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load consumption details';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMoreData || _isLoadingMore) return;

    setState(() {
      _currentPage++;
    });

    await _fetchConsumptionDetails();
  }

  Future<void> _refresh() async {
    await _fetchConsumptionDetails(reset: true);
  }

  void _switchFilter(FilterType filterType) {
    if (_currentFilter != filterType) {
      setState(() {
        _currentFilter = filterType;
      });
    }
  }

  Map<String, dynamic> _getFilterInfo() {
    switch (_currentFilter) {
      case FilterType.all:
        return {'text': 'consumption', 'icon': Icons.list};
      case FilterType.trial:
        return {'text': 'trial user', 'icon': Icons.sports_gymnastics};
      case FilterType.ums:
        return {'text': 'UMS member', 'icon': Icons.fitness_center};
    }
  }

  List<ShakeConsumptionRecord> get _filteredRecords {
    return _consumptionRecords.where((record) {
      switch (_currentFilter) {
        case FilterType.all:
          return true;
        case FilterType.trial:
          return record.isTrial;
        case FilterType.ums:
          return !record.isTrial;
      }
    }).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: Text(
          'Shake Details - ${DateFormat('MMM dd, yyyy').format(widget.shakeEntry.date)}',
        ),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats Header
          _buildFilterHeader(),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat(
                      'EEEE, MMMM dd, yyyy',
                    ).format(widget.shakeEntry.date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  Text(
                    _isLoading && _consumptionRecords.isEmpty
                        ? 'Loading consumption data...'
                        : 'Shake Consumption Records',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkGrey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter Buttons
          _buildFilterButtons(),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterButton(
            'All',
            FilterType.all,
            Icons.list,
            AppTheme.primaryBlack,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterButton(
            'Trial',
            FilterType.trial,
            Icons.sports_gymnastics,
            AppTheme.infoBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterButton(
            'UMS',
            FilterType.ums,
            Icons.fitness_center,
            AppTheme.successGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(
    String title,
    FilterType filterType,
    IconData icon,
    Color color,
  ) {
    final isActive = _currentFilter == filterType;

    return GestureDetector(
      onTap: () => _switchFilter(filterType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color.withOpacity(0.5) : color.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Show loading indicator during initial load or when no data is available yet
    if (_isLoading || _consumptionRecords.isEmpty) {
      // If there's an error message, show error state
      if (_errorMessage != null && _consumptionRecords.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        );
      }

      // Show loading indicator
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading consumption details...'),
          ],
        ),
      );
    }

    if (_consumptionRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_drink_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No consumption records found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'for ${DateFormat('MMM dd, yyyy').format(widget.shakeEntry.date)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (_filteredRecords.isEmpty) {
      final filterInfo = _getFilterInfo();
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filterInfo['icon'] as IconData,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${filterInfo['text']} records found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'for ${DateFormat('MMM dd, yyyy').format(widget.shakeEntry.date)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Text(
              'Try selecting a different filter above',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredRecords.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isLoadingMore && index == _filteredRecords.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Loading more records...',
                      style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
                    ),
                  ],
                ),
              ),
            );
          }

          final record = _filteredRecords[index];
          return _buildConsumptionCard(record);
        },
      ),
    );
  }

  Widget _buildConsumptionCard(ShakeConsumptionRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [AppTheme.white, record.userTypeColor.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: record.userTypeColor.withOpacity(0.1),
                radius: 24,
                child: Text(
                  record.firstName.isNotEmpty && record.lastName.isNotEmpty
                      ? '${record.firstName[0]}${record.lastName[0]}'
                      : record.firstName.isNotEmpty
                      ? record.firstName[0]
                      : 'U',
                  style: TextStyle(
                    color: record.userTypeColor,
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
                      record.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: record.userTypeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: record.userTypeColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                record.isTrial
                                    ? Icons.sports_gymnastics
                                    : Icons.fitness_center,
                                size: 12,
                                color: record.userTypeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                record.userType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: record.userTypeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('HH:mm').format(record.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.darkGrey.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Shake Count
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_drink,
                      color: AppTheme.primaryBlack,
                      size: 16,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.totalShakes.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                    Text(
                      record.totalShakes == 1 ? 'shake' : 'shakes',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppTheme.darkGrey.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
