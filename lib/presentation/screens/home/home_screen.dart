import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/gradients.dart';
import '../../../core/utils/content_filter.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/student_profile_service.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/gradient_category_card.dart';
import '../../widgets/stat_pill.dart';
import '../../widgets/animated_progress_card.dart';
import '../../widgets/redesigned_course_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StudentProfileService _studentProfileService = StudentProfileService();
  final DatabaseService _dbService = DatabaseService();
  StudentProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _studentProfileService.loadProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _refreshDashboard() async {
    await Future.delayed(const Duration(seconds: 1));
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final studentName = userProvider.greetingName;
    final studentInitial = _profile?.initial ?? 'S';
    final studentCourse = userProvider.user?.targetCourse ?? 'Complete profile';

    final user = userProvider.user;
    final xp = user?.xp ?? 0;
    final streak = user?.streak ?? 0;
    final rank = user?.rank ?? 'Rookie';

    int nextLevelXP = 1000;
    if (xp >= 15000) {
      nextLevelXP = 30000;
    } else if (xp >= 7000) {
      nextLevelXP = 15000;
    } else if (xp >= 3000) {
      nextLevelXP = 7000;
    } else if (xp >= 1000) {
      nextLevelXP = 3000;
    } else {
      nextLevelXP = 1000;
    }

    final progress = xp / nextLevelXP;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Modern Light background: soft off-white/lavender-grey
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF7F8FC);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0D2240);
    final secondaryTextColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final cardBgColor = isDark ? AppColors.darkCard : Colors.white;
    final borderCol = isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: isDark ? AppColors.secondary : AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Floating Top Header (Instead of heavy sliver app bar)
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isDark ? AppColors.secondary : AppColors.primary,
                          child: Text(
                            studentInitial,
                            style: TextStyle(
                              color: isDark ? AppColors.darkBackground : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Morning! 🌟',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                studentName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: primaryTextColor,
                                ),
                              ),
                              Text(
                                studentCourse,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quick Streak Flame
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '$streak',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            color: primaryTextColor,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Redesigned Carousel containing Vibrant Gradient category cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  height: 180,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 180,
                      viewportFraction: 0.88,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 6),
                    ),
                    items: [
                      GradientCategoryCard(
                        categoryName: 'School Prep (VI-X)',
                        tagline: 'Maths · Science · SST',
                        emoji: '📐',
                        gradient: AppGradients.school,
                        onTap: () => context.go('/courses'),
                      ),
                      GradientCategoryCard(
                        categoryName: 'Boards Exam (XI-XII)',
                        tagline: 'Science · Commerce · Humanities',
                        emoji: '🔬',
                        gradient: AppGradients.boards,
                        onTap: () => context.go('/courses'),
                      ),
                      GradientCategoryCard(
                        categoryName: 'Govt Jobs Preparation',
                        tagline: 'SSC · Railway · DSSSB',
                        emoji: '🏆',
                        gradient: AppGradients.govtJobs,
                        onTap: () => context.go('/courses'),
                      ),
                      GradientCategoryCard(
                        categoryName: 'CUET 2026 Batch',
                        tagline: 'Vibrant live coaching & syllabus',
                        emoji: '🎓',
                        gradient: AppGradients.cuet,
                        onTap: () => context.go('/courses'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Game Stats Container: Streak, XP and Rank
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: StatPill(
                          emoji: '🔥',
                          value: '$streak Days',
                          label: 'STREAK',
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                      Container(height: 30, width: 1, color: borderCol),
                      Expanded(
                        child: StatPill(
                          emoji: '⭐',
                          value: '$xp XP',
                          label: 'POINTS',
                          color: const Color(0xFFF5A623),
                        ),
                      ),
                      Container(height: 30, width: 1, color: borderCol),
                      Expanded(
                        child: StatPill(
                          emoji: '🏆',
                          value: rank,
                          label: 'LEAGUE',
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Today's Goal Progress Indicator
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: AnimatedProgressCard(progress: progress),
              ),
            ),

            // Featured Courses Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Courses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: primaryTextColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/courses'),
                      child: const Text(
                        'See All →',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF5A623),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Featured Courses Grid/List from Firestore
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _dbService.streamFeaturedCourses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  var courses = snapshot.data ?? [];

                  final userCategory = getCategoryFromProfile(user?.targetCourse, user?.targetExam);
                  if (userCategory != null) {
                    courses = courses.where((c) {
                      final category = (c['category'] ?? '').toString().toLowerCase();
                      if (userCategory == 'senior') {
                        return category == 'senior' || category == 'boards';
                      }
                      return category == userCategory;
                    }).toList();
                  }

                  if (courses.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text('No featured courses matching your profile goals'),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: RedesignedCourseCard(
                            course: courses[index],
                            index: index,
                            onTap: () {
                              context.go('/courses/detail/${courses[index]['id']}');
                            },
                          ),
                        );
                      },
                      childCount: courses.length,
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
