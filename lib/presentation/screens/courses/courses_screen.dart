import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/content_filter.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/student_profile_service.dart';

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
      final profile = await _studentProfileService.loadProfile();
      if (profile == null) return;

      final category = getCategoryFromProfile(
        profile.selectedCourse,
        profile.classLevel,
      );
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Courses',
          style: TextStyle(
            color: Color(0xFF0D2240),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '100+ Courses',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '500K+ Students',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFF22C55E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF888888),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF5A623),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final option = _filterOptions[index];
                final isSelected = _selectedFilter == option;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = option);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFF5A623),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : const Color(0xFF888888),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFFF5A623)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_userCategory != null &&
              _selectedFilter.toLowerCase() == _userCategory!.toLowerCase())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF5A623).withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing courses for ${_selectedFilter.toUpperCase()}',
                    style: const TextStyle(
                      color: Color(0xFF0D2240),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Courses List
          Expanded(child: _buildCoursesList()),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    // Determine which category to query
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
                const Icon(Icons.inbox, size: 64, color: Color(0xFFCCCCCC)),
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
            .toList();

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
                const Icon(Icons.search, size: 64, color: Color(0xFFCCCCCC)),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return GestureDetector(
                onTap: () => context.push('/courses/detail/${course['id']}'),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Course Thumbnail
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            course['category'],
                          ).withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Icon(
                          Icons.school,
                          color: _getCategoryColor(course['category']),
                          size: 40,
                        ),
                      ),
                      // Course Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['title'] ?? 'Course',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0D2240),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    course['facultyName'] ?? 'Faculty',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: const Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Color(0xFFFFA500),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${course['rating'] ?? 4.5}',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: const Color(0xFF888888),
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (course['price'] == 0 ||
                                      course['isFree'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF22C55E,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'FREE',
                                        style: TextStyle(
                                          color: Color(0xFF22C55E),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      '₹${course['price'] ?? 0}',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Enroll Button
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/courses/detail/${course['id']}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5A623),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Enroll',
                            style: TextStyle(
                              color: Color(0xFF0D2240),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'cuet':
        return const Color(0xFF7C3AED);
      case 'school':
      case 'boards':
        return const Color(0xFF0D2240);
      case 'govt':
        return const Color(0xFF0891B2);
      case 'jee':
        return const Color(0xFFDC2626);
      case 'neet':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6366F1);
    }
  }
}
