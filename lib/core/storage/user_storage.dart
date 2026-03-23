import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../data/models/login_response.dart';

class UserStorage {
  static const _keyUser = 'current_user';
  static const _keyClub = 'current_club';

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyUser,
      jsonEncode({
        'id': user.id,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'role': user.role,
        'memberRole': user.memberRole,
        'isActive': user.isActive,
        'createdAt': user.createdAt,
        'updatedAt': user.updatedAt,
      }),
    );
  }

  static Future<void> saveClub(Club club) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyClub,
      jsonEncode({
        'id': club.id,
        'name': club.name,
        'code': club.code,
        'location': club.location,
        'phoneNumber': club.phoneNumber,
        'email': club.email,
        'isActive': club.isActive,
      }),
    );
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userData);
    }
    return null;
  }

  static Future<Club?> getClub() async {
    final prefs = await SharedPreferences.getInstance();
    final clubJson = prefs.getString(_keyClub);
    if (clubJson != null) {
      final clubData = jsonDecode(clubJson) as Map<String, dynamic>;
      return Club.fromJson(clubData);
    }
    return null;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyClub);
  }
}
