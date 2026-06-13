import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/student_profile_service.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/user_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String? pendingCourseId;

  const CompleteProfileScreen({super.key, this.pendingCourseId});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final StudentProfileService _studentProfileService = StudentProfileService();
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
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    final userProvider = context.read<UserProvider>();

    setState(() {
      _phoneController.text = userProvider.user?.phone ?? '';
      _nameController.text = userProvider.user?.name ?? '';
      _schoolController.text = userProvider.user?.schoolCollege ?? '';
      _selectedClass = userProvider.user?.currentClass;
      _selectedCourse = userProvider.user?.targetCourse;
      _selectedExam = userProvider.user?.targetExam;
    });
  }

  void _autoSuggestCourse(String cls) {
    if (cls.contains('Class 6') ||
        cls.contains('Class 7') ||
        cls.contains('Class 8') ||
        cls.contains('Class 9') ||
        cls.contains('Class 10')) {
      setState(() => _selectedCourse = 'School Success Program (VI-X)');
    } else if (cls.contains('Class 11') || cls.contains('Class 12')) {
      setState(() => _selectedCourse = 'Senior Secondary Program (XI-XII)');
    } else if (cls.contains('Graduated')) {
      setState(() => _selectedCourse = 'Government Jobs Bundle');
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF444444),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _skipProfile() async {
    if (_phoneController.text.length != 10) {
      _showError('Please enter a valid 10-digit mobile number before skipping');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final enteredPhone = '+91${_phoneController.text}';
      final isRegistered = await _isPhoneAlreadyRegistered(enteredPhone);
      if (isRegistered) {
        setState(() => _isSubmitting = false);
        _showAlreadyRegisteredDialog();
        return;
      }

      await UserService().savePhoneAndSkip(phone: enteredPhone);
      setState(() => _isSubmitting = false);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profileComplete', false);
    await prefs.setBool('profileSkipped', true);

    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    userProvider.skipProfile();

    context.go('/home');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '💡 Complete your profile anytime from Profile tab to get personalized content!',
        ),
        backgroundColor: const Color(0xFF0D2240),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Complete Now',
          textColor: const Color(0xFFF5A623),
          onPressed: () {},
        ),
      ),
    );
  }

  void _submitProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (_phoneController.text.length != 10) {
      _showError('Enter valid 10-digit number');
      return;
    }
    if (_selectedClass == null) {
      _showError('Please select your class');
      return;
    }
    if (_selectedCourse == null) {
      _showError('Please select a course');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final enteredPhone = '+91${_phoneController.text}';
      final isRegistered = await _isPhoneAlreadyRegistered(enteredPhone);
      if (isRegistered) {
        setState(() => _isSubmitting = false);
        _showAlreadyRegisteredDialog();
        return;
      }

      await UserService().saveProfile(
        name: _nameController.text.trim(),
        schoolCollege: _schoolController.text,
        currentClass: _selectedClass!,
        targetCourse: _selectedCourse!,
        targetExam: _selectedExam ?? '',
        phone: enteredPhone,
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('profileComplete', true);
      await prefs.setBool('profileSkipped', false);

      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.user;

      final updatedUser = UserModel(
        uid: currentUser?.uid ?? 'user_${_phoneController.text}',
        phone: _phoneController.text,
        name: _nameController.text.trim(),
        schoolCollege: _schoolController.text,
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

      setState(() => _isSubmitting = false);

      if (!mounted) return;

      context.go('/home');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Welcome ${updatedUser.name}! Your dashboard is ready!',
          ),
          backgroundColor: const Color(0xFF22C55E),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Failed to save profile. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _isPhoneAlreadyRegistered(String enteredPhone) async {
    final currentUser = context.read<UserProvider>().user;
    final currentUid = currentUser?.uid;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: enteredPhone)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final existingUid = query.docs.first.id;
      if (existingUid != currentUid) {
        return true;
      }
    }
    return false;
  }

  void _showAlreadyRegisteredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Phone Already Registered'),
        content: const Text(
          'This phone number is already registered. Please login using Phone OTP instead.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final userProvider = context.read<UserProvider>();
              await userProvider.logout();
              await SharedPreferences.getInstance().then((prefs) {
                prefs.clear();
              });
              if (mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D2240)),
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2240),
        elevation: 0,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _skipProfile,
            child: const Text(
              'Skip',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D2240), Color(0xFF1a3a6b)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personalize Your Experience',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help us show content tailored to you from the very first session.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('Full Name'),
            _buildInputField(
              controller: _nameController,
              hintText: 'Enter your full name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('Mobile Number'),
            _buildInputField(
              controller: _phoneController,
              hintText: 'Your mobile number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              prefixText: '+91 ',
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('School / College'),
            _buildInputField(
              controller: _schoolController,
              hintText: 'Enter school or college name',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('Current Class'),
            _buildDropdownField(
              value: _selectedClass,
              hintText: 'Select your class',
              items: _classOptions,
              onChanged: (value) {
                setState(() {
                  _selectedClass = value;
                  _autoSuggestCourse(value!);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('Course You Want to Enroll In'),
            _buildDropdownField(
              value: _selectedCourse,
              hintText: 'Select a course',
              items: _getCourseOptions(),
              onChanged: (value) {
                setState(() => _selectedCourse = value);
              },
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('Target Exam'),
            _buildDropdownField(
              value: _selectedExam,
              hintText: 'Select target exam (Optional)',
              items: _examOptions,
              onChanged: (value) {
                setState(() => _selectedExam = value);
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF5A623).withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFF5A623),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These details will automatically appear across Home, Profile and the rest of the app, and you can update them later from your profile.',
                      style: TextStyle(
                        color: const Color(0xFFF5A623),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _skipProfile,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0D2240)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    color: Color(0xFF0D2240),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2240),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  disabledBackgroundColor: const Color(
                    0xFF0D2240,
                  ).withOpacity(0.5),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue to Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF9F9F9),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: const Color(0xFF0D2240), size: 20),
          ),
          Container(width: 1, height: 24, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixText: prefixText,
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF9F9F9),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.arrow_drop_down,
              color: const Color(0xFF0D2240),
              size: 20,
            ),
          ),
          Container(width: 1, height: 24, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(
                  hintText,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                  ),
                ),
                icon: const SizedBox.shrink(),
                isExpanded: true,
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Color(0xFF0D2240),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_drop_down, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}
