import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/student_profile_service.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final StudentProfileService _studentProfileService = StudentProfileService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _schoolController;
  String? _selectedClass;
  String? _selectedCourse;
  String? _selectedExam;
  bool _isSubmitting = false;

  final List<String> _classOptions = [
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11 (Science)',
    'Class 11 (Commerce)',
    'Class 11 (Humanities)',
    'Class 12 (Science)',
    'Class 12 (Commerce)',
    'Class 12 (Humanities)',
    'Graduated',
  ];

  final List<String> _examOptions = [
    'Class Boards (School)',
    'Class Boards (XI-XII)',
    'CUET 2026',
    'SSC CGL',
    'SSC CHSL',
    'Railway NTPC',
    'Railway Group D',
    'DSSSB',
    'JEE Mains (Coming Soon)',
    'NEET UG (Coming Soon)',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _schoolController = TextEditingController();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  void _loadCurrentProfile() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _phoneController.text = user.phone.replaceFirst('+91', '');
      _schoolController.text = user.schoolCollege ?? '';
      _selectedClass = _classOptions.contains(user.currentClass) ? user.currentClass : null;
      _selectedExam = _examOptions.contains(user.targetExam) ? user.targetExam : null;
      
      final courseOpts = _getCourseOptions();
      _selectedCourse = courseOpts.contains(user.targetCourse) ? user.targetCourse : null;
    }
  }

  void _autoSuggestCourse(String cls) {
    if (cls.contains('Class 6') ||
        cls.contains('Class 7') ||
        cls.contains('Class 8') ||
        cls.contains('Class 9') ||
        cls.contains('Class 10')) {
      _selectedCourse = 'School Success Program (VI-X)';
    } else if (cls.contains('Class 11') || cls.contains('Class 12')) {
      _selectedCourse = 'Senior Secondary Program (XI-XII)';
    } else if (cls.contains('Graduated')) {
      _selectedCourse = 'Government Jobs Bundle';
    }
  }

  List<String> _getCourseOptions() {
    if (_selectedClass == null) {
      return [
        'School Success Program (VI-X)',
        'Senior Secondary Program (XI-XII)',
        'Government Jobs Bundle',
        'CUET 2026 Preparation',
      ];
    }

    if (_selectedClass!.contains('Class 6') ||
        _selectedClass!.contains('Class 7') ||
        _selectedClass!.contains('Class 8') ||
        _selectedClass!.contains('Class 9') ||
        _selectedClass!.contains('Class 10')) {
      return [
        'School Success Program (VI-X)',
        'Mathematics Foundation',
        'Science Foundation',
        'All Subjects Package',
      ];
    }

    if (_selectedClass!.contains('11') || _selectedClass!.contains('12')) {
      return [
        'Senior Secondary Program (XI-XII)',
        'Science Stream Complete',
        'Commerce Stream Complete',
        'Humanities Stream Complete',
        'CUET 2026 Preparation',
      ];
    }

    return [
      'SSC CGL Complete Course',
      'Railway NTPC Preparation',
      'DSSSB Full Preparation',
      'Government Jobs Bundle',
      'CUET 2026 Preparation',
    ];
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      _showSnackBar('Please select your class', Colors.red);
      return;
    }
    if (_selectedCourse == null) {
      _showSnackBar('Please select your target course', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      final enteredPhone = _phoneController.text.trim().isNotEmpty
          ? (_phoneController.text.startsWith('+91')
              ? _phoneController.text.trim()
              : '+91${_phoneController.text.trim()}')
          : currentUser?.phone;

      await UserService().saveProfile(
        name: _nameController.text.trim(),
        schoolCollege: _schoolController.text.trim(),
        currentClass: _selectedClass!,
        targetCourse: _selectedCourse!,
        targetExam: _selectedExam ?? '',
        phone: enteredPhone,
      );

      final updatedUser = UserModel(
        uid: currentUser?.uid ?? '',
        phone: enteredPhone?.replaceFirst('+91', '') ?? currentUser?.phone ?? '',
        name: _nameController.text.trim(),
        schoolCollege: _schoolController.text.trim(),
        currentClass: _selectedClass,
        targetCourse: _selectedCourse,
        targetExam: _selectedExam,
        isProfileComplete: true,
        isNewUser: false,
        token: currentUser?.token,
        xp: currentUser?.xp ?? 0,
        streak: currentUser?.streak ?? 0,
        rank: currentUser?.rank ?? 'Rookie',
        enrolledCourses: currentUser?.enrolledCourses ?? const [],
        createdAt: currentUser?.createdAt ?? DateTime.now(),
      );

      await _studentProfileService.saveProfile(
        StudentProfile(
          fullName: updatedUser.name ?? '',
          phoneNumber: updatedUser.phone,
          classLevel: updatedUser.currentClass ?? '',
          selectedCourse: updatedUser.targetCourse ?? '',
          schoolName: updatedUser.schoolCollege,
        ),
      );

      userProvider.updateProfile(updatedUser);

      _showSnackBar('Profile updated successfully!', Colors.green);
      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkCard : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0D2240);
    final inputBorderColor = isDark ? Colors.white24 : Colors.grey[300]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D2240),
        foregroundColor: Colors.white,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        '📝 Update your academic information below to personalize your feed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Name Field
                    _buildLabel('Full Name'),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _buildInputDecoration('Enter your full name', inputBorderColor, isDark),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Phone Field
                    _buildLabel('Phone Number'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _buildInputDecoration('10-digit phone number', inputBorderColor, isDark).copyWith(
                        prefixText: '+91 ',
                        prefixStyle: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.trim().length != 10) {
                          return 'Enter a valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // School Field
                    _buildLabel('School / College'),
                    TextFormField(
                      controller: _schoolController,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _buildInputDecoration('Enter your school/college name', inputBorderColor, isDark),
                    ),
                    const SizedBox(height: 20),

                    // Class Dropdown
                    _buildLabel('Class / Level'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedClass,
                      dropdownColor: cardBgColor,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _buildInputDecoration('Select Class', inputBorderColor, isDark),
                      items: _classOptions.map((cls) {
                        return DropdownMenuItem(value: cls, child: Text(cls));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedClass = val;
                            _autoSuggestCourse(val);
                            final courseOpts = _getCourseOptions();
                            if (!courseOpts.contains(_selectedCourse)) {
                              _selectedCourse = courseOpts.first;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Course Dropdown
                    _buildLabel('Target Course'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourse,
                      dropdownColor: cardBgColor,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _buildInputDecoration('Select Target Course', inputBorderColor, isDark),
                      items: _getCourseOptions().map((course) {
                        return DropdownMenuItem(value: course, child: Text(course));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCourse = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Exam Dropdown
                    _buildLabel('Target Exam (Optional)'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedExam,
                      dropdownColor: cardBgColor,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _buildInputDecoration('Select Target Exam', inputBorderColor, isDark),
                      items: _examOptions.map((exam) {
                        return DropdownMenuItem(value: exam, child: Text(exam));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedExam = val);
                      },
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProfileChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2240),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, Color borderColor, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D2240), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
