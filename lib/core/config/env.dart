/// Simple compile-time environment configuration.
///
/// Use --dart-define to set values at build/run time, e.g.:
/// flutter run --dart-define=API_BASE_URL=https://api.example.com
/// flutter run --dart-define=ENVIRONMENT=dev
/// flutter run --dart-define=ENVIRONMENT=prod
class Env {
  // Environment type (dev, prod)
  static const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  // Development API URL (temporarily unused)
  static const _devApiUrl = 'https://mgc-api-dev.onrender.com/api/rest';

  // Production API URL
  static const _prodApiUrl = 'https://api.magicalcommunity.in/api/rest';

  // Get API base URL based on environment
  static String get apiBaseUrl {
    return isProd ? _prodApiUrl : _devApiUrl;
  }

  // Legacy support - can also be overridden directly
  static const apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Final API URL - uses override if provided, otherwise uses environment-based URL
  static String get finalApiBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) {
      return apiBaseUrlOverride;
    }
    return apiBaseUrl;
  }

  // Timeout configurations
  static const connectTimeoutMs = int.fromEnvironment(
    'API_CONNECT_TIMEOUT_MS',
    defaultValue: 30000, // 30s to allow slower connects
  );

  static const receiveTimeoutMs = int.fromEnvironment(
    'API_RECEIVE_TIMEOUT_MS',
    defaultValue: 60000, // 60s to avoid premature receiveTimeout on slow APIs
  );

  // Helper methods for environment checking
  static bool get isDev =>
      environment.toLowerCase() == 'dev' ||
      environment.toLowerCase() == 'development';
  static bool get isProd =>
      environment.toLowerCase() == 'prod' ||
      environment.toLowerCase() == 'production';

  // Get current environment info for debugging
  static String get currentEnvironmentInfo {
    return 'Environment: $environment\nAPI URL: $finalApiBaseUrl';
  }

  // Print environment info (useful for debugging)
  static void printEnvironmentInfo() {
    print('=== Environment Configuration ===');
    print('Environment: $environment');
    print('API Base URL: $finalApiBaseUrl');
    print('Is Development: $isDev');
    print('Is Production: $isProd');
    print('================================');
  }
}
