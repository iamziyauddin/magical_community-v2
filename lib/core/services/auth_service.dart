import 'package:flutter/material.dart';
import '../storage/token_storage.dart';
import '../services/navigation_service.dart';
import '../../screens/auth/login_screen.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  /// Handle logout globally
  Future<void> handleLogout({String? message, bool showMessage = true}) async {
    try {
      // Clear all stored authentication data
      await TokenStorage.clearToken();

      // Clear any other user-related data if needed
      // await UserPreferences.clear();
      // await Hive.box('user_data').clear();

      // Show logout message if needed
      if (showMessage && message != null) {
        NavigationService.instance.showSnackBar(
          message,
          backgroundColor: Colors.orange,
        );
      }

      // Navigate to login screen and clear navigation stack
      await NavigationService.instance.pushWidgetAndClearStack(
        const LoginScreen(),
      );
    } catch (e) {
      // Handle any errors during logout
      debugPrint('Error during logout: $e');

      // Still try to navigate to login even if cleanup fails
      NavigationService.instance.pushWidgetAndClearStack(const LoginScreen());
    }
  }

  /// Handle unauthorized response globally
  Future<void> handleUnauthorized({String? customMessage}) async {
    final message =
        customMessage ?? 'Your session has expired. Please login again.';

    await handleLogout(message: message, showMessage: true);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await TokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Manual logout (called from logout buttons)
  Future<void> logout() async {
    await handleLogout(
      message: 'You have been logged out successfully.',
      showMessage: true,
    );
  }
}
