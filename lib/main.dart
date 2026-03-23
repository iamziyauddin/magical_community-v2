import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/core/services/navigation_service.dart';
import 'package:magical_community/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters (will be generated)
  // Hive.registerAdapter(UserTypeAdapter());
  // Hive.registerAdapter(ReferralSourceAdapter());
  // Hive.registerAdapter(UserModelAdapter());
  // Hive.registerAdapter(PaymentTypeAdapter());
  // Hive.registerAdapter(PaymentModeAdapter());
  // Hive.registerAdapter(PaymentModelAdapter());
  // Hive.registerAdapter(AttendanceModelAdapter());
  // Hive.registerAdapter(InventoryModelAdapter());
  // Hive.registerAdapter(InventoryLogModelAdapter());
  // Hive.registerAdapter(AppSettingsAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magical Community',
      navigatorKey: NavigationService.instance.navigatorKey,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
