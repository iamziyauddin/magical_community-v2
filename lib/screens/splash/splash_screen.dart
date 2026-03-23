import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/data/services/auth_service.dart';
import 'package:magical_community/screens/auth/login_screen.dart';
import 'package:magical_community/screens/main/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Add a small delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (mounted) {
        if (isLoggedIn) {
          // User is logged in, navigate to main screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          // User is not logged in, navigate to login screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      // On error, navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo (same as LoginScreen)
            SizedBox(
              width: 120,
              height: 120,
              child: Image.asset(
                'assets/icons/ic_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if asset fails to load
                  return const Icon(
                    Icons.favorite,
                    size: 60,
                    color: Colors.white,
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // App Title
            const Text(
              'Magical Community',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Mission, healthy & happy life',
              style: TextStyle(fontSize: 16, color: AppTheme.lightGrey),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
            ),
            const SizedBox(height: 16),

            // Loading text
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 14, color: AppTheme.lightGrey),
            ),
          ],
        ),
      ),
    );
  }
}
