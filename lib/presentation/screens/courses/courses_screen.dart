import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/course_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/services/student_profile_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final StudentProfileService _studentProfileService = StudentProfileService();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  late TextEditingController _searchController;
  bool _isLoading = false;
  StudentProfile? _profile;

  final List<String> _filterOptions = [
    'All',
    'School VI-X',
    'Boards XI-XII',
    'Govt. Jobs',
    'CUET 2026🆕',
    'Free',
    'JEE🔜',
    'NEET🔜',
  ];

  // Static course data
  final List<CourseData> _allCourses = [
    CourseData(
      id: '1',
      title: 'CUET 2026 Complete Prep',
      facultyName: 'Expert Faculty Team',
      examType: 'cuet',
      rating: 4.9,
      price: 2999,
      isBestseller: true,
      isFree: false,
    ),
    CourseData(
      id: '2',
      title: 'Class 10 Maths Board Prep',
      facultyName: 'Rajesh Kumar',
      examType: 'school',
      rating: 4.7,
      price: 0,
      isFree: true,
      isBestseller: false,
    ),
    CourseData(
      id: '3',
      title: 'Class 12 Science Package',
      facultyName: 'Dr. Priya Singh',
      examType: 'senior',
      rating: 4.8,
      price: 1999,
      isBestseller: false,
      isFree: false,
    ),
    CourseData(
      id: '4',
      title: 'Class 9 Foundation Course',
      facultyName: 'Amit Patel',
      examType: 'school',
      rating: 4.6,
      price: 799,
      isBestseller: false,
      isFree: false,
    ),
    CourseData(
      id: '5',
      title: 'Class 11 Commerce Complete',
      facultyName: 'Neha Sharma',
      examType: 'senior',
      rating: 4.5,
      price: 1499,
      isBestseller: false,
      isFree: false,
    ),
    CourseData(
      id: '6',
      title: 'SSC CGL Complete Course',
      facultyName: 'Vikram Singh',
      examType: 'govt',
      rating: 4.8,
      price: 1299,
      isBestseller: true,
      isFree: false,
    ),
    CourseData(
      id: '7',
      title: 'Railway NTPC Preparation',
      facultyName: 'Arjun Verma',
      examType: 'govt',
      rating: 4.7,
      price: 999,
      isBestseller: false,
      isFree: false,
    ),
    CourseData(
      id: '8',
      title: 'DSSSB Full Preparation',
      facultyName: 'Meera Gupta',
      examType: 'govt',
      rating: 4.6,
      price: 1199,
      isBestseller: false,
      isFree: false,
    ),
    CourseData(
      id: '9',
      title: 'JEE Mains Complete Course',
      facultyName: 'Dr. Aakash Yadav',
      examType: 'jee',
      rating: 4.9,
      price: 3999,
      isComingSoon: true,
      isBestseller: false,
      isFree: false,
    ),
    CourseData(
      id: '10',
      title: 'NEET UG Biology',
      facultyName: 'Dr. Anjali Mehta',
      examType: 'neet',
      rating: 4.8,
      price: 3499,
      isComingSoon: true,
      isBestseller: false,
      isFree: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _studentProfileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  List<CourseData> _getFilteredCourses() {
    List<CourseData> filtered = _allCourses;

    // Apply filter
    switch (_selectedFilter) {
      case 'School VI-X':
        filtered = filtered.where((c) => c.examType == 'school').toList();
        break;
      case 'Boards XI-XII':
        filtered = filtered.where((c) => c.examType == 'senior').toList();
        break;
      case 'Govt. Jobs':
        filtered = filtered.where((c) => c.examType == 'govt').toList();
        break;
      case 'CUET 2026🆕':
        filtered = filtered.where((c) => c.examType == 'cuet').toList();
        break;
      case 'Free':
        filtered = filtered.where((c) => c.isFree).toList();
        break;
      case 'JEE🔜':
        filtered = filtered
            .where((c) => c.examType == 'jee' && c.isComingSoon)
            .toList();
        break;
      case 'NEET🔜':
        filtered = filtered
            .where((c) => c.examType == 'neet' && c.isComingSoon)
            .toList();
        break;
      default:
        // All - no filter
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (c) =>
                c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.facultyName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    final selectedCourse = _profile?.selectedCourse;
    if (selectedCourse != null && selectedCourse.isNotEmpty) {
      filtered = [...filtered]..sort((a, b) {
        final aEnrolled = StudentProfileService.isCourseMatch(
          selectedCourse,
          a.title,
        );
        final bEnrolled = StudentProfileService.isCourseMatch(
          selectedCourse,
          b.title,
        );
        if (aEnrolled == bEnrolled) return 0;
        return aEnrolled ? -1 : 1;
      });
    }

    return filtered;
  }

  Future<void> _enrollInCourse(CourseData course) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.userToken);

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      await _showLoginRequiredDialog();
      return;
    }

    final updatedProfile = await _studentProfileService.updateSelectedCourse(
      course.title,
    );
    if (!mounted) return;

    setState(() {
      _profile = updatedProfile ?? _profile;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Your enrolled course is now ${course.title}.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showLoginRequiredDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Login required'),
        content: const Text(
          'Please login with your phone number to enroll in this course.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _getFilteredCourses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Courses'),
        titleTextStyle: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_profile != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D2240), Color(0xFF1A3A6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bookmark_added_rounded,
                      color: Color(0xFFF5A623),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Course',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _profile!.selectedCourse,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Animated Search Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearching ? 70 : 0,
            color: const Color(0xFFFAFAFA),
            child: _isSearching
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search courses or faculty...',
                        hintStyle: const TextStyle(
                          color: Color(0xFFBBBBBB),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF888888),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                child: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF888888),
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                      ),
                    ),
                  )
                : null,
          ),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: _filterOptions.map((filter) {
                  final isActive = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isActive,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: isActive
                          ? AppColors.primary
                          : Colors.white,
                      labelStyle: TextStyle(
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF555555),
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                      side: isActive
                          ? BorderSide.none
                          : const BorderSide(
                              color: Color(0xFFCCCCCC),
                              width: 1,
                            ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Courses List
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : filteredCourses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = filteredCourses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: CourseCard(
                          title: course.title,
                          facultyName: course.facultyName,
                          examType: course.examType,
                          rating: course.rating,
                          price: course.price,
                          isFree: course.isFree,
                          isEnrolled: (_profile?.selectedCourse != null) &&
                              StudentProfileService.isCourseMatch(
                                _profile!.selectedCourse,
                                course.title,
                              ),
                          isComingSoon: course.isComingSoon,
                          isBestseller: course.isBestseller,
                          onTap: () {
                            context.push('/courses/detail/${course.id}');
                          },
                          onEnroll: () => _enrollInCourse(course),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔍', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'No courses found',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different filter',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ShimmerPlaceholder(),
          ),
        );
      },
    );
  }
}

class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFE5E7EB));
  }
}

// Course data model
class CourseData {
  final String id;
  final String title;
  final String facultyName;
  final String examType;
  final double rating;
  final double price;
  final bool isFree;
  final bool isBestseller;
  final bool isComingSoon;

  CourseData({
    required this.id,
    required this.title,
    required this.facultyName,
    required this.examType,
    required this.rating,
    required this.price,
    this.isFree = false,
    this.isBestseller = false,
    this.isComingSoon = false,
  });
}
