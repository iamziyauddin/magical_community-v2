import 'dart:async';
import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/data/services/user_service.dart';
import 'package:magical_community/models/user_model.dart';
import 'package:magical_community/data/models/coach_model.dart';
import 'package:magical_community/screens/users/add_user_screen.dart';
import 'package:magical_community/screens/users/visitor_detail_screen.dart';
import 'package:magical_community/screens/users/unified_user_detail_screen.dart';
import 'package:magical_community/widgets/subscription_dialog.dart';

// Unified list classification for generic user searches (UMS, Trials, Visitors)
enum UserListType { members, trials, visitors }

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();

  // Unified API data using UserModel
  List<UserModel> _allUsers = [];
  List<UserModel> _members = [];
  List<UserModel> _trials = [];

  // UMS state
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshingMembers = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String? _errorMessage;
  bool _membersActiveOnly = true;
  int _totalMembersCount = 0; // Total count from API meta.total

  // Visitors state
  List<UserModel> _allVisitors = [];
  List<UserModel> _visitors = [];
  bool _isLoadingVisitors = false;
  bool _isLoadingMoreVisitors = false;
  bool _isRefreshingVisitors = false;
  int _visitorsPage = 1;
  bool _hasMoreVisitors = true;
  DateTime? _visitorStartDate;
  DateTime? _visitorEndDate;
  int _totalVisitorsCount = 0; // Total count from API meta.total

  // Trials state
  bool _isLoadingTrials = false;
  bool _isLoadingMoreTrials = false;
  bool _isRefreshingTrials = false;
  int _trialsPage = 1;
  bool _hasMoreTrials = true;
  bool _trialsActiveOnly = true;
  int _totalTrialsCount = 0; // Total count from API meta.total

  // Coaches state
  List<UserModel> _coachesFromAPI = [];
  List<UserModel> _seniorCoachesFromAPI = [];
  bool _isLoadingCoaches = false;
  bool _isLoadingMoreCoaches = false;
  bool _isRefreshingCoaches = false;
  int _coachesPage = 1;
  bool _hasMoreCoaches = true;
  bool _showSeniorCoaches = false;
  bool _isLoadingSeniorCoaches = false;
  bool _isLoadingMoreSeniorCoaches = false;
  bool _isRefreshingSeniorCoaches = false;
  int _seniorCoachesPage = 1;
  bool _hasMoreSeniorCoaches = true;
  int _totalCoachesCount = 0; // Total count from API meta.total
  int _totalSeniorCoachesCount = 0; // Total count from API meta.total
  bool _coachesActiveOnly = true; // Filter for coaches active/inactive
  bool _seniorCoachesActiveOnly =
      true; // Filter for senior coaches active/inactive (independent)

  // Search state variables
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  bool _isSearching = false;
  String _currentSearchQuery = '';
  bool _isSearchExpanded = false;

  // Search results for each tab
  List<UserModel> _searchResultsMembers = [];
  List<UserModel> _searchResultsVisitors = [];
  List<UserModel> _searchResultsTrials = [];
  List<UserModel> _searchResultsCoaches = [];
  List<UserModel> _searchResultsSeniorCoaches = [];

  String get _visitorFilterLabel {
    String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
    if (_visitorStartDate != null && _visitorEndDate != null) {
      if (_visitorStartDate!.year == _visitorEndDate!.year &&
          _visitorStartDate!.month == _visitorEndDate!.month &&
          _visitorStartDate!.day == _visitorEndDate!.day) {
        return 'Date: ${fmt(_visitorStartDate!)}';
      }
      return 'Range: ${fmt(_visitorStartDate!)} - ${fmt(_visitorEndDate!)}';
    }
    return 'All dates';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _tabController.previousIndex) {
        // If search input is open but empty, close it when tab changes
        if (_isSearchExpanded && _searchController.text.isEmpty) {
          _isSearchExpanded = false;
        }

        // If there's an active search query, perform search for the new tab
        if (_currentSearchQuery.isNotEmpty) {
          _performSearch(_currentSearchQuery);
        }

        // Load coaches data when switching to coaches tab only if not already loaded
        if (_tabController.index == 1) {
          // Coaches tab - load data only if not already loaded
          if (!_isLoadingCoaches &&
              (_coachesFromAPI.isEmpty || _totalCoachesCount == 0)) {
            _loadCoaches();
          }
          if (!_isLoadingSeniorCoaches &&
              (_seniorCoachesFromAPI.isEmpty ||
                  _totalSeniorCoachesCount == 0)) {
            _loadSeniorCoaches();
          }
        }

        setState(() {});
      }
    });

    // Default visitors filter to today (start and end set to today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _visitorStartDate = today;
    _visitorEndDate = today;

    _loadMembers();
    _loadVisitors();
    _loadTrials();
    _loadCoaches();
    _loadSeniorCoaches();
  }

  Future<void> _loadMembers({bool loadMore = false}) async {
    if (_isLoadingMore && loadMore) return;
    if (!loadMore) {
      setState(() {
        _isLoading = !_isRefreshingMembers;
        _errorMessage = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await _userService.getUsers(
        page: loadMore ? _currentPage + 1 : 1,
        limit: 30,
        activeOnly: _membersActiveOnly,
      );

      result.when(
        success: (membersData) {
          final users = membersData.data
              .map((m) => UserModel.fromMember(m))
              .toList();
          if (loadMore) {
            _allUsers.addAll(users);
            _currentPage++;
          } else {
            _allUsers = users;
            _currentPage = 1;
            // Update total count from API meta.total
            _totalMembersCount = membersData.meta.total;
          }

          _hasMoreData = users.length >= 30;
          _categorizeUsers();

          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
          });
        },
        failure: (message, statusCode) {
          setState(() {
            _errorMessage = message;
            _isLoading = false;
            _isLoadingMore = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load UMS: ${e.toString()}';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadVisitors({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMoreVisitors || !_hasMoreVisitors) return;
      setState(() => _isLoadingMoreVisitors = true);
    } else {
      setState(() {
        _isLoadingVisitors = !_isRefreshingVisitors;
        _hasMoreVisitors = true;
        _visitorsPage = 1;
      });
    }

    try {
      final result = await _userService.getVisitorUsers(
        page: loadMore ? _visitorsPage + 1 : 1,
        limit: 30,
        activeOnly: true,
        startDate: _visitorStartDate,
        endDate: _visitorEndDate,
      );

      result.when(
        success: (membersData) {
          final users = membersData.data
              .map((m) => UserModel.fromMember(m))
              .toList();
          if (loadMore) {
            _allVisitors.addAll(users);
            _visitorsPage++;
          } else {
            _allVisitors = users;
            _visitorsPage = 1;
            // Update total count from API meta.total
            _totalVisitorsCount = membersData.meta.total;
          }

          _hasMoreVisitors = users.length >= 30;

          setState(() {
            _visitors = List.from(_allVisitors);
            _isLoadingVisitors = false;
            _isLoadingMoreVisitors = false;
          });
        },
        failure: (message, statusCode) {
          setState(() {
            _isLoadingVisitors = false;
            _isLoadingMoreVisitors = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoadingVisitors = false;
        _isLoadingMoreVisitors = false;
      });
    }
  }

  Future<void> _loadTrials({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMoreTrials || !_hasMoreTrials) return;
      setState(() => _isLoadingMoreTrials = true);
    } else {
      setState(() {
        _isLoadingTrials = true;
        _hasMoreTrials = true;
        _trialsPage = 1;
      });
    }

    try {
      final result = await _userService.getTrialUsers(
        page: loadMore ? _trialsPage + 1 : 1,
        limit: 30,
        activeOnly: _trialsActiveOnly,
      );

      result.when(
        success: (membersData) {
          final users = membersData.data
              .map((m) => UserModel.fromMember(m))
              .toList();
          setState(() {
            if (loadMore) {
              _trials.addAll(users);
              _trialsPage++;
              _isLoadingMoreTrials = false;
            } else {
              _trials = users;
              _trialsPage = 1;
              _isLoadingTrials = false;
              // Update total count from API meta.total
              _totalTrialsCount = membersData.meta.total;
            }
            _hasMoreTrials = users.length >= 30;
          });
        },
        failure: (message, statusCode) {
          setState(() {
            _isLoadingTrials = false;
            _isLoadingMoreTrials = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoadingTrials = false;
        _isLoadingMoreTrials = false;
      });
    }
  }

  Future<void> _loadCoaches({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMoreCoaches || !_hasMoreCoaches) return;
      setState(() => _isLoadingMoreCoaches = true);
    } else {
      setState(() => _isLoadingCoaches = !_isRefreshingCoaches);
      _coachesPage = 1;
      _hasMoreCoaches = true;
    }

    try {
      final result = await _userService.getCoachUsers(
        page: loadMore ? _coachesPage + 1 : 1,
        limit: 30,
        includeInactive: !_coachesActiveOnly,
        memberRole: 'coach',
      );

      result.when(
        success: (membersData) {
          final users = membersData.data
              .map((m) => UserModel.fromMember(m))
              .toList();
          setState(() {
            if (loadMore) {
              _coachesFromAPI.addAll(users);
              _isLoadingMoreCoaches = false;
              _coachesPage += 1;
            } else {
              _coachesFromAPI = users;
              _isLoadingCoaches = false;
              _coachesPage = 1;
              // Update total count from API meta.total
              _totalCoachesCount = membersData.meta.total;
            }
            // Since we're getting a list directly, estimate pagination
            _hasMoreCoaches = users.length >= 30;
          });
        },
        failure: (message, statusCode) {
          setState(() {
            if (loadMore) {
              _isLoadingMoreCoaches = false;
            } else {
              _isLoadingCoaches = false;
            }
          });
        },
      );
    } catch (e) {
      setState(() {
        if (loadMore) {
          _isLoadingMoreCoaches = false;
        } else {
          _isLoadingCoaches = false;
        }
      });
    }
  }

  Future<void> _loadSeniorCoaches({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMoreSeniorCoaches || !_hasMoreSeniorCoaches) return;
      setState(() => _isLoadingMoreSeniorCoaches = true);
    } else {
      setState(() => _isLoadingSeniorCoaches = !_isRefreshingSeniorCoaches);
      _seniorCoachesPage = 1;
      _hasMoreSeniorCoaches = true;
    }

    try {
      final result = await _userService.getCoachUsers(
        page: loadMore ? _seniorCoachesPage + 1 : 1,
        limit: 30,
        includeInactive: !_seniorCoachesActiveOnly,
        memberRole: 'senior_coach',
      );

      result.when(
        success: (membersData) {
          final users = membersData.data
              .map((m) => UserModel.fromMember(m))
              .toList();
          setState(() {
            if (loadMore) {
              _seniorCoachesFromAPI.addAll(users);
              _isLoadingMoreSeniorCoaches = false;
              _seniorCoachesPage += 1;
            } else {
              _seniorCoachesFromAPI = users;
              _isLoadingSeniorCoaches = false;
              _seniorCoachesPage = 1;
              // Update total count from API meta.total
              _totalSeniorCoachesCount = membersData.meta.total;
            }
            // Since we're getting a list directly, estimate pagination
            _hasMoreSeniorCoaches = users.length >= 30;
          });
        },
        failure: (message, statusCode) {
          setState(() {
            if (loadMore) {
              _isLoadingMoreSeniorCoaches = false;
            } else {
              _isLoadingSeniorCoaches = false;
            }
          });
        },
      );
    } catch (e) {
      setState(() {
        if (loadMore) {
          _isLoadingMoreSeniorCoaches = false;
        } else {
          _isLoadingSeniorCoaches = false;
        }
      });
    }
  }

  void _categorizeUsers() {
    _members = List.from(_allUsers);
  }

  // Unified refresh after membership-related changes (upgrade/renew/convert)
  Future<void> _refreshAfterMembershipChange() async {
    _currentPage = 1;
    _trialsPage = 1;
    _visitorsPage = 1;
    await Future.wait([_loadMembers(), _loadTrials(), _loadVisitors()]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  // Search functionality
  void _onSearchChanged(String query) {
    _searchTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _currentSearchQuery = '';
        _isSearchExpanded = false; // Collapse search when empty
        _clearSearchResults();
      });
      return;
    }

    if (query.length < 3) {
      return; // Don't search for queries less than 3 characters
    }

    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && query == _searchController.text) {
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      _isSearching = true;
      _currentSearchQuery = query;
    });

    // Perform search based on current tab
    switch (_tabController.index) {
      case 0: // UMS tab
        _searchMembers(query);
        break;
      case 1: // Coaches tab
        if (_showSeniorCoaches) {
          _searchSeniorCoaches(query);
        } else {
          _searchCoaches(query);
        }
        break;
      case 2: // Trials tab
        _searchTrials(query);
        break;
      case 3: // Visitors tab
        _searchVisitors(query);
        break;
    }
  }

  UserModel _createUserModelFromJson(Map<String, dynamic> json) {
    // API now returns a unified shape; prefer member parser, fallback to coach.
    try {
      return UserModel.fromMemberJson(json);
    } catch (_) {
      return UserModel.fromCoachJson(json);
    }
  }

  // Apply search results to proper list & stop searching state
  void _applySearchResults(UserListType type, List<UserModel> users) {
    setState(() {
      switch (type) {
        case UserListType.members:
          _searchResultsMembers = users;
          break;
        case UserListType.trials:
          _searchResultsTrials = users;
          break;
        case UserListType.visitors:
          _searchResultsVisitors = users;
          break;
      }
      _isSearching = false;
    });
  }

  // Unified generic search for members / trials / visitors
  Future<void> _searchUsers(UserListType type, String query) async {
    try {
      final activeOnly = switch (type) {
        UserListType.members => _membersActiveOnly,
        UserListType.trials => _trialsActiveOnly,
        UserListType.visitors => false,
      };

      final result = await _userService.filterUsers(
        search: query,
        page: 1,
        limit: 50,
        activeOnly: activeOnly,
        startDate: type == UserListType.visitors ? _visitorStartDate : null,
        endDate: type == UserListType.visitors ? _visitorEndDate : null,
      );
      result.when(
        success: (userMaps) {
          final users = userMaps.map(_createUserModelFromJson).toList();
          _applySearchResults(type, users);
        },
        failure: (msg, code) => _applySearchResults(type, const []),
      );
    } catch (_) {
      _applySearchResults(type, const []);
    }
  }

  // Backward compatible wrappers (other code still calls these)
  Future<void> _searchMembers(String query) =>
      _searchUsers(UserListType.members, query);
  Future<void> _searchVisitors(String query) =>
      _searchUsers(UserListType.visitors, query);
  Future<void> _searchTrials(String query) =>
      _searchUsers(UserListType.trials, query);

  Future<void> _searchCoaches(String query) async {
    try {
      final result = await _userService.getCoaches(
        page: 1,
        limit: 50,
        includeInactive: true,
        memberRole: 'coach',
        search: query,
      );

      result.when(
        success: (data) {
          final users = data.coaches
              .map((coach) => UserModel.fromCoach(coach))
              .toList();
          setState(() {
            _searchResultsCoaches = users;
            _isSearching = false;
          });
        },
        failure: (message, statusCode) {
          setState(() {
            _searchResultsCoaches = [];
            _isSearching = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _searchResultsCoaches = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _searchSeniorCoaches(String query) async {
    try {
      final result = await _userService.getCoachUsers(
        page: 1,
        limit: 50,
        includeInactive: true,
        memberRole: 'senior_coach',
        search: query,
      );

      result.when(
        success: (membersData) {
          final users = membersData.data
              .map((m) => UserModel.fromMember(m))
              .toList();
          setState(() {
            _searchResultsSeniorCoaches = users;
            _isSearching = false;
          });
        },
        failure: (message, statusCode) {
          setState(() {
            _searchResultsSeniorCoaches = [];
            _isSearching = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _searchResultsSeniorCoaches = [];
        _isSearching = false;
      });
    }
  }

  void _clearSearchResults() {
    _searchResultsMembers.clear();
    _searchResultsVisitors.clear();
    _searchResultsTrials.clear();
    _searchResultsCoaches.clear();
    _searchResultsSeniorCoaches.clear();
  }

  List<UserModel> _getCurrentMembersList() {
    if (_currentSearchQuery.isNotEmpty && !_isSearching) {
      return _searchResultsMembers;
    }
    return _members;
  }

  List<UserModel> _getCurrentVisitorsList() {
    if (_currentSearchQuery.isNotEmpty && !_isSearching) {
      return _searchResultsVisitors;
    }
    return _visitors;
  }

  List<UserModel> _getCurrentTrialsList() {
    // print(
    //   'DEBUG: _getCurrentTrialsList called - _currentSearchQuery: "$_currentSearchQuery", _isSearching: $_isSearching',
    // );
    if (_currentSearchQuery.isNotEmpty && !_isSearching) {
      // print(
      //   'DEBUG: _getCurrentTrialsList returning search results: ${_searchResultsTrials.length}',
      // );
      return _searchResultsTrials;
    }
    // print('DEBUG: _getCurrentTrialsList returning _trials: ${_trials.length}');
    return _trials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Users Management'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          if (_tabController.index == 0) _buildUMSFilterAction(),
          if (_tabController.index == 1) _buildCoachFilterAction(),
          if (_tabController.index == 2) _buildTrialFilterAction(),
          if (_tabController.index == 3) _buildVisitorFilterAction(),
          // Search icon when not expanded
          if (!_isSearchExpanded)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearchExpanded = true;
                });
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isSearchExpanded ? 110 : 50),
          child: Column(
            children: [
              // Search bar - only show when expanded
              if (_isSearchExpanded)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(
                        color: AppTheme.white.withOpacity(0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.white.withOpacity(0.6),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppTheme.white.withOpacity(0.6),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.close,
                                color: AppTheme.white.withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSearchExpanded = false;
                                });
                              },
                            ),
                      filled: true,
                      fillColor: AppTheme.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: AppTheme.white),
                  ),
                ),
              // Tab bar
              TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {}),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.star),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('UMS', style: TextStyle(fontSize: 12)),
                        Text(
                          '$_totalMembersCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    icon: const Icon(Icons.fitness_center),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Coaches', style: TextStyle(fontSize: 12)),
                        Text(
                          '${_totalCoachesCount + _totalSeniorCoachesCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    icon: const Icon(Icons.schedule),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Trials', style: TextStyle(fontSize: 12)),
                        Text(
                          '$_totalTrialsCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    icon: const Icon(Icons.people),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Visitors', style: TextStyle(fontSize: 12)),
                        Text(
                          '$_totalVisitorsCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                indicatorColor: AppTheme.accentYellow,
                labelColor: AppTheme.accentYellow,
                unselectedLabelColor: AppTheme.white.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _TabContentWrapper(child: _buildMembersTab()),
          _TabContentWrapper(child: _buildCoachesTab()),
          _TabContentWrapper(child: _buildTrialsTab()),
          _TabContentWrapper(child: _buildVisitorsTab()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUserScreen()),
          );
          if (result is Map && result['userAdded'] == true) {
            if (!mounted) return;
            await Future.wait([
              _loadMembers(),
              _loadTrials(),
              _loadVisitors(),
              _loadCoaches(),
              _loadSeniorCoaches(),
            ]);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User added. Lists refreshed.'),
                  backgroundColor: AppTheme.successGreen,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
        backgroundColor: AppTheme.accentYellow,
        // Add visible plus icon
        child: const Icon(Icons.add, color: AppTheme.white),
      ),
    );
  }

  Widget _buildMembersTab() {
    return RefreshIndicator(
      onRefresh: () async {
        if (mounted) setState(() => _isRefreshingMembers = true);
        try {
          await _loadMembers();
        } finally {
          if (mounted) setState(() => _isRefreshingMembers = false);
        }
      },
      child: _isLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              children: const [
                SizedBox(height: 16),
                Center(child: CircularProgressIndicator()),
                SizedBox(height: 8),
                Center(child: Text('Loading UMS...')),
              ],
            )
          : (_errorMessage != null)
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 32),
                Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  'Error loading data',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.darkGrey),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _loadMembers(),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            )
          : (_getCurrentMembersList().isEmpty)
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(48),
              children: [
                const SizedBox(height: 16),
                Icon(Icons.people_outline, size: 64, color: AppTheme.darkGrey),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _isSearching || _currentSearchQuery.isNotEmpty
                        ? 'No users found for "${_currentSearchQuery}"'
                        : 'No UMS found',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _isSearching
                  ? 1 // Show loading indicator
                  : (_currentSearchQuery.isNotEmpty
                        ? _searchResultsMembers.length
                        : _members.length +
                              ((_hasMoreData && !_isRefreshingMembers)
                                  ? 1
                                  : 0)),
              itemBuilder: (context, index) {
                if (_isSearching) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (_currentSearchQuery.isNotEmpty) {
                  // Show search results
                  final member = _searchResultsMembers[index];
                  return _buildMemberCardWithAPI(member, index);
                } else {
                  // Show normal list with load more functionality
                  final showLoadMore = _hasMoreData && !_isRefreshingMembers;
                  if (showLoadMore && index == _members.length) {
                    return _buildLoadMoreButton();
                  }
                  final member = _members[index];
                  return _buildMemberCardWithAPI(member, index);
                }
              },
            ),
    );
  }

  Widget _buildTrialsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        if (mounted) setState(() => _isRefreshingTrials = true);
        try {
          await _loadTrials();
        } finally {
          if (mounted) setState(() => _isRefreshingTrials = false);
        }
      },
      child: _isLoadingTrials
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              children: const [
                SizedBox(height: 16),
                Center(child: CircularProgressIndicator()),
                SizedBox(height: 8),
                Center(child: Text('Loading trials...')),
              ],
            )
          : (_errorMessage != null)
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 32),
                Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Error loading data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _errorMessage ?? 'Unknown error occurred',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.darkGrey),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _loadTrials(),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            )
          : (_getCurrentTrialsList().isEmpty)
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(48),
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppTheme.darkGrey,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _isSearching || _currentSearchQuery.isNotEmpty
                        ? 'No trial members found for "${_currentSearchQuery}"'
                        : 'No trial members found',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _isSearching
                  ? 1 // Show loading indicator
                  : (_currentSearchQuery.isNotEmpty
                        ? _searchResultsTrials.length
                        : _trials.length +
                              ((_hasMoreTrials && !_isRefreshingTrials)
                                  ? 1
                                  : 0)),
              itemBuilder: (context, index) {
                if (_isSearching) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (_currentSearchQuery.isNotEmpty) {
                  // Show search results
                  final trial = _searchResultsTrials[index];
                  return _buildTrialCardFromAPI(trial, index);
                } else {
                  // Show normal list with load more functionality
                  final showLoadMore = _hasMoreTrials && !_isRefreshingTrials;
                  if (showLoadMore && index == _trials.length) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: _isLoadingMoreTrials
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () => _loadTrials(loadMore: true),
                              child: const Text('Load More Trials'),
                            ),
                    );
                  }
                  final trial = _trials[index];
                  return _buildTrialCardFromAPI(trial, index);
                }
              },
            ),
    );
  }

  Widget _buildVisitorsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        if (mounted) setState(() => _isRefreshingVisitors = true);
        try {
          await _loadVisitors();
        } finally {
          if (mounted) setState(() => _isRefreshingVisitors = false);
        }
      },
      child: _isLoadingVisitors
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              children: const [
                SizedBox(height: 16),
                Center(child: CircularProgressIndicator()),
                SizedBox(height: 8),
                Center(child: Text('Loading visitors...')),
              ],
            )
          : (_getCurrentVisitorsList().isEmpty)
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(48),
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppTheme.darkGrey,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _isSearching || _currentSearchQuery.isNotEmpty
                        ? 'No visitors found for "${_currentSearchQuery}"'
                        : 'No visitors found',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _isSearching
                  ? 1 // Show loading indicator
                  : (_currentSearchQuery.isNotEmpty
                        ? _searchResultsVisitors.length
                        : _visitors.length +
                              ((_hasMoreVisitors && !_isRefreshingVisitors)
                                  ? 1
                                  : 0)),
              itemBuilder: (context, index) {
                if (_isSearching) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (_currentSearchQuery.isNotEmpty) {
                  // Show search results
                  final visitor = _searchResultsVisitors[index];
                  return _buildVisitorCardFromAPI(visitor, index);
                } else {
                  // Show normal list with load more functionality
                  final showLoadMoreVisitors =
                      _hasMoreVisitors && !_isRefreshingVisitors;
                  if (showLoadMoreVisitors && index == _visitors.length) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: _isLoadingMoreVisitors
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () => _loadVisitors(loadMore: true),
                              child: const Text('Load More Visitors'),
                            ),
                    );
                  }
                  final visitor = _visitors[index];
                  return _buildVisitorCardFromAPI(visitor, index);
                }
              },
            ),
    );
  }

  // UMS filter action for app bar (Active/Inactive)
  Widget _buildUMSFilterAction() {
    return PopupMenuButton<bool>(
      icon: Icon(
        Icons.filter_alt,
        color: _membersActiveOnly ? AppTheme.white : AppTheme.accentYellow,
      ),
      tooltip: 'Filter UMS',
      onSelected: (bool value) async {
        if (value == _membersActiveOnly) return;
        setState(() => _membersActiveOnly = value);
        await _loadMembers();
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<bool>(
          value: true,
          child: Row(
            children: [
              Icon(
                _membersActiveOnly
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: _membersActiveOnly
                    ? AppTheme.successGreen
                    : AppTheme.darkGrey,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Active Members'),
            ],
          ),
        ),
        PopupMenuItem<bool>(
          value: false,
          child: Row(
            children: [
              Icon(
                !_membersActiveOnly
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: !_membersActiveOnly
                    ? AppTheme.successGreen
                    : AppTheme.darkGrey,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Expired Members'),
            ],
          ),
        ),
      ],
    );
  }

  // Coach filter action for app bar (Active/Inactive)
  Widget _buildCoachFilterAction() {
    // Use the appropriate filter variable based on current tab
    final bool currentActiveOnly = _showSeniorCoaches
        ? _seniorCoachesActiveOnly
        : _coachesActiveOnly;

    return PopupMenuButton<bool>(
      icon: Icon(
        Icons.filter_alt,
        color: currentActiveOnly ? AppTheme.white : AppTheme.accentYellow,
      ),
      tooltip: _showSeniorCoaches ? 'Filter Senior Coaches' : 'Filter Coaches',
      onSelected: (bool value) async {
        if (value == currentActiveOnly) return;

        // Update the appropriate filter variable
        if (_showSeniorCoaches) {
          setState(() => _seniorCoachesActiveOnly = value);
          await _loadSeniorCoaches();
        } else {
          setState(() => _coachesActiveOnly = value);
          await _loadCoaches();
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<bool>(
          value: true,
          child: Row(
            children: [
              Icon(
                currentActiveOnly
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: currentActiveOnly
                    ? AppTheme.successGreen
                    : AppTheme.darkGrey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _showSeniorCoaches ? 'Active Senior Coaches' : 'Active Coaches',
              ),
            ],
          ),
        ),
        PopupMenuItem<bool>(
          value: false,
          child: Row(
            children: [
              Icon(
                !currentActiveOnly
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: !currentActiveOnly
                    ? AppTheme.successGreen
                    : AppTheme.darkGrey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _showSeniorCoaches
                    ? 'Expired Senior Coaches'
                    : 'Expired Coaches',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Segmented control style toggle
  Widget _buildCoachInlineToggle() {
    final segments = [
      _CoachSegment(
        active: !_showSeniorCoaches,
        label: 'Coaches',
        count: _totalCoachesCount,
        icon: Icons.fitness_center,
        activeColor: AppTheme.successGreen,
        onTap: () {
          if (_showSeniorCoaches) {
            setState(() {
              _showSeniorCoaches = false;
              // Keep senior list intact; do not clear.
            });
          }
        },
      ),
      _CoachSegment(
        active: _showSeniorCoaches,
        label: 'Senior',
        count: _totalSeniorCoachesCount,
        icon: Icons.star,
        activeColor: AppTheme.accentYellow,
        onTap: () {
          if (!_showSeniorCoaches) {
            setState(() {
              _showSeniorCoaches = true;
              if ((_seniorCoachesFromAPI.isEmpty ||
                      _totalSeniorCoachesCount == 0) &&
                  !_isLoadingSeniorCoaches) {
                _loadSeniorCoaches();
              }
            });
          }
        },
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.darkGrey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            for (int i = 0; i < segments.length; i++) ...[
              Expanded(child: segments[i]),
              if (i < segments.length - 1)
                Container(
                  width: 1,
                  height: 34,
                  color: AppTheme.darkGrey.withOpacity(0.15),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // (State class continues below with more methods)

  // Trials filter action for app bar (Active/Inactive)
  Widget _buildTrialFilterAction() {
    return PopupMenuButton<bool>(
      icon: Icon(
        Icons.filter_alt,
        color: _trialsActiveOnly ? AppTheme.white : AppTheme.accentYellow,
      ),
      tooltip: 'Filter Trials',
      onSelected: (bool value) async {
        if (value == _trialsActiveOnly) return;
        setState(() => _trialsActiveOnly = value);
        await _loadTrials();
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<bool>(
          value: true,
          child: Row(
            children: [
              Icon(
                _trialsActiveOnly
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: _trialsActiveOnly
                    ? AppTheme.successGreen
                    : AppTheme.darkGrey,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Active Trials'),
            ],
          ),
        ),
        PopupMenuItem<bool>(
          value: false,
          child: Row(
            children: [
              Icon(
                !_trialsActiveOnly
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: !_trialsActiveOnly
                    ? AppTheme.successGreen
                    : AppTheme.darkGrey,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Expired Trials'),
            ],
          ),
        ),
      ],
    );
  }

  // Visitor filter action for app bar
  Widget _buildVisitorFilterAction() {
    return PopupMenuButton<String>(
      icon: Icon(
        // Use a calendar icon to reflect date-based filtering instead of generic filter
        Icons.calendar_month,
        color: (_visitorStartDate != null || _visitorEndDate != null)
            ? AppTheme.accentYellow
            : AppTheme.white,
      ),
      tooltip: 'Filter Visitors by Date',
      onSelected: (String value) async {
        switch (value) {
          case 'single_date':
            await _selectSingleDate();
            break;
          case 'date_range':
            await _selectDateRange();
            break;
          case 'clear_filter':
            await _clearDateFilter();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'single_date',
          child: Row(
            children: [
              Icon(Icons.today, color: AppTheme.darkGrey, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Single Date',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Pick a specific date',
                      style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'date_range',
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: AppTheme.darkGrey, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Date Range',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Pick start and end dates',
                      style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'clear_filter',
          child: Row(
            children: [
              Icon(Icons.clear, color: AppTheme.errorRed, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Clear Filter',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Filter:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGrey.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _visitorFilterLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for visitor date filtering
  Future<void> _selectSingleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitorStartDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        final d = DateTime(picked.year, picked.month, picked.day);
        _visitorStartDate = d;
        _visitorEndDate = d;
      });
      await _loadVisitors();
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final initialStart =
        _visitorStartDate ?? now.subtract(const Duration(days: 6));
    final initialEnd = _visitorEndDate ?? now;
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      saveText: 'Apply',
    );
    if (range != null) {
      setState(() {
        _visitorStartDate = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        _visitorEndDate = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
        );
      });
      await _loadVisitors();
    }
  }

  Future<void> _clearDateFilter() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _visitorStartDate = today;
      _visitorEndDate = today;
    });
    await _loadVisitors();
  }

  Widget _buildCoachesTab() {
    // Always show toggle at top; below that show appropriate body
    return RefreshIndicator(
      onRefresh: () async {
        if (_showSeniorCoaches) {
          if (mounted) setState(() => _isRefreshingSeniorCoaches = true);
          try {
            await _loadSeniorCoaches();
          } finally {
            if (mounted) setState(() => _isRefreshingSeniorCoaches = false);
          }
        } else {
          if (mounted) setState(() => _isRefreshingCoaches = true);
          try {
            await _loadCoaches();
          } finally {
            if (mounted) setState(() => _isRefreshingCoaches = false);
          }
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // Toggle always visible
          _buildCoachInlineToggle(),
          const SizedBox(height: 4),
          if (_isLoadingCoaches && !_showSeniorCoaches)
            _buildInlineLoader('Loading coaches...')
          else if (_isLoadingSeniorCoaches && _showSeniorCoaches)
            _buildInlineLoader('Loading senior coaches...')
          else if (_showSeniorCoaches)
            _buildSeniorCoachesInnerList()
          else
            _buildCoachesInnerList(),
        ],
      ),
    );
  }

  // Internal list (without toggle) for regular coaches
  Widget _buildCoachesInnerList() {
    final bool showingSearch = _currentSearchQuery.isNotEmpty && !_isSearching;
    final List<UserModel> displayList = showingSearch
        ? _searchResultsCoaches
        : _coachesFromAPI;
    if (displayList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.darkGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching || _currentSearchQuery.isNotEmpty
                  ? 'No coaches found for "$_currentSearchQuery"'
                  : 'No coaches found',
              style: const TextStyle(fontSize: 18, color: AppTheme.darkGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final listLength = displayList.length;
    final extraLoader =
        (!_isSearching &&
            !showingSearch &&
            _hasMoreCoaches &&
            !_isRefreshingCoaches)
        ? 1
        : 0;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _isSearching ? 1 : listLength + extraLoader,
      itemBuilder: (context, index) {
        final adj = index;
        if (_isSearching) {
          if (adj == 0) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
        if (adj == listLength && extraLoader == 1) {
          return _buildCoachesLoadMoreButton();
        }
        final coach = displayList[adj];
        return _buildCoachCardAsMember(coach, adj);
      },
    );
  }

  // Internal list (without toggle) for senior coaches
  Widget _buildSeniorCoachesInnerList() {
    if (_isLoadingSeniorCoaches) {
      return _buildInlineLoader('Loading senior coaches...');
    }

    final bool showingSearch = _currentSearchQuery.isNotEmpty && !_isSearching;
    final List<UserModel> displayList = showingSearch
        ? _searchResultsSeniorCoaches
        : _seniorCoachesFromAPI;
    if (displayList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.darkGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching || _currentSearchQuery.isNotEmpty
                  ? 'No senior coaches found for "$_currentSearchQuery"'
                  : 'No senior coaches found',
              style: const TextStyle(fontSize: 18, color: AppTheme.darkGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final listLength = displayList.length;
    final extraLoader =
        (!_isSearching &&
            !showingSearch &&
            _hasMoreSeniorCoaches &&
            !_isRefreshingSeniorCoaches)
        ? 1
        : 0;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _isSearching ? 1 : listLength + extraLoader,
      itemBuilder: (context, index) {
        final adj = index;
        if (_isSearching) {
          if (adj == 0) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
        if (adj == listLength && extraLoader == 1) {
          return _buildSeniorCoachesLoadMoreButton();
        }
        final coach = displayList[adj];
        return _buildCoachCardAsMember(coach, adj);
      },
    );
  }

  Widget _buildInlineLoader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.darkGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachesLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: _isLoadingMoreCoaches
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: () => _loadCoaches(loadMore: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Load More Coaches'),
            ),
    );
  }

  Widget _buildSeniorCoachesLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: _isLoadingMoreSeniorCoaches
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: () => _loadSeniorCoaches(loadMore: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentYellow,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Load More Senior Coaches'),
            ),
    );
  }

  // ignore: unused_element
  Widget _buildMemberCard(UserModel member, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (context) => UnifiedUserDetailScreen(
                user: member,
                onUserUpdated: (updatedMember) {
                  final idx = _members.indexWhere(
                    (m) => m.id == updatedMember.id,
                  );
                  if (idx != -1) {
                    setState(() => _members[idx] = updatedMember);
                  }
                },
              ),
            ),
          );
          if (!mounted) return;
          if (result == true ||
              result == 'role-changed' ||
              result == 'details-updated') {
            // If role changed might move between tabs; reload all role-based lists
            await Future.wait([
              _loadMembers(),
              _loadCoaches(),
              _loadSeniorCoaches(),
            ]);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('User data refreshed.'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppTheme.white, AppTheme.successGreen.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.successGreen,
                      child: Text(
                        member.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.white,
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
                            member.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                          Text(
                            member.mobileNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkGrey.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Top-right badge: show only due amount when there are dues, otherwise show paid
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: member.pendingDues > 0
                            ? AppTheme.errorRed
                            : AppTheme.successGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member.pendingDues > 0
                            ? '₹${member.pendingDues.toInt()} Due'
                            : 'Paid',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.darkGrey.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _buildMembershipRange(
                          member.membershipStartDate,
                          member.membershipEndDate,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.darkGrey.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Show paid amount and due shakes
                Row(
                  children: [
                    // Paid amount on left
                    Text(
                      'Paid: ₹${member.totalPaid.toInt()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Due shakes on right - show if activeMembership exists
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Due Shakes: ${member.totalDueShake}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method for UMS tab using API data with improved design
  Widget _buildMemberCardWithAPI(UserModel member, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          // Navigate to member detail screen and await role update result
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (context) => UnifiedUserDetailScreen(
                user: member,
                onUserUpdated: (updatedMember) {
                  // Update the member in-place in lists
                  final idx = _members.indexWhere(
                    (m) => m.id == updatedMember.id,
                  );
                  if (idx != -1) {
                    setState(() {
                      _members[idx] = updatedMember;
                    });
                  }
                  final allIdx = _allUsers.indexWhere(
                    (u) => u.id == updatedMember.id,
                  );
                  if (allIdx != -1) {
                    setState(() {
                      _allUsers[allIdx] = updatedMember;
                    });
                  }
                },
              ),
            ),
          );
          if (result == true ||
              result == 'role-changed' ||
              result == 'details-updated') {
            await Future.wait([
              _loadMembers(),
              _loadCoaches(),
              _loadSeniorCoaches(),
            ]);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('User data refreshed.'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppTheme.white, AppTheme.successGreen.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section: Avatar, Name, Mobile, Due/Paid status
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.successGreen.withOpacity(0.15),
                      child: Text(
                        (member.firstName?.isNotEmpty == true)
                            ? member.firstName![0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.fullName,
                            style: AppTheme.userNameTextStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.phoneNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkGrey,
                              fontWeight: FontWeight.w400,
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
                        color: member.hasDues
                            ? AppTheme.errorRed
                            : AppTheme.successGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        member.hasDues
                            ? '₹${member.dueAmount.toInt()} Due'
                            : 'Paid',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Divider line
                Container(height: 1, color: AppTheme.darkGrey.withOpacity(0.1)),
                const SizedBox(height: 12),

                // Middle section: Membership dates and Days left
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Membership dates and Days left
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Membership dates row
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 16,
                                color: AppTheme.darkGrey.withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _buildMembershipRange(
                                    member.membershipStartDate,
                                    member.membershipEndDate,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Days left row
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: AppTheme.darkGrey.withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${_calculateDaysUntilExpiry(member.membershipEndDate!, startDate: member.membershipStartDate)} Days left',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right side: DueShake and Paid amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DueShake row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_drink,
                              size: 16,
                              color: AppTheme.accentYellow,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'DueShake ${member.totalDueShake}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryBlack,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Paid amount row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.currency_rupee,
                              size: 16,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Paid: ₹${member.totalPaid.toInt()}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryBlack,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCoachCard(UserModel coach) {
    // Deprecated path; keeping for reference. Use _buildCoachCardAsMember instead.
    return const SizedBox.shrink();
  }

  // ignore: unused_element
  Widget _buildTrialCard(UserModel trial, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (context) => UnifiedUserDetailScreen(
                user: trial,
                onUserUpdated: (updatedTrial) {
                  // Update the trial in-place in lists
                  final idx = _trials.indexWhere(
                    (t) => t.id == updatedTrial.id,
                  );
                  if (idx != -1) {
                    setState(() {
                      _trials[idx] = updatedTrial;
                    });
                  }
                  final allIdx = _allUsers.indexWhere(
                    (u) => u.id == updatedTrial.id,
                  );
                  if (allIdx != -1) {
                    setState(() {
                      _allUsers[allIdx] = updatedTrial;
                    });
                  }
                },
              ),
            ),
          );
          if (!mounted) return;
          if (result == true ||
              result == 'details-updated' ||
              result == 'role-changed') {
            await _refreshAfterMembershipChange();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Trial user refreshed.'),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppTheme.white, AppTheme.accentYellow.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.accentYellow,
                      child: Text(
                        trial.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryBlack,
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
                            trial.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                          Text(
                            trial.mobileNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkGrey.withOpacity(0.8),
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
                        color: trial.hasDues
                            ? AppTheme.errorRed
                            : AppTheme.successGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trial.hasDues
                            ? '₹${trial.dueAmount.toInt()} Due'
                            : 'Paid',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppTheme.darkGrey.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ends: ${trial.trialEndDate != null ? _formatDate(trial.trialEndDate!) : 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkGrey.withOpacity(0.8),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Paid: ₹${trial.totalPaid.toInt()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showUpgradeDialog(context, trial);
                        },
                        icon: const Icon(Icons.upgrade, size: 16),
                        label: const Text('Upgrade to UMS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: trial.isTrialExpired
                              ? AppTheme.accentYellow
                              : AppTheme.successGreen,
                          foregroundColor: trial.isTrialExpired
                              ? AppTheme.primaryBlack
                              : AppTheme.white,
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
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildVisitorCard(UserModel visitor, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitorDetailScreen(visitor: visitor),
            ),
          ).then((result) async {
            if (!mounted) return;
            if (result == true || result == 'details-updated') {
              await _refreshAfterMembershipChange();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Visitor refreshed.'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppTheme.white, AppTheme.darkGrey.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.darkGrey,
                      child: Text(
                        visitor.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.white,
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
                            visitor.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                          Text(
                            visitor.mobileNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkGrey.withOpacity(0.8),
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
                        color: AppTheme.darkGrey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (visitor.referredByName != null &&
                                visitor.referredByName!.isNotEmpty)
                            ? visitor.referredByName!
                            : 'Direct',
                        style: const TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: AppTheme.darkGrey.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Visited: ${_formatDate(visitor.visitDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkGrey.withOpacity(0.8),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        _showConvertVisitorDialog(context, visitor);
                      },
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Convert'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Note: Legacy Member-to-UserModel converter removed (Member type not used here).

  // Note: role string conversion not required in this screen.

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _buildMembershipRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '—';
    final startStr = start != null ? _formatDate(start) : '—';
    final endStr = end != null ? _formatDate(end) : '—';
    return '$startStr - $endStr';
  }

  // Removed old _getReferralText; list uses referredByName when available.

  void _showUpgradeDialog(BuildContext context, UserModel trial) {
    showDialog(
      context: context,
      builder: (context) => _UpgradeDialog(
        user: trial,
        onUpgrade: (membershipDuration, paymentAmount) {
          // TODO: Implement trial upgrade via API
          // _upgradeTrialToMember(trial, membershipDuration, paymentAmount);
        },
      ),
    );
  }

  void _showConvertVisitorDialog(BuildContext context, UserModel visitor) {
    showDialog(
      context: context,
      builder: (context) => _ConvertVisitorDialog(
        visitor: visitor,
        onConvert: (membershipDuration, paymentAmount) {
          // TODO: Implement visitor conversion via API
          // _convertVisitorToMember(visitor, membershipDuration, paymentAmount);
        },
      ),
    );
  }

  void _showMembershipDetailsDialog(BuildContext context, UserModel visitor) {
    final upcomingSub = visitor.upcomingSubscription;
    if (upcomingSub == null) return;

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
              Text(
                '${visitor.fullName} has an upcoming membership:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlack,
                ),
              ),
              const SizedBox(height: 16),

              // Membership Type
              _buildDetailRow(
                'Membership Type',
                (upcomingSub.membershipType ?? 'N/A').toUpperCase(),
                Icons.star,
                AppTheme.successGreen,
              ),
              const SizedBox(height: 12),

              // Total Payable
              _buildDetailRow(
                'Total Amount',
                '₹${upcomingSub.totalPayable.toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                AppTheme.infoBlue,
              ),
              const SizedBox(height: 12),

              // Amount Paid
              _buildDetailRow(
                'Amount Paid',
                '₹${upcomingSub.totalPaid.toStringAsFixed(0)}',
                Icons.payment,
                AppTheme.successGreen,
              ),
              const SizedBox(height: 12),

              // Due Amount
              if (upcomingSub.dueAmount > 0) ...[
                _buildDetailRow(
                  'Amount Due',
                  '₹${upcomingSub.dueAmount.toStringAsFixed(0)}',
                  Icons.pending_actions,
                  AppTheme.errorRed,
                ),
                const SizedBox(height: 16),
                // Container(
                //   padding: const EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: AppTheme.errorRed.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(
                //       color: AppTheme.errorRed.withOpacity(0.3),
                //     ),
                //   ),
                //   child: Row(
                //     children: [
                //       Icon(
                //         Icons.info_outline,
                //         color: AppTheme.errorRed,
                //         size: 20,
                //       ),
                //       const SizedBox(width: 8),
                //       Expanded(
                //         child: Text(
                //           'Membership will activate once the due amount is paid.',
                //           style: TextStyle(
                //             color: AppTheme.errorRed,
                //             fontSize: 12,
                //             fontWeight: FontWeight.w500,
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
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

  Widget _buildDetailRow(
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

  // TODO: These methods need to be updated to work with Member API objects
  // For now they are commented out since they use the old UserModel
  /*
  void _upgradeTrialToMember(UserModel trial, int months, double payment) {
    final now = DateTime.now();
    final updatedUser = UserModel(
      id: trial.id,
      name: trial.name,
      mobileNumber: trial.mobileNumber,
      address: trial.address,
      referredBy: trial.referredBy,
      visitDate: trial.visitDate,
      userType: UserType.member,
      membershipStartDate: now,
      membershipEndDate: now.add(Duration(days: 30 * months)),
      totalPaid: trial.totalPaid + payment,
      pendingDues: (7500.0 * months) - payment,
      role: UserRole.member,
      createdAt: trial.createdAt,
      updatedAt: now,
    );

    setState(() {
      _trials.removeWhere((t) => t.userId == trial.id);
      _members.add(updatedUser);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${trial.fullName} upgraded to UMS successfully!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _convertVisitorToMember(UserModel visitor, int months, double payment) {
    final now = DateTime.now();
    final updatedUser = UserModel(
      id: visitor.id,
      name: visitor.name,
      mobileNumber: visitor.mobileNumber,
      address: visitor.address,
      referredBy: visitor.referredBy,
      visitDate: visitor.visitDate,
      userType: UserType.member,
      membershipStartDate: now,
      membershipEndDate: now.add(Duration(days: 30 * months)),
      totalPaid: payment,
      pendingDues: (7500.0 * months) - payment,
      role: UserRole.member,
      createdAt: visitor.createdAt,
      updatedAt: now,
    );

    setState(() {
      _visitors.removeWhere((v) => v.userId == visitor.id);
      _members.add(updatedUser);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${visitor.fullName} converted to UMS successfully!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _handleMemberRoleUpdate(UserModel updatedMember) {
    setState(() {
      // Remove from original list
      _members.removeWhere((m) => m.userId == updatedMember.id);
      _coaches.removeWhere((c) => c.userId == updatedMember.id);

      // Add to appropriate list based on new role
      switch (updatedMember.role) {
        case UserRole.member:
          _members.add(updatedMember);
          break;
        case UserRole.coach:
        case UserRole.seniorCoach:
          _coaches.add(updatedMember);
          break;
      }

      // Sort lists to maintain order
      _members.sort((a, b) => a.fullName.compareTo(b.fullName));
      _coaches.sort((a, b) => a.fullName.compareTo(b.fullName));
    });

    // Show appropriate message based on role change
    String message;
    if (updatedMember.role == UserRole.member) {
      message = '${updatedMember.fullName} moved back to Members list';
    } else {
      message = '${updatedMember.fullName} promoted and moved to Coaches tab!';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.swap_horiz, color: AppTheme.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
        action: updatedMember.role != UserRole.member
            ? SnackBarAction(
                label: 'View Coaches',
                textColor: AppTheme.white,
                onPressed: () {
                  _tabController.animateTo(3); // Navigate to Coaches tab
                },
              )
            : null,
      ),
    );
  }
  */

  // Helper widgets for API integration
  // ignore: unused_element
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.darkGrey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadMembers(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppTheme.darkGrey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: AppTheme.darkGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: () => _loadMembers(loadMore: true),
              child: const Text('Load More'),
            ),
    );
  }

  Widget _buildTrialCardFromAPI(UserModel member, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (context) => UnifiedUserDetailScreen(
                user: member,
                onUserUpdated: (updatedMember) {
                  // Update the trial in-place in lists
                  final idx = _trials.indexWhere(
                    (t) => t.id == updatedMember.id,
                  );
                  if (idx != -1) {
                    setState(() {
                      _trials[idx] = updatedMember;
                    });
                  }
                  final allIdx = _allUsers.indexWhere(
                    (u) => u.id == updatedMember.id,
                  );
                  if (allIdx != -1) {
                    setState(() {
                      _allUsers[allIdx] = updatedMember;
                    });
                  }
                },
              ),
            ),
          );
          if (!mounted) return;
          if (result == true ||
              result == 'details-updated' ||
              result == 'role-changed') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Membership update successful. List refreshed.'),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
            await _loadTrials();
            await _loadMembers();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppTheme.white, AppTheme.accentYellow.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.accentYellow.withOpacity(0.2),
                      child: Icon(
                        Icons.schedule,
                        color: AppTheme.accentYellow,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.fullName,
                            style: AppTheme.userNameTextStyle,
                          ),
                          Text(
                            member.mobileNumber,
                            style: const TextStyle(
                              color: AppTheme.darkGrey,
                              fontSize: 14,
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
                        color: member.hasDues
                            ? AppTheme.errorRed
                            : AppTheme.successGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member.hasDues
                            ? '₹${member.dueAmount.toInt()} Due'
                            : 'Paid',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle section: Membership dates and Days left
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Membership dates and Days left
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Membership dates row
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 16,
                                color: AppTheme.darkGrey.withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _buildMembershipRange(
                                    member.trialStartDate ??
                                        member.membershipStartDate,
                                    member.trialEndDate ??
                                        member.membershipEndDate,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Days left row
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: AppTheme.darkGrey.withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  (member.userType == UserType.trial &&
                                              member.isExpired) ||
                                          member.isTrialExpired
                                      ? 'Trial expired'
                                      : (member.trialEndDate ??
                                                member.membershipEndDate) !=
                                            null
                                      ? '${_calculateDaysUntilExpiry(member.trialEndDate ?? member.membershipEndDate!, startDate: member.trialStartDate ?? member.membershipStartDate)} days left'
                                      : 'No end date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        ((member.userType == UserType.trial &&
                                                member.isExpired) ||
                                            member.isTrialExpired)
                                        ? AppTheme.errorRed
                                        : AppTheme.primaryBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right side: DueShake and Paid amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DueShake row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_drink,
                              size: 16,
                              color: AppTheme.accentYellow,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'DueShake ${member.totalDueShake}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryBlack,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Paid amount row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.currency_rupee,
                              size: 16,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Paid: ₹${member.totalPaid.toInt()}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryBlack,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ), // closes Container
      ), // closes InkWell
    ); // closes Card
  }

  Widget _buildVisitorCardFromAPI(UserModel member, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkGrey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlack.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (context) => VisitorDetailScreen(visitor: member),
            ),
          );
          if (!mounted) return;
          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Membership update successful. List refreshed.'),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
            await _loadVisitors();
            await _loadMembers();
          } else if (result is UserModel) {
            final updated = result;
            final idx = _visitors.indexWhere((u) => u.id == updated.id);
            if (idx != -1) {
              setState(() => _visitors[idx] = updated);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Visitor details updated.'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.darkGrey.withOpacity(0.2),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppTheme.darkGrey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.fullName,
                          style: AppTheme.userNameTextStyle,
                        ),
                        Text(
                          member.phoneNumber,
                          style: const TextStyle(
                            color: AppTheme.darkGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (member.hasUpcomingSubscription) {
                        // Show membership details dialog
                        _showMembershipDetailsDialog(context, member);
                      } else {
                        // Always allow upgrade - no membership checks
                        final screenContext = context;
                        showDialog(
                          context: context,
                          builder: (context) => SubscriptionDialog(
                            config: SubscriptionDialogConfig.visitorUpgrade(
                              userName: member.fullName,
                              onConfirm: (plan, amount, startDate) async {
                                try {
                                  if (!mounted) return;

                                  // Format the start date for API (YYYY-MM-DD)
                                  final formattedStartDate =
                                      '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

                                  final res = await _userService
                                      .renewSubscription(
                                        memberId: member.id,
                                        subscriptionPlanId: plan.id,
                                        amount: amount,
                                        startDate: formattedStartDate,
                                      );
                                  if (!mounted) return;
                                  res.when(
                                    success: (_) {
                                      ScaffoldMessenger.of(
                                        screenContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${member.fullName} upgraded to ${plan.name} with ₹${amount.toStringAsFixed(2)} payment!',
                                          ),
                                          backgroundColor:
                                              AppTheme.successGreen,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                      _loadVisitors();
                                    },
                                    failure: (message, statusCode) {
                                      ScaffoldMessenger.of(
                                        screenContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to upgrade subscription: $message',
                                          ),
                                          backgroundColor: AppTheme.errorRed,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 5),
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
                                      backgroundColor: AppTheme.errorRed,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: member.hasUpcomingSubscription
                            ? AppTheme.successGreen.withOpacity(0.1)
                            : AppTheme.accentYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: member.hasUpcomingSubscription
                              ? AppTheme.successGreen.withOpacity(0.3)
                              : AppTheme.accentYellow.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            member.hasUpcomingSubscription
                                ? 'Membership'
                                : 'Upgrade',
                            style: TextStyle(
                              color: member.hasUpcomingSubscription
                                  ? AppTheme.successGreen
                                  : AppTheme.accentYellow,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            member.hasUpcomingSubscription
                                ? Icons.card_membership
                                : Icons.arrow_drop_down,
                            color: member.hasUpcomingSubscription
                                ? AppTheme.successGreen
                                : AppTheme.accentYellow,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Middle section: Visit information
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email row
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: AppTheme.darkGrey.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                member.email ?? 'No email',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlack,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right side: Visit Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visit Date row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.darkGrey.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Visit: ${member.membershipStartDate != null ? _formatDate(member.membershipStartDate!) : _formatDate(member.visitDate)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryBlack,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to convert Coach to UserModel for using MemberDetailScreen
  // ignore: unused_element
  UserModel _convertCoachToUserModel(Coach coach) {
    return UserModel(
      id: coach.userId,
      name: coach.fullName,
      mobileNumber: coach.phoneNumber ?? '',
      address: coach.address ?? '', // May be present now
      referredBy: ReferralSource.other,
      visitDate: coach.membershipStartDate ?? DateTime.now(),
      userType: UserType.member,
      trialStartDate: null,
      trialEndDate: null,
      membershipStartDate: coach.membershipStartDate,
      membershipEndDate: coach.membershipEndDate,
      totalPaid: coach.totalPaid,
      pendingDues: coach.dueAmount,
      isActive: coach.isActive,
      notes: coach.disease,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      role: coach.memberRole == 'seniorCoach'
          ? UserRole.seniorCoach
          : coach.memberRole == 'coach'
          ? UserRole.coach
          : UserRole.member,
    );
  }

  Widget _buildCoachCardAsMember(UserModel coach, int index) {
    // For coaches converted to UserModel, we'll handle membership data differently
    final isSeniorCoach = coach.role == UserRole.seniorCoach;
    final gradientColor = isSeniorCoach
        ? AppTheme.errorRed
        : AppTheme.successGreen;
    final avatarColor = isSeniorCoach
        ? AppTheme.errorRed
        : AppTheme.successGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          // Enrich coach with phone/address from UMS list if available before navigating
          final enrichedCoach = _enrichCoachFromUMS(coach);
          final result = await Navigator.push<String?>(
            context,
            MaterialPageRoute(
              builder: (context) => UnifiedUserDetailScreen(
                user: enrichedCoach,
                onUserUpdated: (updatedMember) {
                  // Re-distribute updated member between coach/senior coach lists based on new role
                  setState(() {
                    // Remove from both lists first
                    _coachesFromAPI.removeWhere(
                      (c) => c.id == updatedMember.id,
                    );
                    _seniorCoachesFromAPI.removeWhere(
                      (c) => c.id == updatedMember.id,
                    );

                    if (updatedMember.role == UserRole.coach) {
                      _coachesFromAPI.add(updatedMember);
                    } else if (updatedMember.role == UserRole.seniorCoach) {
                      _seniorCoachesFromAPI.add(updatedMember);
                    } else {
                      // If demoted to regular member, ensure it's not lingering in coach lists
                      // (member list will be refreshed separately)
                    }

                    // Optional: sort lists alphabetically after change
                    _coachesFromAPI.sort(
                      (a, b) => a.fullName.compareTo(b.fullName),
                    );
                    _seniorCoachesFromAPI.sort(
                      (a, b) => a.fullName.compareTo(b.fullName),
                    );
                  });
                },
              ),
            ),
          );
          if (result == 'role-changed' || result == 'details-updated') {
            await Future.wait([
              _loadMembers(),
              _loadCoaches(),
              _loadSeniorCoaches(),
            ]);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('User data refreshed.'),
                  backgroundColor: AppTheme.successGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else if (result != null && result.isNotEmpty && mounted) {
            // Legacy string messages path
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result),
                backgroundColor: AppTheme.successGreen,
              ),
            );
            if (result.toLowerCase().contains('promoted')) {
              await _loadSeniorCoaches();
            } else if (result.toLowerCase().contains('demote') ||
                result.toLowerCase().contains('demoted')) {
              await _loadMembers();
            } else {
              await Future.wait([_loadCoaches(), _loadSeniorCoaches()]);
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppTheme.white, gradientColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: avatarColor,
                      child: Text(
                        coach.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.white,
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
                            coach.fullName,
                            style: AppTheme.userNameTextStyle,
                          ),
                          if (coach.phoneNumber.isNotEmpty)
                            Text(
                              coach.phoneNumber,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.darkGrey.withOpacity(0.8),
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
                        color: coach.hasDues ? AppTheme.errorRed : avatarColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        coach.hasDues
                            ? '₹${coach.dueAmount.toInt()} Due'
                            : 'Paid',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (coach.membershipStartDate != null ||
                    coach.membershipEndDate != null) ...[
                  const SizedBox(height: 12),

                  // Middle section: Membership dates and Days total
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side: Membership dates and Days total
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Membership dates row
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 16,
                                  color: AppTheme.darkGrey.withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _buildMembershipRange(
                                      coach.membershipStartDate,
                                      coach.membershipEndDate,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryBlack,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Days total row
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: AppTheme.darkGrey.withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    coach.membershipEndDate != null
                                        ? '${_calculateDaysUntilExpiry(coach.membershipEndDate!, startDate: coach.membershipStartDate)} Days left'
                                        : 'No end date',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryBlack,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right side: DueShake and Paid amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DueShake row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_drink,
                                size: 16,
                                color: AppTheme.accentYellow,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'DueShake ${coach.totalDueShake}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlack,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Paid amount row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.currency_rupee,
                                size: 16,
                                color: AppTheme.successGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Paid: ₹${coach.totalPaid.toInt()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlack,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Try to fill missing coach fields (mobile/address/disease/email) from the UMS list we already loaded
  UserModel _enrichCoachFromUMS(UserModel coach) {
    UserModel? match;
    // 1) Try by exact ID
    try {
      match = _allUsers.firstWhere((u) => u.id == coach.id);
    } catch (_) {}

    // 2) Try by phone if available
    if (match == null && coach.mobileNumber.isNotEmpty) {
      try {
        match = _allUsers.firstWhere(
          (u) => u.mobileNumber == coach.mobileNumber,
        );
      } catch (_) {}
    }

    // 3) Try by full name (case-insensitive)
    if (match == null) {
      final coachName = coach.fullName.trim().toLowerCase();
      try {
        match = _allUsers.firstWhere(
          (u) => u.fullName.trim().toLowerCase() == coachName,
        );
      } catch (_) {}
    }

    if (match == null) return coach; // No match found; return as-is

    return coach.copyWith(
      mobileNumber: (coach.mobileNumber.isEmpty
          ? match.mobileNumber
          : coach.mobileNumber),
      address: (coach.address.isEmpty ? match.address : coach.address),
      disease: (coach.disease == null || coach.disease!.isEmpty)
          ? match.disease
          : coach.disease,
      email: coach.email ?? match.email,
      firstName: coach.firstName ?? match.firstName,
      lastName: coach.lastName ?? match.lastName,
    );
  }

  // Calculate remaining days until expiry with start date consideration
  int _calculateDaysUntilExpiry(DateTime endDate, {DateTime? startDate}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    // Determine the calculation start point
    DateTime calculationStart;
    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      // If start date is in the future, use start date; otherwise use current date
      calculationStart = start.isAfter(today) ? start : today;
    } else {
      // If no start date provided, use current date (backward compatibility)
      calculationStart = today;
    }

    // Calculate days including the end date (add 1 for inclusive calculation)
    final difference = end.difference(calculationStart).inDays + 1;
    return difference > 0 ? difference : 0;
  }
}

// Wrapper widget to preserve tab state and prevent rebuilds
class _TabContentWrapper extends StatefulWidget {
  final Widget child;

  const _TabContentWrapper({required this.child});

  @override
  State<_TabContentWrapper> createState() => _TabContentWrapperState();
}

class _TabContentWrapperState extends State<_TabContentWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// Upgrade Dialog for Trial Users
class _UpgradeDialog extends StatefulWidget {
  final UserModel user;
  final Function(int months, double payment) onUpgrade;

  const _UpgradeDialog({required this.user, required this.onUpgrade});

  @override
  State<_UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<_UpgradeDialog> {
  int _selectedMonths = 1;
  double _paymentAmount = 7500.0;
  final TextEditingController _paymentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentController.text = _paymentAmount.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Upgrade ${widget.user.name} to UMS'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current Trial Status: ${widget.user.isTrialExpired ? "Expired" : "Active"}',
            style: TextStyle(
              color: widget.user.isTrialExpired
                  ? AppTheme.errorRed
                  : AppTheme.successGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedMonths,
            decoration: const InputDecoration(
              labelText: 'UMS Duration',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 Month (₹7,500)')),
              DropdownMenuItem(value: 3, child: Text('3 Months (₹22,500)')),
              DropdownMenuItem(value: 6, child: Text('6 Months (₹45,000)')),
              DropdownMenuItem(value: 12, child: Text('12 Months (₹90,000)')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMonths = value!;
                _paymentAmount = 7500.0 * _selectedMonths;
                _paymentController.text = _paymentAmount.toString();
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paymentController,
            decoration: InputDecoration(
              labelText: 'Payment Amount',
              prefixText: '₹',
              border: const OutlineInputBorder(),
              helperText: 'Total: ₹${7500.0 * _selectedMonths}',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _paymentAmount = double.tryParse(value) ?? 0.0;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onUpgrade(_selectedMonths, _paymentAmount);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successGreen,
            foregroundColor: AppTheme.white,
          ),
          child: const Text('Upgrade'),
        ),
      ],
    );
  }
}

// Convert Visitor Dialog
class _ConvertVisitorDialog extends StatefulWidget {
  final UserModel visitor;
  final Function(int months, double payment) onConvert;

  const _ConvertVisitorDialog({required this.visitor, required this.onConvert});

  @override
  State<_ConvertVisitorDialog> createState() => _ConvertVisitorDialogState();
}

class _ConvertVisitorDialogState extends State<_ConvertVisitorDialog> {
  int _selectedMonths = 1;
  double _paymentAmount = 7500.0;
  final TextEditingController _paymentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentController.text = _paymentAmount.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Convert ${widget.visitor.name} to UMS'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Visited: ${widget.visitor.visitDate.day}/${widget.visitor.visitDate.month}/${widget.visitor.visitDate.year}',
            style: const TextStyle(
              color: AppTheme.darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedMonths,
            decoration: const InputDecoration(
              labelText: 'UMS Duration',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 Month (₹7,500)')),
              DropdownMenuItem(value: 3, child: Text('3 Months (₹22,500)')),
              DropdownMenuItem(value: 6, child: Text('6 Months (₹45,000)')),
              DropdownMenuItem(value: 12, child: Text('12 Months (₹90,000)')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMonths = value!;
                _paymentAmount = 7500.0 * _selectedMonths;
                _paymentController.text = _paymentAmount.toString();
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paymentController,
            decoration: InputDecoration(
              labelText: 'Initial Payment',
              prefixText: '₹',
              border: const OutlineInputBorder(),
              helperText: 'Total: ₹${7500.0 * _selectedMonths}',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _paymentAmount = double.tryParse(value) ?? 0.0;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConvert(_selectedMonths, _paymentAmount);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successGreen,
            foregroundColor: AppTheme.white,
          ),
          child: const Text('Convert'),
        ),
      ],
    );
  }
}

// Segmented control segment widget for Coaches / Senior Coaches toggle
class _CoachSegment extends StatelessWidget {
  final bool active;
  final String label;
  final int count;
  final IconData icon;
  final Color activeColor;
  final VoidCallback onTap;
  const _CoachSegment({
    required this.active,
    required this.label,
    required this.count,
    required this.icon,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? activeColor : AppTheme.darkGrey,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$label ($count)',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? activeColor : AppTheme.darkGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
