import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/screens/auth/login_screen.dart';
import 'package:magical_community/data/services/auth_service.dart';
import 'package:magical_community/core/storage/token_storage.dart';
import 'package:magical_community/core/storage/user_storage.dart';
import 'package:magical_community/core/session/session_manager.dart';

class AuthUtils {
  static final AuthService _authService = AuthService();

  /// Shows a logout confirmation dialog and handles logout
  static void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _performLogout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Performs the actual logout by calling auth service and navigating to login screen
  static Future<void> _performLogout(BuildContext context) async {
    try {
      // Immediate local cleanup (don’t wait on network)
      await TokenStorage.clearToken();
      await UserStorage.clearUserData();
      SessionManager.instance.clearSession();

      // Redirect to login instantly without waiting for API
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }

      // Fire-and-forget server logout (optional)
      // Ignore result and do not block UI
      // Any errors are safely ignored since local logout is already done
      // Note: This call may fail because token was cleared; it’s acceptable.
      // Intentionally not awaited
      // ignore: unawaited_futures
      _authService.logout();
    } catch (e) {
      // On any error, still navigate to login
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  /// Quick logout without confirmation (for emergency cases)
  static void quickLogout(BuildContext context) {
    _performLogout(context);
  }
}
