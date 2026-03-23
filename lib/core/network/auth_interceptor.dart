import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import '../services/navigation_service.dart';
import '../../screens/auth/login_screen.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 errors directly with dialog, but not for login requests
    if (err.response?.statusCode == 401) {
      final requestPath = err.requestOptions.path;
      // Don't show session expired dialog for login attempts
      if (requestPath != '/auth/login') {
        _handleUnauthorizedWithDialog();
      }
    }

    super.onError(err, handler);
  }

  void _handleUnauthorizedWithDialog() async {
    final context = NavigationService.instance.currentContext;
    if (context != null) {
      // Clear token first
      await TokenStorage.clearToken();

      // Show dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppTheme.errorRed),
              SizedBox(width: 8),
              Text('Session Expired'),
            ],
          ),
          content: const Text(
            'Your session has expired. Please login again to continue.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: AppTheme.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                NavigationService.instance.pushWidgetAndClearStack(
                  const LoginScreen(),
                );
              },
              child: const Text('Login Again'),
            ),
          ],
        ),
      );
    } else {
      // Fallback if no context
      TokenStorage.clearToken();
      NavigationService.instance.pushWidgetAndClearStack(const LoginScreen());
    }
  }
}
