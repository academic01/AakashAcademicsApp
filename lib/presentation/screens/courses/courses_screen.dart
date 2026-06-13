import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/gradients.dart';
import '../../../core/utils/content_filter.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/student_profile_service.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/redesigned_course_card.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StudentProfileService _studentProfileService = StudentProfileService();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  late TextEditingController _searchController;
  String? _userCategory;

  final List<String> _filterOptions = [
    'All',
    'School',
    'Boards',
    'Govt',
    'CUET',
    'Free',
    'JEE',
    'NEET',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      String? targetCourse;
      String? targetExam;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user != null) {
        targetCourse = user.targetCourse;
        targetExam = user.targetExam;
      } else {
        final profile = await _studentProfileService.loadProfile();
        if (profile != null) {
          targetCourse = profile.selectedCourse;
          targetExam = profile.classLevel;
        }
      }

      if (targetCourse == null && targetExam == null) return;

      final category = getCategoryFromProfile(targetCourse, targetExam);
      if (category == null) return;

      final normalized = category.toLowerCase();
      final selection = _filterOptions.firstWhere(
        (option) =>
            option.toLowerCase() == normalized ||
            option.toLowerCase().contains(normalized),
        orElse: () => _selectedFilter,
      );

      if (!mounted) return;
      setState(() {
        _userCategory = category;
        _selectedFilter = selection;
      });
    } catch (_) {
      // Continue without profile
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF7F8FC);
    final cardBgColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Redesigned Header: White card with 4px top gradient accent line
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // Top 4px gradient accent line
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D2240), Color(0xFFF5A623), Color(0xFF4F46E5)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Courses',
                            style: TextStyle(
                              color: Color(0xFF0D2240),
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '100+ Courses',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: const Color(0xFF0D2240),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                '500K+ Students',
                                style: TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar: white rounded-full (50px radius) with soft shadow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF888888)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF888888),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Filter Chips: pill buttons with gradient fill when active
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _filterOptions.length,
                itemBuilder: (context, index) {
                  final option = _filterOptions[index];
                  final isSelected = _selectedFilter == option;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = option);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? (option == 'All' || option == 'Free'
                                  ? const LinearGradient(colors: [Color(0xFF0D2240), Color(0xFF1E3A8A)])
                                  : AppGradients.getGradientForCategory(option))
                              : null,
                          color: isSelected ? null : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_userCategory != null &&
                _selectedFilter.toLowerCase() == _userCategory!.toLowerCase())
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing courses for ${_selectedFilter.toUpperCase()}',
                      style: const TextStyle(
                        color: Color(0xFF0D2240),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = 'All';
                        });
                      },
                      child: const Text(
                        'Show All',
                        style: TextStyle(
                          color: Color(0xFFF5A623),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Courses Grid/List Redesign
            Expanded(child: _buildCoursesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    String? queryCategory;
    if (_selectedFilter != 'All' && _selectedFilter != 'Free') {
      queryCategory = _selectedFilter.toLowerCase();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _dbService.streamCourses(category: queryCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_rounded, size: 64, color: Color(0xFFCCCCCC)),
                const SizedBox(height: 16),
                Text(
                  'No courses available',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          );
        }

        var courses = snapshot.data!.docs
            .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
            .where((c) {
              final status = c['status'];
              return status == 'active' || status == 'coming_soon';
            })
            .toList();

        // Sort in memory: isFeatured (descending), then createdAt (descending)
        courses.sort((a, b) {
          final aFeatured = a['isFeatured'] == true ? 1 : 0;
          final bFeatured = b['isFeatured'] == true ? 1 : 0;
          if (aFeatured != bFeatured) {
            return bFeatured.compareTo(aFeatured);
          }
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        // Apply free filter
        if (_selectedFilter == 'Free') {
          courses = courses
              .where((c) => c['price'] == 0 || c['isFree'] == true)
              .toList();
        }

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          courses = courses.where((c) {
            final title = (c['title'] ?? '').toLowerCase();
            final faculty = (c['facultyName'] ?? '').toLowerCase();
            return title.contains(_searchQuery) ||
                faculty.contains(_searchQuery);
          }).toList();
        }

        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_rounded, size: 64, color: Color(0xFFCCCCCC)),
                const SizedBox(height: 16),
                Text(
                  'No matching courses',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RedesignedCourseCard(
                  course: course,
                  index: index,
                  onTap: () => context.push('/courses/detail/${course['id']}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
