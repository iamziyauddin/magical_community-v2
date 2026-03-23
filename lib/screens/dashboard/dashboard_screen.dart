import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/widgets/stat_card.dart';
import 'package:magical_community/data/services/user_service.dart';
import 'package:magical_community/data/models/dashboard_stats.dart';
import 'package:magical_community/data/models/attendance_view_record.dart';
import 'package:magical_community/core/network/api_result.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Cache the last fetched stats to avoid flashing zeros on tab changes
  static DashboardStats? _cachedStats;
  late AnimationController _animationController;
  final UserService _userService = UserService();
  DashboardStats? _stats;
  // All dashboard values come from API via _stats; no static fallbacks
  bool _isLoadingStats = false; // show wellness loader during first load
  bool _isRefreshing = false; // show spinner on refresh button
  DateTime _selectedAttendanceDate = DateTime.now(); // For attendance viewer
  Future<ApiResult<AttendanceViewResponse>>? _attendanceFuture;

  @override
  void initState() {
    super.initState();
    // Use cached stats immediately so UI keeps last values until API returns
    _stats = _cachedStats;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    _loadTodayStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final bool _isInitialLoading =
        _isLoadingStats && _stats == null && _cachedStats == null;
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        bottom: _isRefreshing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: AppTheme.primaryBlack,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
                  minHeight: 3,
                ),
              )
            : null,
        actions: [
          _isRefreshing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _animationController.reset();
                    _animationController.forward();
                    _loadTodayStats();
                  },
                ),
          // PopupMenuButton<String>(
          //   icon: const Icon(Icons.more_vert),
          //   onSelected: (value) {
          //     switch (value) {
          //       case 'logout':
          //         AuthUtils.showLogoutDialog(context);
          //         break;
          //     }
          //   },
          //   itemBuilder: (context) => [
          //     const PopupMenuItem(
          //       value: 'logout',
          //       child: Row(
          //         children: [
          //           Icon(Icons.logout, color: AppTheme.errorRed),
          //           SizedBox(width: 8),
          //           Text('Logout'),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
      body: _isInitialLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildWellnessLoader(),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _animationController.reset();
                _animationController.forward();
                await _loadTodayStats();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Stats Grid
                    Text(
                      'Today\'s Overview',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.primaryBlack,
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        StatCard(
                          title: 'Visitors Today',
                          value: (_stats?.todayVisitorCount ?? 0).toString(),
                          icon: Icons.people_outline,
                          color: AppTheme.infoBlue,
                          delay: 300,
                        ),
                        StatCard(
                          title: 'Trials Today',
                          value: (_stats?.todayTrialCount ?? 0).toString(),
                          icon: Icons.schedule,
                          color: AppTheme.warningOrange,
                          delay: 400,
                        ),
                        StatCard(
                          title: 'New UMS',
                          value: (_stats?.todayNewMemberCount ?? 0).toString(),
                          icon: Icons.person_add,
                          color: AppTheme.successGreen,
                          delay: 500,
                        ),
                        StatCard(
                          title: 'Total UMS',
                          // Use totalUMS directly from API response
                          value: (_stats?.totalUMS ?? 0).toString(),
                          icon: Icons.groups,
                          color: AppTheme.accentYellow,
                          delay: 600,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Shake Summary Card
                    Text(
                      'Shakes Served Today',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.primaryBlack,
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate().fadeIn(delay: 850.ms),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.infoBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_drink,
                                  color: AppTheme.infoBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🥤 Shakes Served Today',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryBlack,
                                          ),
                                    ),
                                    Text(
                                      'Total: ${(_stats?.todayMemberShakeCount ?? 0) + (_stats?.todayTrialShakeCount ?? 0)} shakes',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.darkGrey.withOpacity(
                                          0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Shake Stats Row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.successGreen.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.fitness_center,
                                        color: AppTheme.successGreen,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_stats?.todayMemberShakeCount ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.successGreen,
                                        ),
                                      ).animate().fadeIn(delay: 1000.ms).scale(),
                                      const Text(
                                        '🟢 UMS',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.successGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.infoBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.infoBlue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.sports_gymnastics,
                                        color: AppTheme.infoBlue,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_stats?.todayTrialShakeCount ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.infoBlue,
                                        ),
                                      ).animate().fadeIn(delay: 1100.ms).scale(),
                                      const Text(
                                        '🔵 Trials',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.infoBlue,
                                          fontWeight: FontWeight.w600,
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
                    ).animate().fadeIn(delay: 900.ms),

                    const SizedBox(height: 24),

                    // Attendance Chart
                    // Text(
                    //   'UMS Attendance',
                    //   style: Theme.of(context).textTheme.headlineSmall
                    //       ?.copyWith(
                    //         color: AppTheme.primaryBlack,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    // ).animate().fadeIn(delay: 700.ms),

                    // const SizedBox(height: 16),

                    // Card(
                    //   elevation: 8,
                    //   shape: RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(20),
                    //   ),
                    //   child: Container(
                    //     padding: const EdgeInsets.all(20),
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(20),
                    //       gradient: LinearGradient(
                    //         colors: [
                    //           AppTheme.white,
                    //           AppTheme.successGreen.withOpacity(0.05),
                    //         ],
                    //         begin: Alignment.topLeft,
                    //         end: Alignment.bottomRight,
                    //       ),
                    //     ),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         Row(
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           children: [
                    //             const Text(
                    //               'Today\'s Attendance',
                    //               style: TextStyle(
                    //                 fontSize: 18,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: AppTheme.primaryBlack,
                    //               ),
                    //             ),
                    //             Container(
                    //               padding: const EdgeInsets.all(8),
                    //               decoration: BoxDecoration(
                    //                 color: AppTheme.successGreen.withOpacity(
                    //                   0.1,
                    //                 ),
                    //                 borderRadius: BorderRadius.circular(8),
                    //               ),
                    //               child: const Icon(
                    //                 Icons.people,
                    //                 color: AppTheme.successGreen,
                    //                 size: 20,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //         const SizedBox(height: 20),
                    //         // Attendance Stats Row
                    //         Row(
                    //           children: [
                    //             Expanded(
                    //               child: Container(
                    //                 padding: const EdgeInsets.all(16),
                    //                 decoration: BoxDecoration(
                    //                   color: AppTheme.successGreen.withOpacity(
                    //                     0.1,
                    //                   ),
                    //                   borderRadius: BorderRadius.circular(12),
                    //                   border: Border.all(
                    //                     color: AppTheme.successGreen
                    //                         .withOpacity(0.3),
                    //                   ),
                    //                 ),
                    //                 child: Column(
                    //                   children: [
                    //                     const Icon(
                    //                       Icons.check_circle,
                    //                       color: AppTheme.successGreen,
                    //                       size: 32,
                    //                     ),
                    //                     const SizedBox(height: 8),
                    //                     Text(
                    //                       '${_stats?.todayPresentCount ?? 0}',
                    //                       style: const TextStyle(
                    //                         fontSize: 24,
                    //                         fontWeight: FontWeight.bold,
                    //                         color: AppTheme.successGreen,
                    //                       ),
                    //                     ),
                    //                     const Text(
                    //                       'Present',
                    //                       style: TextStyle(
                    //                         fontSize: 12,
                    //                         color: AppTheme.darkGrey,
                    //                         fontWeight: FontWeight.w500,
                    //                       ),
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //             ),
                    //             const SizedBox(width: 16),
                    //             Expanded(
                    //               child: Container(
                    //                 padding: const EdgeInsets.all(16),
                    //                 decoration: BoxDecoration(
                    //                   color: AppTheme.errorRed.withOpacity(0.1),
                    //                   borderRadius: BorderRadius.circular(12),
                    //                   border: Border.all(
                    //                     color: AppTheme.errorRed.withOpacity(
                    //                       0.3,
                    //                     ),
                    //                   ),
                    //                 ),
                    //                 child: Column(
                    //                   children: [
                    //                     const Icon(
                    //                       Icons.cancel,
                    //                       color: AppTheme.errorRed,
                    //                       size: 32,
                    //                     ),
                    //                     const SizedBox(height: 8),
                    //                     Text(
                    //                       '${_stats?.todayAbsentCount ?? 0}',
                    //                       style: const TextStyle(
                    //                         fontSize: 24,
                    //                         fontWeight: FontWeight.bold,
                    //                         color: AppTheme.errorRed,
                    //                       ),
                    //                     ),
                    //                     const Text(
                    //                       'Absent',
                    //                       style: TextStyle(
                    //                         fontSize: 12,
                    //                         color: AppTheme.darkGrey,
                    //                         fontWeight: FontWeight.w500,
                    //                       ),
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //         const SizedBox(height: 16),
                    //         // Attendance Rate Progress Bar
                    //         Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Row(
                    //               mainAxisAlignment:
                    //                   MainAxisAlignment.spaceBetween,
                    //               children: [
                    //                 const Text(
                    //                   'Attendance Rate',
                    //                   style: TextStyle(
                    //                     fontSize: 14,
                    //                     fontWeight: FontWeight.w600,
                    //                     color: AppTheme.darkGrey,
                    //                   ),
                    //                 ),
                    //                 Text(
                    //                   '${((((_stats?.todayPresentCount ?? 0).toDouble()) / (_stats?.todayMemberCount ?? 0).toDouble().clamp(1.0, double.maxFinite)) * 100).toInt()}%',
                    //                   style: const TextStyle(
                    //                     fontSize: 14,
                    //                     fontWeight: FontWeight.bold,
                    //                     color: AppTheme.successGreen,
                    //                   ),
                    //                 ),
                    //               ],
                    //             ),
                    //             const SizedBox(height: 8),
                    //             ClipRRect(
                    //               borderRadius: BorderRadius.circular(8),
                    //               child: LinearProgressIndicator(
                    //                 value:
                    //                     ((_stats?.todayPresentCount ?? 0)
                    //                         .toDouble()) /
                    //                     ((_stats?.todayMemberCount ?? 0)
                    //                         .toDouble()
                    //                         .clamp(1.0, double.maxFinite)),
                    //                 backgroundColor: AppTheme.errorRed
                    //                     .withOpacity(0.2),
                    //                 valueColor:
                    //                     const AlwaysStoppedAnimation<Color>(
                    //                       AppTheme.successGreen,
                    //                     ),
                    //                 minHeight: 8,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //         const SizedBox(height: 16),
                    //         // Quick Check-In and View Records Buttons
                    //         Row(
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           children: [
                    //             Expanded(
                    //               child: ElevatedButton.icon(
                    //                 onPressed: _openAttendanceRecordsSheet,
                    //                 icon: const Icon(
                    //                   Icons.fact_check,
                    //                   size: 16,
                    //                 ),
                    //                 label: const Text(
                    //                   'View Records',
                    //                   style: TextStyle(fontSize: 12),
                    //                 ),
                    //                 style: ElevatedButton.styleFrom(
                    //                   backgroundColor: AppTheme.successGreen,
                    //                   foregroundColor: Colors.white,
                    //                   padding: const EdgeInsets.symmetric(
                    //                     horizontal: 8,
                    //                     vertical: 8,
                    //                   ),
                    //                   shape: RoundedRectangleBorder(
                    //                     borderRadius: BorderRadius.circular(8),
                    //                   ),
                    //                   elevation: 2,
                    //                 ),
                    //               ),
                    //             ),
                    //             const SizedBox(width: 12),
                    //             // Expanded(
                    //             //   child: ElevatedButton.icon(
                    //             //     onPressed: () {
                    //             //       Navigator.push(
                    //             //         context,
                    //             //         MaterialPageRoute(
                    //             //           builder: (context) =>
                    //             //               const QuickAttendanceScreen(),
                    //             //         ),
                    //             //       );
                    //             //     },
                    //             //     icon: const Icon(
                    //             //       Icons.check_circle_outline,
                    //             //       size: 16,
                    //             //     ),
                    //             //     label: const Text(
                    //             //       'Quick Check-In',
                    //             //       style: TextStyle(fontSize: 12),
                    //             //     ),
                    //             //     style: ElevatedButton.styleFrom(
                    //             //       backgroundColor: const Color(0xFF67B437),
                    //             //       foregroundColor: Colors.white,
                    //             //       padding: const EdgeInsets.symmetric(
                    //             //         horizontal: 8,
                    //             //         vertical: 8,
                    //             //       ),
                    //             //       shape: RoundedRectangleBorder(
                    //             //         borderRadius: BorderRadius.circular(8),
                    //             //       ),
                    //             //       elevation: 2,
                    //             //     ),
                    //             //   ),
                    //             // ),
                    //           ],
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ).animate().fadeIn(delay: 800.ms),

                    // const SizedBox(height: 24),

                    // Weekly Overview hidden for now
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _loadTodayStats() async {
    if (!mounted) return;
    setState(() {
      // Only show full-screen loader if there is no cached or current stats
      _isLoadingStats = _stats == null && _cachedStats == null;
      _isRefreshing = true;
    });
    final result = await _userService.getTodayDashboardStats();
    if (!mounted) return;
    result.when(
      success: (stats) {
        setState(() {
          _stats = stats;
          // Update cache so subsequent visits render instantly without zeros
          _cachedStats = stats;
          _isLoadingStats = false;
          _isRefreshing = false;
        });
      },
      failure: (message, statusCode) {
        setState(() {
          _isLoadingStats = false;
          _isRefreshing = false;
        });
      },
    );
  }

  void _loadAttendanceRecords() {
    setState(() {
      _attendanceFuture = _userService.getAttendanceByDate(
        date: _selectedAttendanceDate,
      );
    });
  }

  // Weekly bar chart helper removed while Weekly Overview is hidden

  // Wellness themed loader shown during first load with no cached stats
  Widget _buildWellnessLoader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Centering today's wellness",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 16),
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
                  AppTheme.accentYellow.withOpacity(0.1),
                  AppTheme.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.self_improvement,
                    size: 40,
                    color: AppTheme.primaryBlack,
                  ),
                ).animate().scale(duration: 600.ms).then().shakeY(),
                const SizedBox(height: 12),
                const Text(
                  'Charging wellness vibes…',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  backgroundColor: AppTheme.darkGrey.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.accentYellow,
                  ),
                  minHeight: 6,
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Placeholder grid for stat cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: List.generate(4, (i) => i).map((i) {
            final baseColor = [
              AppTheme.infoBlue,
              AppTheme.warningOrange,
              AppTheme.successGreen,
              AppTheme.accentYellow,
            ][i];
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ).animate().fadeIn(delay: (200 + i * 100).ms),
                  const SizedBox(height: 12),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).animate().fadeIn(delay: (250 + i * 120).ms),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: 70,
                        height: 26,
                        decoration: BoxDecoration(
                          color: baseColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ).animate().fadeIn(delay: (300 + i * 140).ms),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _openAttendanceRecordsSheet() {
    // Initialize the attendance future
    _loadAttendanceRecords();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with date selector
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.successGreen.withOpacity(0.1),
                          AppTheme.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.fact_check,
                                color: AppTheme.successGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Attendance Records',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlack,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.lightGrey,
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Date picker chip
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: _selectedAttendanceDate,
                              firstDate: DateTime(2020, 1, 1),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme
                                        .copyWith(
                                          primary: AppTheme.successGreen,
                                        ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _selectedAttendanceDate = picked);
                              _loadAttendanceRecords();
                              Navigator.pop(ctx);
                              _openAttendanceRecordsSheet();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentYellow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: AppTheme.accentYellow.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  size: 18,
                                  color: AppTheme.primaryBlack,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(_selectedAttendanceDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlack,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: AppTheme.primaryBlack,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Records list
                  Expanded(
                    child: FutureBuilder<ApiResult<AttendanceViewResponse>>(
                      future: _attendanceFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.hourglass_empty,
                                    color: AppTheme.successGreen,
                                    size: 30,
                                  ),
                                ).animate().scale(duration: 1500.ms),
                                const SizedBox(height: 12),
                                const Text(
                                  'Loading attendance records...',
                                  style: TextStyle(color: AppTheme.darkGrey),
                                ),
                              ],
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline,
                                      size: 40,
                                      color: AppTheme.errorRed,
                                    ),
                                  ).animate().shake(),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Error Loading Records',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Unexpected error: ${snapshot.error.toString()}',
                                    style: TextStyle(
                                      color: AppTheme.darkGrey.withOpacity(0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _loadAttendanceRecords,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.errorRed,
                                      foregroundColor: AppTheme.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppTheme.darkGrey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: const Icon(
                                      Icons.inbox_outlined,
                                      size: 40,
                                      color: AppTheme.darkGrey,
                                    ),
                                  ).animate().fadeIn(duration: 600.ms),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Data',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No attendance data available',
                                    style: TextStyle(color: AppTheme.darkGrey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final result = snapshot.data!;
                        return result.when(
                          success: (resp) {
                            final records = resp.records;
                            if (records.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: AppTheme.darkGrey.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            40,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.inbox_outlined,
                                          size: 40,
                                          color: AppTheme.darkGrey,
                                        ),
                                      ).animate().fadeIn(duration: 600.ms),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No records found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryBlack,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No attendance records for ${_formatDate(_selectedAttendanceDate)}',
                                        style: TextStyle(
                                          color: AppTheme.darkGrey.withOpacity(
                                            0.8,
                                          ),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Sort records: present first, then by name
                            final sorted = [...records];
                            sorted.sort((a, b) {
                              final statusCompare = a.status.compareTo(
                                b.status,
                              );
                              if (statusCompare != 0)
                                return -statusCompare; // present first
                              final aName = (a.user?.name ?? a.userId)
                                  .toLowerCase();
                              final bName = (b.user?.name ?? b.userId)
                                  .toLowerCase();
                              return aName.compareTo(bName);
                            });

                            // Partition into present and absent lists
                            final presentRecords = sorted.where((r) {
                              final s = r.status.toLowerCase();
                              return s == 'present' || s == 'success';
                            }).toList();
                            final absentRecords = sorted.where((r) {
                              final s = r.status.toLowerCase();
                              return s == 'absent' || s == 'failed';
                            }).toList();

                            return DefaultTabController(
                              length: 2,
                              child: Column(
                                children: [
                                  // Tabs
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.lightGrey,
                                        ),
                                      ),
                                      child: TabBar(
                                        labelColor: AppTheme.primaryBlack,
                                        unselectedLabelColor: AppTheme.darkGrey
                                            .withOpacity(0.8),
                                        indicatorColor: AppTheme.successGreen,
                                        tabs: [
                                          Tab(
                                            text:
                                                'Present (${presentRecords.length})',
                                          ),
                                          Tab(
                                            text:
                                                'Absent (${absentRecords.length})',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Records lists per tab
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        // Present list
                                        presentRecords.isEmpty
                                            ? Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    24.0,
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: const [
                                                      Icon(
                                                        Icons.inbox_outlined,
                                                        size: 40,
                                                        color:
                                                            AppTheme.darkGrey,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'No present records',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : ListView.separated(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      16,
                                                      0,
                                                      16,
                                                      16,
                                                    ),
                                                itemBuilder: (c, i) =>
                                                    _buildAttendanceRecordTile(
                                                      presentRecords[i],
                                                    ),
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 8),
                                                itemCount:
                                                    presentRecords.length,
                                              ),
                                        // Absent list
                                        absentRecords.isEmpty
                                            ? Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    24.0,
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: const [
                                                      Icon(
                                                        Icons.inbox_outlined,
                                                        size: 40,
                                                        color:
                                                            AppTheme.darkGrey,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text('No absent records'),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : ListView.separated(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      16,
                                                      0,
                                                      16,
                                                      16,
                                                    ),
                                                itemBuilder: (c, i) =>
                                                    _buildAttendanceRecordTile(
                                                      absentRecords[i],
                                                    ),
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 8),
                                                itemCount: absentRecords.length,
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          failure: (message, status) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorRed.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: const Icon(
                                        Icons.error_outline,
                                        size: 40,
                                        color: AppTheme.errorRed,
                                      ),
                                    ).animate().shake(),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Error Loading Records',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      message,
                                      style: TextStyle(
                                        color: AppTheme.darkGrey.withOpacity(
                                          0.8,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _loadAttendanceRecords,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.errorRed,
                                        foregroundColor: AppTheme.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceRecordTile(AttendanceViewRecord record) {
    final status = record.status.toLowerCase();
    final isPresent = status == 'present' || status == 'success';
    final name = (record.user?.name ?? '').trim().isEmpty
        ? record.userId
        : record.user!.name;
    final initials = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isPresent ? AppTheme.successGreen : AppTheme.errorRed)
              .withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGrey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPresent ? AppTheme.successGreen : AppTheme.errorRed,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPresent
                            ? AppTheme.successGreen.withOpacity(0.15)
                            : AppTheme.errorRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPresent ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: isPresent
                              ? AppTheme.successGreen
                              : AppTheme.errorRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if ((record.user?.phoneNumber ?? '').isNotEmpty) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _callPhone(record.user!.phoneNumber!),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: AppTheme.darkGrey.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              record.user!.phoneNumber!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkGrey.withOpacity(0.8),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Status icon
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: isPresent ? AppTheme.successGreen : AppTheme.errorRed,
            size: 24,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _callPhone(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to initiate call: $e')));
    }
  }
}
