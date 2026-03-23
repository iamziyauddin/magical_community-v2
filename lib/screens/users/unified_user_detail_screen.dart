import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/models/user_model.dart';
import 'package:magical_community/models/payment_model.dart';
import 'package:magical_community/data/services/user_service.dart';
import 'package:magical_community/screens/users/edit_user_details_screen.dart';
import 'package:magical_community/widgets/subscription_dialog.dart';
// Removed ApiService import after extracting payment management to dedicated screen
import 'package:url_launcher/url_launcher.dart';
import 'package:magical_community/screens/users/payment_history_screen.dart';
import 'package:magical_community/screens/users/subscription_history_screen.dart';

class UnifiedUserDetailScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel)? onUserUpdated;

  const UnifiedUserDetailScreen({
    super.key,
    required this.user,
    this.onUserUpdated,
  });

  @override
  State<UnifiedUserDetailScreen> createState() =>
      _UnifiedUserDetailScreenState();
}

class _UnifiedUserDetailScreenState extends State<UnifiedUserDetailScreen> {
  final UserService _userService = UserService();
  UserModel? _detailUser; // Store the API-loaded user data separately
  bool _detailsUpdated = false;
  String? _roleUpdateError;
  bool _isUpdatingRole = false;
  String? _currentRoleBeingUpdated;
  bool _isLoadingDetail = false;
  String? _detailError;
  final String _clubId =
      'cmeqz2jnu001x12qwdziw2vm3'; // TODO: inject via session

  @override
  void initState() {
    super.initState();
    // Start loading immediately - API-first approach
    _isLoadingDetail = true;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _detailError = null;
    });
    final result = await _userService.getUserDetail(
      userId: widget.user.id,
      clubId: _clubId,
    );
    if (!mounted) return;
    result.when(
      success: (u) {
        setState(() {
          // Store the complete API-loaded user data
          _detailUser = u;
          _isLoadingDetail = false;
        });
      },
      failure: (msg, int? status) {
        setState(() {
          _isLoadingDetail = false;
          _detailError = msg.isNotEmpty ? msg : 'Failed to load latest data';
        });
      },
    );
  }

  // Get the current user data (API data if loaded, otherwise null)
  UserModel? get currentUser => _detailUser;

  bool get _isTrialUser {
    final user = currentUser;
    if (user == null) return false;

    // A user is considered a trial user if:
    // PRIORITY 1: Check membershipType first (most reliable from API)
    // PRIORITY 2: Check userType if membershipType is null
    // PRIORITY 3: Check trial dates pattern

    // Priority 1: If membershipType is explicitly set, trust it
    if (user.membershipType != null) {
      if (user.membershipType == 'trial') {
        return true;
      } else if (user.membershipType == 'membership') {
        return false;
      }
    }

    // Priority 2: Fall back to userType if membershipType is null or unknown
    if (user.userType == UserType.trial) {
      return true;
    }

    // Priority 3: Check trial date pattern (has trialEndDate but no regular membership)
    if (user.trialEndDate != null &&
        user.membershipStartDate == null &&
        user.membershipEndDate == null) {
      return true;
    }

    return false;
  }

  // Check if user is a UMS member (has regular membership, not trial)
  bool get _isUMSMember {
    final user = currentUser;
    if (user == null) return false;

    // A user is a UMS member if they are NOT a trial user AND have an active membership
    if (_isTrialUser) {
      return false;
    }

    // Must have membership dates to be considered UMS
    if (user.membershipStartDate != null || user.membershipEndDate != null) {
      return true;
    }

    // If they have a role other than member and are not trial users, they're UMS
    if (user.role == UserRole.coach || user.role == UserRole.seniorCoach) {
      return true;
    }

    return false;
  }

  String get _screenTitle {
    final user = currentUser;
    if (user == null) return 'Loading...';
    return _isTrialUser ? '${user.name} - Trial Details' : user.name;
  }

  String get _actionButtonText {
    // Use widget.user to match the button action logic
    if (_isTrialUser) {
      // Check if trial user has upcoming subscription
      return widget.user.hasUpcomingSubscription
          ? 'View Membership'
          : 'Upgrade';
    } else if (widget.user.userType == UserType.visitor) {
      return widget.user.hasUpcomingSubscription
          ? 'View Membership'
          : 'Upgrade';
    } else {
      return 'Renew';
    }
  }

  // Generic inclusive days calculator
  String _getInclusiveDaysLeft(UserModel user) {
    final endDate = _isTrialUser
        ? (user.trialEndDate ?? user.membershipEndDate)
        : user.membershipEndDate;
    final startDate = _isTrialUser
        ? (user.trialStartDate ?? user.membershipStartDate)
        : user.membershipStartDate;

    if (endDate == null || startDate == null) return '—';

    final todayRaw = DateTime.now();
    final today = DateTime(todayRaw.year, todayRaw.month, todayRaw.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    if (today.isAfter(end)) return 'Expired';
    if (today.isBefore(start)) {
      final total = end.difference(start).inDays + 1;
      return '$total days';
    }
    final remaining = end.difference(today).inDays + 1;
    return '$remaining days';
  }

  Color _getUserThemeColor() {
    if (_isTrialUser) {
      return widget.user.isTrialExpired
          ? AppTheme.errorRed
          : AppTheme.accentYellow;
    }
    switch (widget.user.role) {
      case UserRole.seniorCoach:
        return AppTheme.errorRed; // Changed to red for senior coaches
      case UserRole.coach:
        return AppTheme
            .successGreen; // Changed to green for coaches (same as UMS)
      case UserRole.member:
        return AppTheme.accentYellow; // UMS members keep yellow
    }
  }

  IconData _getUserIcon() {
    if (_isTrialUser) return Icons.schedule;
    switch (widget.user.role) {
      case UserRole.seniorCoach:
        return Icons.star;
      case UserRole.coach:
        return Icons.fitness_center;
      case UserRole.member:
        return Icons.person;
    }
  }

  String _getUserStatus() {
    if (_isTrialUser) {
      return widget.user.isTrialExpired ? 'Trial Expired' : 'Active Trial';
    }
    return 'Active ${widget.user.roleDisplayName}';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      // Silently ignore for now; optionally show a snackbar
    }
  }

  Future<void> _handleRoleChange(String newRole) async {
    print('DEBUG: _handleRoleChange called with role: $newRole');
    print('DEBUG: _isUpdatingRole: $_isUpdatingRole');

    if (_isUpdatingRole) {
      print('DEBUG: Already updating role, returning early');
      return;
    }

    try {
      print('DEBUG: Setting state to updating...');
      setState(() {
        _isUpdatingRole = true;
        _roleUpdateError = null;
        _currentRoleBeingUpdated = newRole;
      });

      // Convert the role strings to match API expectations
      String apiRole;
      switch (newRole) {
        case 'member':
          apiRole = 'member';
          break;
        case 'coach':
          apiRole = 'coach';
          break;
        case 'seniorCoach':
          apiRole = 'senior_coach';
          break;
        default:
          print('DEBUG: Invalid role provided: $newRole');
          throw Exception('Invalid role: $newRole');
      }

      print('DEBUG: Calling updateMemberRole API with:');
      print('DEBUG: memberId: ${widget.user.id}');
      print('DEBUG: memberRole: $apiRole');

      final result = await _userService.updateMemberRole(
        memberId: widget.user.id,
        memberRole: apiRole,
      );

      print('DEBUG: API call completed, checking if mounted...');
      if (!mounted) {
        print('DEBUG: Widget not mounted, returning early');
        return;
      }

      print('DEBUG: Processing API result...');
      result.when(
        success: (updatedUser) {
          print('DEBUG: API success, updated user: ${updatedUser.name}');
          print('DEBUG: Updated user role: ${updatedUser.role}');

          try {
            setState(() {
              // Update the current widget.user with the new role information
              widget.user.role = updatedUser.role;
              widget.user.memberRole = updatedUser.memberRole;

              // Also update our detail user if loaded
              if (_detailUser != null) {
                _detailUser!.role = updatedUser.role;
                _detailUser!.memberRole = updatedUser.memberRole;
              }

              _isUpdatingRole = false;
              _roleUpdateError = null;
              _currentRoleBeingUpdated = null;
            });

            // Show success message
            String message;
            final currentMemberRole = widget.user.memberRole ?? '';
            switch (updatedUser.role) {
              case UserRole.member:
                message =
                    '${updatedUser.fullName} successfully demoted to UMS Member';
                break;
              case UserRole.coach:
                // Check if this was a promotion from member or demotion from senior coach
                if (currentMemberRole == 'seniorCoach' ||
                    currentMemberRole == 'senior_coach') {
                  message =
                      '${updatedUser.fullName} successfully demoted to Coach';
                } else {
                  message =
                      '${updatedUser.fullName} successfully promoted to Coach';
                }
                break;
              case UserRole.seniorCoach:
                message =
                    '${updatedUser.fullName} successfully promoted to Senior Coach';
                break;
            }

            print('DEBUG: Showing success snackbar: $message');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(message)),
                  ],
                ),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Call the onUserUpdated callback to notify parent screen
            print('DEBUG: Calling onUserUpdated callback...');
            if (widget.onUserUpdated != null) {
              widget.onUserUpdated!(updatedUser);
            }

            // Pop with role-changed result so parent can refresh lists
            print('DEBUG: Popping navigator with role-changed result');
            Navigator.of(context).pop('role-changed');
          } catch (e) {
            print('DEBUG: Error in success handler: $e');
            setState(() {
              _isUpdatingRole = false;
              _roleUpdateError = 'Error processing success: ${e.toString()}';
              _currentRoleBeingUpdated = null;
            });
          }
        },
        failure: (message, statusCode) {
          print(
            'DEBUG: API failure - message: $message, statusCode: $statusCode',
          );
          try {
            setState(() {
              _isUpdatingRole = false;
              _roleUpdateError = message;
              _currentRoleBeingUpdated = null;
            });
          } catch (e) {
            print('DEBUG: Error setting failure state: $e');
          }
        },
      );
    } catch (e, stackTrace) {
      print('DEBUG: Exception in _handleRoleChange: $e');
      print('DEBUG: StackTrace: $stackTrace');

      if (!mounted) {
        print('DEBUG: Widget not mounted during error handling');
        return;
      }

      try {
        setState(() {
          _isUpdatingRole = false;
          _roleUpdateError = 'Error updating role: ${e.toString()}';
          _currentRoleBeingUpdated = null;
        });
      } catch (stateError) {
        print('DEBUG: Error setting error state: $stateError');
      }
    }
  }

  String _getRoleUpdateMessage(String newRole) {
    final currentMemberRole = widget.user.memberRole ?? '';
    final userName = widget.user.name;

    switch (newRole) {
      case 'coach':
        if (widget.user.role == UserRole.member) {
          return '🎯 Promoting $userName to Coach Role';
        } else if (currentMemberRole == 'seniorCoach' ||
            currentMemberRole == 'senior_coach') {
          return '📉 Demoting $userName to Coach Role';
        } else {
          return '🔄 Updating $userName to Coach Role';
        }
      case 'seniorCoach':
        return '⭐ Promoting $userName to Senior Coach';
      case 'member':
        return '👤 Demoting $userName to UMS Member';
      default:
        return '🔄 Updating user role...';
    }
  }

  Widget _buildLoadingOverlay() {
    String message = 'Updating Role...';
    String subtitle = 'Please wait while we process the changes...';
    IconData roleIcon = Icons.admin_panel_settings;
    Color roleColor = AppTheme.accentYellow;

    if (_currentRoleBeingUpdated != null) {
      message = _getRoleUpdateMessage(_currentRoleBeingUpdated!);

      // Set role-specific icons and colors
      switch (_currentRoleBeingUpdated) {
        case 'member':
          roleIcon = Icons.person;
          roleColor = AppTheme.accentYellow;
          subtitle = 'Adjusting permissions and access levels...';
          break;
        case 'coach':
          roleIcon = Icons.fitness_center;
          roleColor = AppTheme.successGreen;
          subtitle = 'Updating coaching privileges and responsibilities...';
          break;
        case 'seniorCoach':
          roleIcon = Icons.star;
          roleColor = AppTheme.errorRed;
          subtitle = 'Granting senior coaching authority...';
          break;
      }
    }

    return Container(
      color: AppTheme.primaryBlack.withValues(alpha: 0.85),
      child: Center(
        child:
            Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlack.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated role icon with pulsing effect
                      Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: roleColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(roleIcon, color: roleColor, size: 36),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.1, 1.1),
                            duration: 1200.ms,
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.1, 1.1),
                            end: const Offset(1.0, 1.0),
                            duration: 1200.ms,
                            curve: Curves.easeInOut,
                          ),

                      const SizedBox(height: 32),

                      // Progress indicator with custom styling
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: roleColor,
                                strokeWidth: 4,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: roleColor,
                                    shape: BoxShape.circle,
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .fade(
                                  begin: 0.3,
                                  end: 1.0,
                                  duration: 800.ms,
                                  curve: Curves.easeInOut,
                                )
                                .then()
                                .fade(
                                  begin: 1.0,
                                  end: 0.3,
                                  duration: 800.ms,
                                  curve: Curves.easeInOut,
                                ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Main message with gradient text effect
                      ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                roleColor,
                                roleColor.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              message,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 200.ms)
                          .slideY(
                            begin: 0.3,
                            end: 0,
                            duration: 600.ms,
                            delay: 200.ms,
                          ),

                      const SizedBox(height: 16),

                      // Subtitle with typing animation effect
                      Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.darkGrey.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 400.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            duration: 800.ms,
                            delay: 400.ms,
                          ),

                      const SizedBox(height: 24),

                      // Progress steps indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .scale(
                                begin: const Offset(1.0, 1.0),
                                end: const Offset(1.5, 1.5),
                                duration: 600.ms,
                                delay: Duration(milliseconds: index * 200),
                                curve: Curves.easeInOut,
                              )
                              .then()
                              .scale(
                                begin: const Offset(1.5, 1.5),
                                end: const Offset(1.0, 1.0),
                                duration: 600.ms,
                                curve: Curves.easeInOut,
                              );
                        }),
                      ),
                    ],
                  ),
                )
                .animate()
                .scale(
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(duration: 300.ms),
      ),
    );
  }

  // Helper widgets (moved up so analyzer sees definitions before use, though not required)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.darkGrey.withOpacity(0.7), size: 20),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.darkGrey.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.primaryBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickablePhoneRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.darkGrey.withOpacity(0.7)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.darkGrey.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _makePhoneCall(value),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.accentYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const Icon(Icons.phone, color: AppTheme.accentYellow, size: 18),
      ],
    );
  }

  Widget _buildMembershipStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGrey.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShakeStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkGrey.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGrey.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAttendanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.darkGrey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Subscription renewal validation
  bool _canRenewSubscription() {
    // Option 1: All shakes consumed (totalDueShake = 0)
    bool allShakesConsumed =
        (widget.user.activeMembership?.totalDueShake ?? 0) == 0;

    // Option 2: Membership expired (current date > membershipEndDate)
    bool membershipExpired = false;
    if (widget.user.membershipEndDate != null) {
      final now = DateTime.now();
      final endDate = widget.user.membershipEndDate!;
      membershipExpired = now.isAfter(endDate);
    }

    // User can renew if EITHER condition is true
    return allShakesConsumed || membershipExpired;
  }

  String _getRenewalBlockedMessage() {
    final dueShakes = widget.user.activeMembership?.totalDueShake ?? 0;
    final endDate = widget.user.membershipEndDate;

    if (dueShakes > 0 && endDate != null) {
      return 'Great to see your enthusiasm for continuing! 🌟\n\n'
          'Your renewal will be available once you finish your remaining delicious shakes '
          'or after your current membership cycle completes.\n\n'
          'Keep enjoying your fitness journey! 💪';
    } else if (dueShakes > 0) {
      return 'We love your commitment! 🎯\n\n'
          'You still have some nutritious shakes waiting for you. '
          'Once you\'ve enjoyed them all, your renewal option will be ready!\n\n'
          'Every shake brings you closer to your goals! 🥤✨';
    } else if (endDate != null) {
      return 'Looking ahead, we see! 👀\n\n'
          'Your current membership is actively serving you well. '
          'Your renewal window will open as this period concludes.\n\n'
          'We\'ll be here when you\'re ready to continue! 🚀';
    } else {
      return 'We appreciate your interest in continuing your journey with us! 🙏\n\n'
          'Your renewal option isn\'t quite ready yet, but we\'re excited to help you when the time comes.';
    }
  }

  void _showRenewalBlockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.schedule, color: AppTheme.accentYellow),
            SizedBox(width: 8),
            Text(
              'Renewal Coming Soon',
              style: TextStyle(
                fontSize: 20, // 👈 set your desired font size here
                fontWeight: FontWeight.w500, // optional
              ),
            ),
          ],
        ),
        content: Text(
          _getRenewalBlockedMessage(),
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlack),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show UI when API data is loaded
    final user = currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        print('DEBUG: PopScope triggered');
        print('DEBUG: _detailsUpdated: $_detailsUpdated');
        print('DEBUG: _detailUser: ${_detailUser != null}');

        try {
          if (_detailsUpdated) {
            print(
              'DEBUG: Details updated, notifying parent and returning details-updated',
            );
            // Call the callback to update the user in the list immediately
            if (widget.onUserUpdated != null && _detailUser != null) {
              try {
                widget.onUserUpdated!(_detailUser!);
                print(
                  'DEBUG: Successfully called onUserUpdated callback for details update',
                );
              } catch (e) {
                print(
                  'DEBUG: Error in onUserUpdated callback (details update): $e',
                );
              }
            }
            Navigator.of(context).pop('details-updated');
            return;
          } else if (_detailUser != null) {
            print('DEBUG: User was updated, notifying parent');
            // Use the callback to notify parent about updated user instead of returning it
            if (widget.onUserUpdated != null) {
              try {
                widget.onUserUpdated!(_detailUser!);
                print('DEBUG: Successfully called onUserUpdated callback');
              } catch (e) {
                print(
                  'DEBUG: Error in onUserUpdated callback (navigation): $e',
                );
              }
            }
            print('DEBUG: Popping with user-updated result');
            Navigator.of(context).pop('user-updated');
            return;
          }
          print('DEBUG: Normal pop');
          Navigator.of(context).pop();
        } catch (e) {
          print('DEBUG: Error in PopScope: $e');
          // Safe fallback - just pop normally
          Navigator.of(context).pop();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppTheme.lightGrey,
            appBar: AppBar(
              title: Text(_screenTitle),
              backgroundColor: _isTrialUser
                  ? AppTheme.accentYellow
                  : AppTheme.primaryBlack,
              foregroundColor: _isTrialUser
                  ? AppTheme.primaryBlack
                  : AppTheme.white,
              elevation: 0,
              actions: currentUser != null
                  ? [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Details',
                        onPressed: () async {
                          final result =
                              await Navigator.push<Map<String, dynamic>>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditUserDetailsScreen(user: widget.user),
                                ),
                              );
                          if (result != null &&
                              result['detailsUpdated'] == true) {
                            final updated = result['updatedUser'] as UserModel;
                            setState(() {
                              // Update basic user details
                              widget.user.name = updated.name;
                              widget.user.firstName = updated.firstName;
                              widget.user.lastName = updated.lastName;
                              widget.user.email = updated.email;
                              widget.user.address = updated.address;
                              widget.user.mobileNumber = updated.mobileNumber;
                              widget.user.disease = updated.disease;
                              widget.user.referredByName =
                                  updated.referredByName;
                              widget.user.referredById = updated.referredById;

                              // Update membership dates if provided
                              if (updated.membershipStartDate != null) {
                                widget.user.membershipStartDate =
                                    updated.membershipStartDate;
                              }
                              if (updated.membershipEndDate != null) {
                                widget.user.membershipEndDate =
                                    updated.membershipEndDate;
                              }

                              // Update financial data
                              widget.user.totalPayable = updated.totalPayable;
                              widget.user.totalPaid = updated.totalPaid;
                              widget.user.dueAmount = updated.dueAmount;
                              widget.user.pendingDues = updated.pendingDues;

                              // Update membership status and active membership
                              if (updated.membershipStatus != null) {
                                widget.user.membershipStatus =
                                    updated.membershipStatus;
                              }
                              if (updated.activeMembership != null) {
                                widget.user.activeMembership =
                                    updated.activeMembership;
                                // Update shake data from active membership
                                widget.user.totalDueShake =
                                    updated.activeMembership!.totalDueShake ??
                                    0;
                                widget.user.totalConsumedShake =
                                    updated
                                        .activeMembership!
                                        .totalConsumedShake ??
                                    0;
                              }

                              // Update attendance summary if provided
                              if (updated.attendanceSummary != null) {
                                widget.user.attendanceSummary =
                                    updated.attendanceSummary;
                              }

                              widget.user.updatedAt = DateTime.now();
                              // Update detail user if loaded
                              if (_detailUser != null) {
                                _detailUser = widget.user;
                              }
                              _detailsUpdated = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppTheme.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text('User details updated successfully!'),
                                  ],
                                ),
                                backgroundColor: AppTheme.successGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      // Role management for UMS members only (not trial users)
                      if (_isUMSMember)
                        _isUpdatingRole
                            ? IconButton(
                                icon: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.white,
                                    ),
                                  ),
                                ),
                                tooltip: 'Updating Role...',
                                onPressed: null,
                              )
                            : PopupMenuButton<String>(
                                icon: const Icon(Icons.admin_panel_settings),
                                tooltip: 'Role Management',
                                enabled: !_isUpdatingRole,
                                onSelected: _handleRoleChange,
                                itemBuilder: (context) {
                                  final items = <PopupMenuEntry<String>>[];

                                  // Use memberRole for more precise role management
                                  final currentMemberRole =
                                      widget.user.memberRole ?? '';

                                  // For UMS Members (no memberRole or empty): Show promote to coach option
                                  if (widget.user.role == UserRole.member &&
                                      (currentMemberRole.isEmpty ||
                                          currentMemberRole == 'member')) {
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'coach',
                                        child: Text('Promote to Coach'),
                                      ),
                                    );
                                  }
                                  // For Coaches: Show promote to senior coach and demote to UMS
                                  else if (currentMemberRole == 'coach') {
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'seniorCoach',
                                        child: Text('Promote to Senior Coach'),
                                      ),
                                    );
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'member',
                                        child: Text('Demote to UMS'),
                                      ),
                                    );
                                  }
                                  // For Senior Coaches: Show demote to coach and demote to UMS
                                  else if (currentMemberRole == 'seniorCoach' ||
                                      currentMemberRole == 'senior_coach') {
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'coach',
                                        child: Text('Demote to Coach'),
                                      ),
                                    );
                                  }

                                  return items;
                                },
                              ),
                    ]
                  : null,
            ),
            body: currentUser == null
                ? Center(
                    child: _detailError != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppTheme.errorRed,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _detailError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _fetchDetail,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          )
                        : const CircularProgressIndicator(),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_roleUpdateError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.errorRed),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.errorRed,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _roleUpdateError!,
                                      style: const TextStyle(
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Profile Header (continues existing original UI)
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.white,
                                  _getUserThemeColor().withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: _getUserThemeColor(),
                                  child: Text(
                                    widget.user.name.isNotEmpty
                                        ? widget.user.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: _isTrialUser
                                          ? AppTheme.primaryBlack
                                          : AppTheme.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.user.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlack,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getUserThemeColor(),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getUserIcon(),
                                        color: _isTrialUser
                                            ? AppTheme.primaryBlack
                                            : AppTheme.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _getUserStatus(),
                                        style: TextStyle(
                                          color: _isTrialUser
                                              ? AppTheme.primaryBlack
                                              : AppTheme.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isTrialUser) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.user.pendingDues > 0
                                          ? AppTheme.errorRed
                                          : AppTheme.successGreen,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      widget.user.pendingDues > 0
                                          ? 'Dues: ₹${widget.user.pendingDues.toInt()}'
                                          : 'All Paid',
                                      style: const TextStyle(
                                        color: AppTheme.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ).animate().scale(duration: 600.ms),

                        const SizedBox(height: 16),

                        // Contact Information
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.contact_phone,
                                      color: AppTheme.primaryBlack,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Contact Information',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlack,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildClickablePhoneRow(
                                  Icons.phone,
                                  'Mobile',
                                  widget.user.mobileNumber,
                                ),
                                const SizedBox(height: 6),
                                if (widget.user.email != null &&
                                    widget.user.email!.isNotEmpty) ...[
                                  _buildInfoRow(
                                    Icons.email,
                                    'Email',
                                    widget.user.email!,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                _buildInfoRow(
                                  Icons.home,
                                  'Address',
                                  widget.user.address.isNotEmpty
                                      ? widget.user.address
                                      : '—',
                                ),
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  Icons.local_hospital,
                                  'Disease',
                                  widget.user.disease?.isNotEmpty == true
                                      ? widget.user.disease!
                                      : 'None',
                                ),
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  Icons.people,
                                  'Referred By',
                                  (widget.user.referredByName != null &&
                                          widget.user.referredByName!
                                              .trim()
                                              .isNotEmpty)
                                      ? widget.user.referredByName!.trim()
                                      : 'Direct',
                                ),
                              ],
                            ),
                          ),
                        ).animate().slide(
                          begin: const Offset(-1, 0),
                          delay: 200.ms,
                        ),

                        const SizedBox(height: 16),

                        // Membership Details
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accentYellow.withOpacity(0.1),
                                  AppTheme.accentYellow.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentYellow
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          color: AppTheme.primaryBlack,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isTrialUser
                                                ? 'Trial Membership'
                                                : 'Membership Details',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryBlack,
                                            ),
                                          ),
                                          Text(
                                            _isTrialUser
                                                ? (widget.user.isTrialExpired
                                                      ? 'Expired'
                                                      : 'Active')
                                                : 'Active Membership',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  _isTrialUser &&
                                                      widget.user.isTrialExpired
                                                  ? AppTheme.errorRed
                                                  : AppTheme.successGreen,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMembershipStatCard(
                                          'Start Date',
                                          _formatDate(
                                            _isTrialUser
                                                ? (widget.user.trialStartDate ??
                                                      widget
                                                          .user
                                                          .membershipStartDate ??
                                                      DateTime.now())
                                                : (widget
                                                          .user
                                                          .membershipStartDate ??
                                                      DateTime.now()),
                                          ),
                                          Icons.play_circle_outline,
                                          AppTheme.successGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildMembershipStatCard(
                                          'End Date',
                                          _formatDate(
                                            _isTrialUser
                                                ? (widget.user.trialEndDate ??
                                                      widget
                                                          .user
                                                          .membershipEndDate ??
                                                      DateTime.now())
                                                : (widget
                                                          .user
                                                          .membershipEndDate ??
                                                      DateTime.now()),
                                          ),
                                          Icons.stop_circle_outlined,
                                          AppTheme.errorRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMembershipStatCard(
                                          'Days Left',
                                          _getInclusiveDaysLeft(widget.user),
                                          Icons.timer_outlined,
                                          _isTrialUser &&
                                                  widget.user.isTrialExpired
                                              ? AppTheme.errorRed
                                              : AppTheme.accentYellow,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildMembershipStatCard(
                                          'Total Paid',
                                          '₹${widget.user.totalPaid.toInt()}',
                                          Icons.currency_rupee,
                                          AppTheme.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().slide(
                          begin: const Offset(1, 0),
                          delay: 300.ms,
                        ),

                        const SizedBox(height: 16),

                        // Shake Details Card
                        if (widget.user.activeMembership != null)
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.successGreen.withOpacity(0.1),
                                    AppTheme.successGreen.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.successGreen
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.local_drink,
                                            color: AppTheme.successGreen,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Shake Details',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryBlack,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildShakeStatCard(
                                            'Total Shakes',
                                            '${widget.user.activeMembership?.totalShake ?? 0}',
                                            Icons.local_drink,
                                            AppTheme.primaryBlack,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildShakeStatCard(
                                            'Due Shakes',
                                            '${widget.user.activeMembership?.totalDueShake ?? 0}',
                                            Icons.pending_actions,
                                            AppTheme.accentYellow,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: Container(
                                        width: double.infinity,
                                        child: _buildShakeStatCard(
                                          'Consumed Shakes',
                                          '${widget.user.activeMembership?.totalConsumedShake ?? 0}',
                                          Icons.check_circle,
                                          AppTheme.successGreen,
                                          isWide: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().slide(
                            begin: const Offset(-1, 0),
                            delay: 350.ms,
                          ),

                        const SizedBox(height: 16),

                        // Attendance Summary
                        if (widget.user.attendanceSummary != null)
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.assignment_turned_in,
                                        color: AppTheme.accentYellow,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Attendance Summary',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildAttendanceCard(
                                          'Present',
                                          widget.user.attendanceSummary!.present
                                              .toString(),
                                          Icons.check_circle,
                                          AppTheme.successGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildAttendanceCard(
                                          'Absent',
                                          widget.user.attendanceSummary!.absent
                                              .toString(),
                                          Icons.cancel,
                                          AppTheme.errorRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: widget.user.attendanceSummary!.rate,
                                    backgroundColor: AppTheme.errorRed
                                        .withOpacity(0.3),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppTheme.successGreen,
                                        ),
                                    minHeight: 8,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Attendance Rate: '
                                    '${(widget.user.attendanceSummary!.rate * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlack,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

                        const SizedBox(height: 05),
                        // View Payment History and Subscription History buttons side by side
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PaymentHistoryScreen(
                                          user: widget.user,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.receipt_long,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Payment History',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryBlack,
                                    elevation: 2,
                                    shadowColor: AppTheme.primaryBlack
                                        .withOpacity(0.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: AppTheme.primaryBlack
                                            .withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SubscriptionHistoryScreen(
                                              user: widget.user,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.history, size: 16),
                                  label: const Text(
                                    'Subscription History',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryBlack,
                                    elevation: 2,
                                    shadowColor: AppTheme.primaryBlack
                                        .withOpacity(0.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: AppTheme.primaryBlack
                                            .withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons (Add Payment + Upgrade/Renew)
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showPaymentDialog(),
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Add Payment'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.successGreen,
                                      foregroundColor: AppTheme.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      minimumSize: const Size(0, 48),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showSubscriptionAction(),
                                    icon: Icon(
                                      _isTrialUser
                                          ? (widget.user.hasUpcomingSubscription
                                                ? Icons.card_membership
                                                : Icons.upgrade)
                                          : (widget.user.userType ==
                                                        UserType.visitor &&
                                                    widget
                                                        .user
                                                        .hasUpcomingSubscription
                                                ? Icons.card_membership
                                                : Icons.refresh),
                                    ),
                                    label: Text(
                                      _actionButtonText,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          (_isTrialUser &&
                                                  widget
                                                      .user
                                                      .hasUpcomingSubscription) ||
                                              (widget.user.userType ==
                                                      UserType.visitor &&
                                                  widget
                                                      .user
                                                      .hasUpcomingSubscription)
                                          ? AppTheme.successGreen
                                          : AppTheme.accentYellow,
                                      foregroundColor:
                                          (_isTrialUser &&
                                                  widget
                                                      .user
                                                      .hasUpcomingSubscription) ||
                                              (widget.user.userType ==
                                                      UserType.visitor &&
                                                  widget
                                                      .user
                                                      .hasUpcomingSubscription)
                                          ? AppTheme.white
                                          : AppTheme.primaryBlack,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      minimumSize: const Size(0, 48),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().slide(
                          begin: const Offset(0, 1),
                          delay: 400.ms,
                        ),
                      ],
                    ),
                  ),
          ),
          if (!_isLoadingDetail && _detailError != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.errorRed,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _detailError!,
                          style: const TextStyle(color: AppTheme.white),
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchDetail,
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: AppTheme.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Loading overlay
          if (_isUpdatingRole) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  void _showSubscriptionAction() {
    if (_isTrialUser) {
      // For trial users, check if they have upcoming subscription
      if (widget.user.hasUpcomingSubscription) {
        _showVisitorMembershipDetails(); // Show membership details for trial users too
        return;
      }
      // Otherwise check validation before upgrade
      if (!_canRenewSubscription()) {
        _showRenewalBlockedDialog();
        return;
      }
      _showTrialUpgrade();
    } else if (widget.user.userType == UserType.visitor) {
      // For visitors: check if they have upcoming subscription
      if (widget.user.hasUpcomingSubscription) {
        _showVisitorMembershipDetails();
      } else {
        // For visitors upgrading, check validation
        if (!_canRenewSubscription()) {
          _showRenewalBlockedDialog();
          return;
        }
        _showTrialUpgrade(); // Use same upgrade flow as trials for visitors
      }
    } else {
      // For UMS, Coach, Senior Coach - validate before renewal
      if (!_canRenewSubscription()) {
        _showRenewalBlockedDialog();
        return;
      }
      _showMembershipRenewal();
    }
  }

  // Payment management (Add only – edit/delete moved to history screen if needed later)
  void _showPaymentDialog() {
    final parentContext = context;
    final amountController = TextEditingController(text: '0');
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    PaymentMode selectedMode = PaymentMode.cash;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.payment, color: AppTheme.successGreen),
              SizedBox(width: 8),
              Text('Add Payment'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.successGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isTrialUser ? Icons.schedule : Icons.star,
                            color: AppTheme.successGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isTrialUser
                                ? 'Trial Payment'
                                : 'Membership Payment',
                            style: const TextStyle(
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pending Due: ₹${widget.user.dueAmount.toInt()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.user.dueAmount > 0
                              ? AppTheme.errorRed
                              : AppTheme.successGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000, 1, 1),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Payment Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    child: Text(_formatDate(selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMode>(
                  value: selectedMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(_getPaymentModeText(mode)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedMode = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount < 0) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid amount (0 or more)',
                            ),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        final title = notesController.text.isNotEmpty
                            ? notesController.text
                            : '${_isTrialUser ? 'Trial' : 'Membership'} payment by ${widget.user.name}';
                        final result = await _userService.createIncome(
                          title: title,
                          amount: amount,
                          paymentDate: selectedDate,
                          userId: widget.user.id,
                        );
                        if (!mounted) return;
                        result.when(
                          success: (payment) async {
                            setState(() {
                              widget.user.totalPaid =
                                  (widget.user.totalPaid) + payment.amount;
                              final currentDue = widget.user.dueAmount;
                              final newDue = currentDue - payment.amount;
                              final safeDue = newDue > 0 ? newDue : 0.0;
                              widget.user.dueAmount = safeDue;
                              widget.user.pendingDues = safeDue;
                            });
                            if (widget.onUserUpdated != null) {
                              try {
                                widget.onUserUpdated!(widget.user);
                              } catch (_) {}
                            }
                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment added successfully'),
                                  backgroundColor: AppTheme.successGreen,
                                ),
                              );
                            }
                          },
                          failure: (message, statusCode) {
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to add payment: $message',
                                ),
                                backgroundColor: AppTheme.errorRed,
                              ),
                            );
                          },
                        );
                      } catch (e) {
                        Navigator.of(dialogContext).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: AppTheme.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.white,
                        ),
                      ),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
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

  void _showTrialUpgrade() {
    showDialog(
      context: context,
      builder: (_) => SubscriptionDialog(
        config: SubscriptionDialogConfig.trialUpgrade(
          userName: widget.user.name,
          onConfirm: (plan, amount, startDate) async {
            if (!mounted) return;
            await _upgradeToMembershipWithStartDate(
              startDate: startDate,
              planId: plan.id,
              amount: amount,
            );
          },
        ),
      ),
    );
  }

  void _showMembershipRenewal() {
    SubscriptionDialogConfig config;

    if (widget.user.role == UserRole.seniorCoach) {
      config = SubscriptionDialogConfig.renewal(
        userName: widget.user.name,
        onConfirm: (plan, amount, startDate) async {
          if (!mounted) return;
          await _upgradeToMembershipWithStartDate(
            startDate: startDate,
            planId: plan.id,
            amount: amount,
          );
        },
      );
    } else if (widget.user.role == UserRole.coach) {
      config = SubscriptionDialogConfig.renewal(
        userName: widget.user.name,
        onConfirm: (plan, amount, startDate) async {
          if (!mounted) return;
          await _upgradeToMembershipWithStartDate(
            startDate: startDate,
            planId: plan.id,
            amount: amount,
          );
        },
      );
    } else {
      // UMS user
      config = SubscriptionDialogConfig.renewal(
        userName: widget.user.name,
        onConfirm: (plan, amount, startDate) async {
          if (!mounted) return;
          await _upgradeToMembershipWithStartDate(
            startDate: startDate,
            planId: plan.id,
            amount: amount,
          );
        },
      );
    }

    showDialog(
      context: context,
      builder: (_) => SubscriptionDialog(config: config),
    );
  }

  Future<void> _upgradeToMembershipWithStartDate({
    required DateTime startDate,
    String? planId,
    double? amount,
  }) async {
    try {
      // Format the start date for API (assuming format: YYYY-MM-DD)
      final formattedStartDate =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

      print('DEBUG: _upgradeToMembershipWithStartDate called');
      print('DEBUG: userId: ${widget.user.id}');
      print('DEBUG: startDate: $formattedStartDate');
      print('DEBUG: planId: ${planId ?? 'default'}');
      print('DEBUG: amount: ${amount ?? 0.0}');

      final result = await _userService.renewSubscription(
        memberId: widget.user.id,
        subscriptionPlanId:
            planId ?? '1', // Default plan ID - should be configurable
        amount: amount ?? 1000.0, // Default amount - should be configurable
        startDate: formattedStartDate, // Add startDate parameter
      );

      if (!mounted) return;

      result.when(
        success: (subscription) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.white),
                  const SizedBox(width: 8),
                  Text(
                    _isTrialUser
                        ? 'Subscription upgrade successful!'
                        : 'Subscription renewal successful!',
                  ),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Refresh the user data or navigate back
          if (widget.onUserUpdated != null) {
            // If we have an updated user from the API response, use it
            // Otherwise, trigger a refresh of the current user
            widget.onUserUpdated!(widget.user);
          }
        },
        failure: (message, statusCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isTrialUser
                    ? 'Failed to upgrade: $message'
                    : 'Failed to renew: $message',
              ),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        },
      );
    } catch (e) {
      print('DEBUG: Exception in _upgradeToMembershipWithStartDate: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _showVisitorMembershipDetails() {
    final upcomingSubscription = widget.user.upcomingSubscription;
    if (upcomingSubscription == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Membership Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Membership Type',
              upcomingSubscription.membershipType ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Total Payable',
              '₹${upcomingSubscription.totalPayable.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Total Paid',
              '₹${upcomingSubscription.totalPaid.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Due Amount',
              '₹${upcomingSubscription.dueAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Plan ID',
              upcomingSubscription.subscriptionPlanId ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Trial Status',
              upcomingSubscription.isTrial == true ? 'Yes' : 'No',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
