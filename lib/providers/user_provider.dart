import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../core/constants/app_constants.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isProfileComplete = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isProfileComplete => _isProfileComplete;
  bool get isLoggedIn => _user != null;

  // Called after login success
  void setUser(UserModel user) {
    _user = user;
    _isProfileComplete = user.isProfileComplete;
    notifyListeners();
  }

  // Called after profile form submit
  void updateProfile(UserModel updatedUser) {
    _user = updatedUser;
    _isProfileComplete = true;
    notifyListeners();
    _saveToPrefs();
  }

  // Called on skip profile
  void skipProfile() {
    if (_user != null) {
      _user = _user!.copyWith(isProfileComplete: false);
    }
    _isProfileComplete = false;
    notifyListeners();
  }

  // Add XP for gamification
  void addXP(int xp, String reason) {
    if (_user != null) {
      final newXp = _user!.xp + xp;
      final newRank = _calculateRank(newXp);
      _user = _user!.copyWith(xp: newXp, rank: newRank);
      notifyListeners();
      _saveToPrefs();
    }
  }

  // Calculate rank based on XP
  String _calculateRank(int totalXp) {
    if (totalXp < 100) return 'Rookie';
    if (totalXp < 500) return 'Explorer';
    if (totalXp < 1000) return 'Scholar';
    if (totalXp < 2000) return 'Master';
    if (totalXp < 5000) return 'Legend';
    return 'Grandmaster';
  }

  // Load user from SharedPreferences
  Future<void> loadFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      final token = prefs.getString('token');

      if (userData != null && token != null) {
        _user = UserModel.fromJson(jsonDecode(userData));
        _isProfileComplete = _user!.isProfileComplete;
      }
    } catch (e) {
      debugPrint('Error loading user from prefs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save user to SharedPreferences
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) {
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        await prefs.setString('token', _user!.token ?? '');
        await prefs.setBool(StorageKeys.profileComplete, _isProfileComplete);
      }
    } catch (e) {
      debugPrint('Error saving user to prefs: $e');
    }
  }

  // Clear profile data (used when skipping)
  void clearProfile() {
    _isProfileComplete = false;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('token');
      await prefs.remove(StorageKeys.profileComplete);

      _user = null;
      _isProfileComplete = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  // Check if user needs profile completion
  bool get needsProfile => _user != null && !_isProfileComplete;

  // Get personalized content filter based on target course
  String? get contentFilter {
    if (!_isProfileComplete) return null;
    return _user?.targetCourse;
  }

  // Get greeting name (first name from full name)
  String get greetingName {
    if (_user?.name == null || _user!.name!.isEmpty) {
      return 'Student';
    }
    return _user!.name!.split(' ').first;
  }
}
