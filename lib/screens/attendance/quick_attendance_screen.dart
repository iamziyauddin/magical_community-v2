import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/data/services/user_service.dart';

enum AttendanceFilter { all, present, absent }

// Simple Member class for attendance tracking
class Member {
  final String id;
  final String name;
  final String mobileNumber;
  final bool isActive;

  Member({
    required this.id,
    required this.name,
    required this.mobileNumber,
    this.isActive = true,
  });
}

class QuickAttendanceScreen extends StatefulWidget {
  const QuickAttendanceScreen({super.key});

  @override
  State<QuickAttendanceScreen> createState() => _QuickAttendanceScreenState();
}

class _QuickAttendanceScreenState extends State<QuickAttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();
  List<Member> _allMembers = [];
  List<Member> _filteredMembers = [];
  Map<String, bool> _attendanceStatus = {}; // true = present, false = absent
  Map<String, bool> _originalStatus = {}; // Track original state for changes
  AttendanceFilter _currentFilter = AttendanceFilter.all;
  bool _hasUnsavedChanges = false;
  DateTime _selectedDate = DateTime.now();
  int _page = 1;
  final int _limit = 50;
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool get _hasMore => _total > 0 && _allMembers.length < _total;

  @override
  void initState() {
    super.initState();
    _initLoad();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initLoad() async {
    _page = 1;
    _total = 0;
    _allMembers = [];
    _filteredMembers = [];
    _attendanceStatus = {};
    _originalStatus = {};
    _hasUnsavedChanges = false;
    await _fetchMembers(reset: true);
    _applyFilter();
  }

  Future<void> _fetchMembers({bool reset = false}) async {
    if (_isLoading || _isLoadingMore) return;
    setState(() {
      if (reset) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    final result = await _userService.fetchFilteredUsers(
      page: _page,
      limit: _limit,
      activeOnly: false,
      membershipTypes: const ['membership', 'trial'],
    );

    result.when(
      success: (pageData) {
        _total = pageData.meta.total;
        final newMembers = pageData.data
            .map(
              (u) => Member(
                id: u.userId,
                name: '${u.firstName} ${u.lastName}'.trim(),
                mobileNumber: u.phoneNumber ?? '',
                isActive: u.membershipStatus.toLowerCase() == 'active',
              ),
            )
            .toList();

        // Append unique and default them to Present if not already set
        for (final m in newMembers) {
          if (_allMembers.indexWhere((e) => e.id == m.id) == -1) {
            _allMembers.add(m);
            // Ensure every member has a status - default to Present
            _attendanceStatus[m.id] = true;
            // Keep baseline in sync so adding pages doesn't trigger unsaved state
            if (_originalStatus.isNotEmpty) {
              _originalStatus[m.id] = true;
            }
          }
        }
        // For a new date/session:
        // - If today, baseline to current so Save isn't enabled by default.
        // - If not today (missed day), enable Save by leaving baseline empty.
        if (reset && _originalStatus.isEmpty) {
          if (_isToday(_selectedDate)) {
            _originalStatus = Map.from(_attendanceStatus);
          } else {
            _originalStatus = {};
            _hasUnsavedChanges = true;
          }
        }

        _page += 1;
      },
      failure: (msg, statusCode) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _fetchMembers(reset: reset),
              ),
            ),
          );
        }
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_isLoading || _isLoadingMore) return;
    if (_allMembers.length >= _total && _total > 0) return; // no more
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _fetchMembers(reset: false).then((_) => _applyFilter());
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF67B437),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _hasUnsavedChanges = false; // Reset unsaved changes when changing date
      });
      // Reinitialize for the selected date (default all present again)
      await _initLoad();
    }
  }

  // No per-date server fetch for statuses; default-present each day

  void _applyFilter() {
    String searchQuery = _searchController.text.toLowerCase();

    List<Member> filtered = _allMembers.where((member) {
      // First apply search filter
      bool matchesSearch =
          (member.name.toLowerCase().contains(searchQuery) ||
          member.mobileNumber.contains(searchQuery));

      if (!matchesSearch) return false;

      // Then apply attendance filter
      switch (_currentFilter) {
        case AttendanceFilter.present:
          return _attendanceStatus[member.id] == true;
        case AttendanceFilter.absent:
          return _attendanceStatus[member.id] == false;
        case AttendanceFilter.all:
          return true;
      }
    }).toList();

    // Sort: Present first, then Absent, then by name
    filtered.sort((a, b) {
      bool aPresent = _attendanceStatus[a.id] == true;
      bool bPresent = _attendanceStatus[b.id] == true;

      if (aPresent && !bPresent) return -1;
      if (!aPresent && bPresent) return 1;
      return a.name.compareTo(b.name);
    });

    setState(() {
      _filteredMembers = filtered;
    });
  }

  void _toggleAttendance(Member member, bool isPresent) {
    setState(() {
      _attendanceStatus[member.id] = isPresent;
      _hasUnsavedChanges = !_mapEquals(_attendanceStatus, _originalStatus);
    });
    _applyFilter();
  }

  bool _mapEquals(Map<String, bool> map1, Map<String, bool> map2) {
    if (map1.length != map2.length) return false;
    for (String key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  void _saveAttendance() async {
    // Build full map of marked users (present + absent)
    final Map<String, bool> marked = Map.from(_attendanceStatus);
    // Show blocking progress while submitting
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    final result = await _userService.submitAttendance(
      attendanceDate: _selectedDate,
      statuses: marked,
    );

    result.when(
      success: (res) {
        if (mounted) Navigator.of(context).pop(); // close progress
        if (res.failedRecords > 0) {
          // Show failed members and allow retry via SnackBar action
          final failed = res.results.where((r) => !r.isSuccess).toList();
          final failedIds = failed.map((r) => r.userId).toList();
          final failedNames = _allMembers
              .where((m) => failedIds.contains(m.id))
              .map((m) => m.name)
              .toList();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  res.message != null && res.message!.isNotEmpty
                      ? '${res.message} | Failed: ${failedNames.join(', ')}'
                      : 'Saved with ${res.failedRecords} failed: ${failedNames.join(', ')}',
                ),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () async {
                    if (mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                    }
                    // Retry only the failed records with their intended statuses
                    final Map<String, bool> retryStatuses = {
                      for (final id in failedIds)
                        id: _attendanceStatus[id] == true,
                    };
                    final retry = await _userService.submitAttendance(
                      attendanceDate: _selectedDate,
                      statuses: retryStatuses,
                    );
                    retry.when(
                      success: (rr) {
                        if (mounted)
                          Navigator.of(context).pop(); // close progress
                        if (rr.failedRecords == 0 && mounted) {
                          setState(() {
                            _originalStatus = Map.from(_attendanceStatus);
                            _hasUnsavedChanges = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                rr.message != null && rr.message!.isNotEmpty
                                    ? rr.message!
                                    : 'All failed records saved for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                              ),
                              backgroundColor: const Color(0xFF67B437),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else if (mounted && rr.failedRecords > 0) {
                          final againFailedIds = rr.results
                              .where((r) => !r.isSuccess)
                              .map((r) => r.userId)
                              .toList();
                          final againFailedNames = _allMembers
                              .where((m) => againFailedIds.contains(m.id))
                              .map((m) => m.name)
                              .toList();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                rr.message != null && rr.message!.isNotEmpty
                                    ? '${rr.message} | Failed: ${againFailedNames.join(', ')}'
                                    : 'Some records still failed: ${againFailedNames.join(', ')}',
                              ),
                            ),
                          );
                        }
                      },
                      failure: (msg, statusCode) {
                        if (mounted)
                          Navigator.of(context).pop(); // close progress
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
                    );
                  },
                ),
              ),
            );
          }
        } else {
          // Success: baseline current state and clear unsaved flag
          setState(() {
            _originalStatus = Map.from(_attendanceStatus);
            _hasUnsavedChanges = false;
          });
          if (mounted) {
            Navigator.of(context).pop(); // close progress
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  marked.isNotEmpty &&
                          (res.message != null && res.message!.isNotEmpty)
                      ? res.message!
                      : 'Attendance saved for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                ),
                backgroundColor: const Color(0xFF67B437),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      failure: (msg, statusCode) {
        if (mounted) Navigator.of(context).pop(); // close progress
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    );
  }

  int get _presentCount =>
      _attendanceStatus.values.where((status) => status == true).length;
  int get _absentCount =>
      _attendanceStatus.values.where((status) => status == false).length;
  int get _totalActiveMembers => _allMembers.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Quick Attendance'),
        backgroundColor: const Color(0xFF67B437),
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          // Save Button
          IconButton(
            onPressed: _hasUnsavedChanges ? _saveAttendance : null,
            icon: Icon(
              Icons.save,
              color: _hasUnsavedChanges
                  ? AppTheme.white
                  : AppTheme.white.withOpacity(0.5),
            ),
            tooltip: 'Save Attendance',
          ),
        ],
      ),
      body: Column(
        children: [
          // Today's Summary Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isToday(_selectedDate)
                                ? 'Today: $_presentCount / $_totalActiveMembers'
                                : 'Attendance: $_presentCount / $_totalActiveMembers',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF67B437),
                            ),
                          ),
                          GestureDetector(
                            onTap: _selectDate,
                            child: Row(
                              children: [
                                Text(
                                  DateFormat(
                                    'EEEE, MMM dd, yyyy',
                                  ).format(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.darkGrey.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: AppTheme.darkGrey.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasUnsavedChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit,
                              color: Colors.orange,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'Unsaved',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Present',
                        _presentCount,
                        const Color(0xFF67B437),
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Absent',
                        _absentCount,
                        AppTheme.errorRed,
                        Icons.cancel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Search UMS by name or phone...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF67B437)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF67B437)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF67B437),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filter Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  'All ($_totalActiveMembers)',
                  AttendanceFilter.all,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Present ($_presentCount)',
                  AttendanceFilter.present,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Absent ($_absentCount)',
                  AttendanceFilter.absent,
                ),
              ],
            ),
          ),

          //   const SizedBox(height: 16),

          //   // Bulk Actions
          //   Container(
          //     margin: const EdgeInsets.symmetric(horizontal: 16),
          //     child: Row(
          //       children: [
          //         Expanded(
          //           child: ElevatedButton.icon(
          //             onPressed: _markAllPresent,
          //             icon: const Icon(Icons.check_circle, size: 18),
          //             label: const Text('Mark All Present'),
          //             style: ElevatedButton.styleFrom(
          //               backgroundColor: const Color(0xFF67B437),
          //               foregroundColor: AppTheme.white,
          //               padding: const EdgeInsets.symmetric(vertical: 12),
          //             ),
          //           ),
          //         ),
          //         const SizedBox(width: 12),
          //         Expanded(
          //           child: ElevatedButton.icon(
          //             onPressed: _markAllAbsent,
          //             icon: const Icon(Icons.cancel, size: 18),
          //             label: const Text('Mark All Absent'),
          //             style: ElevatedButton.styleFrom(
          //               backgroundColor: AppTheme.errorRed,
          //               foregroundColor: AppTheme.white,
          //               padding: const EdgeInsets.symmetric(vertical: 12),
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          const SizedBox(height: 16),

          // Members List
          Expanded(
            child: (_isLoading && _allMembers.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : (_filteredMembers.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount:
                              _filteredMembers.length +
                              ((_isLoadingMore || _hasMore) ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _filteredMembers.length) {
                              return _buildListFooter();
                            }
                            final member = _filteredMembers[index];
                            final attendanceStatus =
                                _attendanceStatus[member.id];
                            return _buildMemberCard(member, attendanceStatus);
                          },
                        )),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 3),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AttendanceFilter filter) {
    bool isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
        _applyFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF67B437) : AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF67B437)
                : AppTheme.darkGrey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.white : AppTheme.darkGrey,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(Member member, bool? attendanceStatus) {
    // Ensure every member has a status - fallback to Present if null
    final status = attendanceStatus ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Member Avatar
            CircleAvatar(
              backgroundColor: status
                  ? const Color(0xFF67B437)
                  : AppTheme.errorRed,
              child: Text(
                member.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.mobileNumber,
                    style: TextStyle(
                      color: AppTheme.darkGrey.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Attendance Radio Buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Present Radio
                GestureDetector(
                  onTap: () => _toggleAttendance(member, true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<bool?>(
                        value: true,
                        groupValue: status,
                        onChanged: (value) => _toggleAttendance(member, true),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        activeColor: const Color(0xFF67B437),
                      ),
                      Text(
                        'Present',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: status
                              ? const Color(0xFF67B437)
                              : AppTheme.darkGrey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Absent Radio
                GestureDetector(
                  onTap: () => _toggleAttendance(member, false),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<bool?>(
                        value: false,
                        groupValue: status,
                        onChanged: (value) => _toggleAttendance(member, false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        activeColor: AppTheme.errorRed,
                      ),
                      Text(
                        'Absent',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: !status
                              ? AppTheme.errorRed
                              : AppTheme.darkGrey.withOpacity(0.7),
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
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    if (_searchController.text.isNotEmpty) {
      message = 'No UMS found';
      subtitle = 'Try searching with a different name or phone number';
      icon = Icons.search_off;
    } else {
      switch (_currentFilter) {
        case AttendanceFilter.present:
          message = 'No members marked present';
          subtitle = 'Mark members as present to see them here';
          icon = Icons.check_circle_outline;
          break;
        case AttendanceFilter.absent:
          message = 'No members marked absent';
          subtitle = 'Mark members as absent to see them here';
          icon = Icons.cancel_outlined;
          break;
        case AttendanceFilter.all:
          message = 'No UMS found';
          subtitle = 'Check your UMS database';
          icon = Icons.people_outline;
          break;
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.darkGrey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.darkGrey.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.darkGrey.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListFooter() {
    // Footer shown when loading more or when more pages are available
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () {
              _fetchMembers(reset: false).then((_) => _applyFilter());
            },
            icon: const Icon(Icons.expand_more),
            label: const Text('Load more'),
          ),
        ),
      );
    }
    return const SizedBox(height: 12);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
