import '../storage/user_storage.dart';
import '../storage/token_storage.dart';
import '../../data/models/login_response.dart';

/// Helper class for managing current session
class SessionManager {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();
  SessionManager._();

  User? _currentUser;
  Club? _currentClub;

  /// Initialize session from stored data
  Future<void> initialize() async {
    _currentUser = await UserStorage.getUser();
    _currentClub = await UserStorage.getClub();
  }

  /// Get current logged in user
  User? get currentUser => _currentUser;

  /// Get current club
  Club? get currentClub => _currentClub;

  /// Check if user is logged in
  Future<bool> get isLoggedIn async {
    final token = await TokenStorage.getToken();
    return token != null && token.isNotEmpty && _currentUser != null;
  }

  /// Update session data after login
  void updateSession(LoginData loginData) {
    _currentUser = loginData.user;
    _currentClub = loginData.club;
  }

  /// Clear session data
  void clearSession() {
    _currentUser = null;
    _currentClub = null;
  }

  /// Get user full name
  String get userFullName => _currentUser?.fullName ?? 'User';

  /// Get user role
  String get userRole => _currentUser?.role ?? '';

  /// Get club name
  String get clubName => _currentClub?.name ?? '';
}
