import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/student_profile.dart';

class StudentProfileService {
  static const List<String> availableClasses = [
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11',
    'Class 12',
  ];

  static const List<String> availableCourses = [
    'School Success Program',
    'CUET 2026',
    'JEE Foundation',
    'NEET Foundation',
    'Govt Jobs Prep',
    'Commerce Excellence',
  ];

  Future<StudentProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfile = prefs.getString(StorageKeys.studentProfile);
    if (rawProfile == null || rawProfile.isEmpty) {
      return null;
    }
    return StudentProfile.fromJson(
      jsonDecode(rawProfile) as Map<String, dynamic>,
    );
  }

  Future<void> saveProfile(StudentProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.studentProfile,
      jsonEncode(profile.toJson()),
    );
    await prefs.setBool(StorageKeys.profileComplete, true);
    await prefs.setString(StorageKeys.authPhone, profile.phoneNumber);
  }

  Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.profileComplete) ?? false;
  }

  Future<String?> getAuthenticatedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.authPhone);
  }

  Future<void> setAuthenticatedPhone(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.authPhone, phoneNumber);
  }

  Future<void> resetProfileIfPhoneChanged(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final existingPhone = prefs.getString(StorageKeys.authPhone);
    if (existingPhone != null &&
        existingPhone.isNotEmpty &&
        existingPhone != phoneNumber) {
      await clearProfile();
    }
    await prefs.setString(StorageKeys.authPhone, phoneNumber);
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.studentProfile);
    await prefs.remove(StorageKeys.profileComplete);
  }

  Future<StudentProfile?> updateSelectedCourse(String courseTitle) async {
    final profile = await loadProfile();
    if (profile == null) return null;

    final updatedProfile = StudentProfile(
      fullName: profile.fullName,
      phoneNumber: profile.phoneNumber,
      classLevel: profile.classLevel,
      selectedCourse: courseTitle,
      schoolName: profile.schoolName,
    );

    await saveProfile(updatedProfile);
    return updatedProfile;
  }

  static bool isCourseMatch(String selectedCourse, String courseTitle) {
    final selected = _normalize(selectedCourse);
    final current = _normalize(courseTitle);
    if (selected.isEmpty || current.isEmpty) {
      return false;
    }

    if (selected == current ||
        selected.contains(current) ||
        current.contains(selected)) {
      return true;
    }

    final selectedTokens = selected.split(' ').where((token) => token.isNotEmpty);
    final currentTokens = current.split(' ').where((token) => token.isNotEmpty);

    final overlap = selectedTokens.where(currentTokens.contains).length;
    return overlap >= 2;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
