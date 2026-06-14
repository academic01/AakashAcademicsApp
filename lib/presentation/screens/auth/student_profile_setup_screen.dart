import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

import '../../../data/models/user_model.dart';
import '../../../data/services/student_profile_service.dart';
import '../../../providers/user_provider.dart';

class StudentProfileSetupScreen extends StatefulWidget {
  const StudentProfileSetupScreen({super.key});

  @override
  State<StudentProfileSetupScreen> createState() =>
      _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState extends State<StudentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _profileService = StudentProfileService();

  String? _phoneNumber;
  String? _selectedClass;
  String? _selectedCourse;
  String? _selectedExam;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileDraft();
  }

  Future<void> _loadProfileDraft() async {
    final profile = await _profileService.loadProfile();
    final authPhone = await _profileService.getAuthenticatedPhone();
    if (!mounted) return;
    setState(() {
      _phoneNumber = authPhone ?? profile?.phoneNumber ?? '';
      _nameController.text = profile?.fullName ?? '';
      _schoolController.text = profile?.schoolName ?? '';
      _selectedClass =
          profile?.classLevel ?? StudentProfileService.availableClasses.first;
      _selectedCourse =
          profile?.selectedCourse ??
          StudentProfileService.availableCourses.first;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() ||
        _selectedClass == null ||
        _selectedCourse == null ||
        _phoneNumber == null ||
        _phoneNumber!.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Create user model
      final user = UserModel(
        uid: 'user_$_phoneNumber',
        phone: _phoneNumber!,
        name: _nameController.text.trim(),
        schoolCollege: _schoolController.text.trim().isEmpty
            ? null
            : _schoolController.text.trim(),
        currentClass: _selectedClass,
        targetCourse: _selectedCourse,
        targetExam: _selectedExam,
        isProfileComplete: true,
        createdAt: DateTime.now(),
      );

      // Save to SharedPreferences
      await prefs.setString('user', jsonEncode(user.toJson()));
      await prefs.setBool(StorageKeys.profileComplete, true);
      await prefs.setBool(StorageKeys.profileSkipped, false);

      // Update provider
      if (mounted) {
        context.read<UserProvider>().updateProfile(user);

        setState(() => _isSaving = false);

        // Go to personalized dashboard
        context.go('/home');

        // Welcome message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Welcome! Your dashboard is ready!'),
            backgroundColor: Color(0xFF22C55E),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _skipProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.profileComplete, false);
    await prefs.setBool(StorageKeys.profileSkipped, true);

    // Update provider
    if (mounted) {
      context.read<UserProvider>().skipProfile();

      // Go to full unfiltered dashboard
      context.go('/home');

      // Show tip snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '💡 Complete your profile anytime from Profile tab to get personalized content!',
          ),
          backgroundColor: Color(0xFF0D2240),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Complete Your Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0D2240),
                        const Color(0xFF1A3A6B).withOpacity(0.92),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        color: Color(0xFFF5A623),
                        size: 34,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Welcome to Aakash Academics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Set up your personal details once so your dashboard, profile and learning journey feel tailored to you from the very first session.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mobile Number',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '+91 ${_phoneNumber ?? ''}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D2240),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _schoolController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'School / College',
                    hintText: 'Optional',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  items: StudentProfileService.availableClasses
                      .map(
                        (classValue) => DropdownMenuItem(
                          value: classValue,
                          child: Text(classValue),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedClass = value),
                  decoration: const InputDecoration(
                    labelText: 'Current Class',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  validator: (value) =>
                      value == null ? 'Please choose your class' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourse,
                  items: StudentProfileService.availableCourses
                      .map(
                        (course) => DropdownMenuItem(
                          value: course,
                          child: Text(course),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCourse = value),
                  decoration: const InputDecoration(
                    labelText: 'Course You Want to Enroll In',
                    prefixIcon: Icon(Icons.rocket_launch_outlined),
                  ),
                  validator: (value) =>
                      value == null ? 'Please choose a course' : null,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFFF5A623),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'These details will automatically appear across Home, Profile and the rest of the app, and you can update them later from your profile.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF7C5A00),
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _skipProfile,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF0D2240)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text('Skip for now'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue to Dashboard'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
