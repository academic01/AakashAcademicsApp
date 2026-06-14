import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/gradients.dart';
import '../../../core/utils/content_filter.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/student_profile_service.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/gradient_category_card.dart';
import '../../widgets/stat_pill.dart';
import '../../widgets/animated_progress_card.dart';
import '../../widgets/course_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StudentProfileService _studentProfileService = StudentProfileService();
  final DatabaseService _dbService = DatabaseService();
  StudentProfile? _profile;
  bool _announcementDismissed = false;

  String _studentName = 'Student';
  String? _userCategory;
  bool _profileComplete = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUserData();
  }

  Future<void> _loadProfile() async {
    final profile = await _studentProfileService.loadProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
    
    if (!doc.exists || doc.data() == null) return;
    
    final data = doc.data()!;
    
    if (mounted) {
      setState(() {
        _studentName = (data['name'] as String?)?.trim().isNotEmpty == true
            ? data['name'] as String
            : (data['phone'] as String? ?? 'Student');
        
        _profileComplete = data['isProfileComplete'] as bool? ?? false;
        
        _userCategory = ContentFilter.getCategoryFromProfile(
          targetCourse: data['targetCourse'] as String?,
          targetExam: data['targetExam'] as String?,
          currentClass: data['currentClass'] as String?,
        );
      });
    }
  }

  Future<void> _refreshDashboard() async {
    await Future.delayed(const Duration(seconds: 1));
    await _loadProfile();
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
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

    return StreamBuilder<DocumentSnapshot>(
      stream: _dbService.streamSiteSettings(),
      builder: (context, settingsSnapshot) {
        Map<String, dynamic>? settings;
        if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
          settings = settingsSnapshot.data!.data() as Map<String, dynamic>?;
        }

        final showAnnBar = settings?['showAnnouncementBar'] == true;
        final annText = settings?['announcementText']?.toString() ?? '';
        final annLink = settings?['announcementLink']?.toString() ?? '';

        final showTicker = settings?['showTicker'] == true;
        final tickerItems = List<String>.from(settings?['tickerItems'] ?? []);

        final heroHeading1 = settings?['heroHeading1']?.toString() ?? '';
        final heroHeading2 = settings?['heroHeading2']?.toString() ?? '';
        final heroSubheading = settings?['heroSubheading']?.toString() ?? '';
        final statsList = settings?['stats'] as List<dynamic>?;

        return Scaffold(
          backgroundColor: bgColor,
          body: RefreshIndicator(
            onRefresh: _refreshDashboard,
            color: isDark ? AppColors.secondary : AppColors.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (showAnnBar && annText.isNotEmpty && !_announcementDismissed)
                  SliverToBoxAdapter(
                    child: _buildAnnouncementBar(annText, annLink),
                  ),
                if (showTicker && tickerItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildScrollingTicker(tickerItems, isDark),
                  ),
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
                                _studentName,
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
                        if (user?.uid == null)
                          IconButton(
                            icon: Icon(
                              Icons.notifications_none_rounded,
                              color: primaryTextColor,
                            ),
                            onPressed: () {},
                          )
                        else
                          StreamBuilder<int>(
                            stream: UserService().unreadNotificationCount(user!.uid),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.notifications_none_rounded,
                                      color: primaryTextColor,
                                    ),
                                    onPressed: () => context.push('/notifications'),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            count > 9 ? '9+' : '$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Live Class Banner (Pulsing and animated)
            SliverToBoxAdapter(
              child: StreamBuilder<Map<String, dynamic>?>(
                stream: _dbService.streamCurrentLiveClass(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return const SizedBox.shrink();
                  }

                  final liveClass = snapshot.data!;
                  final title = liveClass['title'] ?? 'Live Class';
                  final faculty = liveClass['facultyName'] ?? 'Faculty';
                  final subject = liveClass['subject'] ?? 'Subject';
                  final streamUrl = liveClass['streamUrl'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Text('🔴 ', style: TextStyle(fontSize: 10)),
                                    Text(
                                      'LIVE NOW',
                                      style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                               .scaleXY(begin: 0.95, end: 1.05, duration: 800.ms),
                              Text(
                                subject.toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'with $faculty',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push(
                                  '/live/embed/${liveClass['id']}?url=${Uri.encodeComponent(streamUrl)}&title=${Uri.encodeComponent(title)}&faculty=${Uri.encodeComponent(faculty)}');
                            },
                            icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFFEF4444)),
                            label: const Text(
                              'Join Classroom',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1);
                },
              ),
            ),

            SliverToBoxAdapter(
              child: _buildHeroCard(
                heroHeading1.isNotEmpty ? heroHeading1 : 'Shape Your Future',
                heroHeading2.isNotEmpty ? heroHeading2 : 'With Aakash Academics',
                heroSubheading.isNotEmpty ? heroSubheading : 'Learn from the best educators in India',
                (statsList != null && statsList.isNotEmpty)
                    ? statsList
                    : const [
                        {'number': '10k+', 'label': 'Students'},
                        {'number': '500+', 'label': 'Classes'},
                        {'number': '100+', 'label': 'Tests'},
                      ],
                isDark,
              ),
            ),

            // Redesigned Carousel containing Vibrant Gradient category cards (Filtered strictly by student's target program)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  height: 180,
                  child: Builder(
                    builder: (context) {
                      final userCategory = ContentFilter.getCategoryFromProfile(
                        targetCourse: _profile?.selectedCourse ?? user?.targetCourse,
                        targetExam: _profile?.classLevel ?? user?.targetExam,
                        currentClass: user?.currentClass,
                      );

                      final allCategoryCards = [
                        (
                          'school',
                          GradientCategoryCard(
                            categoryName: 'School Prep (VI-X)',
                            tagline: 'Maths · Science · SST',
                            emoji: '📐',
                            gradient: AppGradients.school,
                            onTap: () => context.go('/courses'),
                          )
                        ),
                        (
                          'senior',
                          GradientCategoryCard(
                            categoryName: 'Boards Exam (XI-XII)',
                            tagline: 'Science · Commerce · Humanities',
                            emoji: '🔬',
                            gradient: AppGradients.boards,
                            onTap: () => context.go('/courses'),
                          )
                        ),
                        (
                          'govt',
                          GradientCategoryCard(
                            categoryName: 'Govt Jobs Preparation',
                            tagline: 'SSC · Railway · DSSSB',
                            emoji: '🏆',
                            gradient: AppGradients.govtJobs,
                            onTap: () => context.go('/courses'),
                          )
                        ),
                        (
                          'cuet',
                          GradientCategoryCard(
                            categoryName: 'CUET 2026 Batch',
                            tagline: 'Vibrant live coaching & syllabus',
                            emoji: '🎓',
                            gradient: AppGradients.cuet,
                            onTap: () => context.go('/courses'),
                          )
                        ),
                      ];

                      final filteredCards = userCategory != null
                          ? allCategoryCards
                              .where((item) => item.$1 == userCategory)
                              .map((item) => item.$2)
                              .toList()
                          : allCategoryCards.map((item) => item.$2).toList();

                      return CarouselSlider(
                        options: CarouselOptions(
                          height: 180,
                          viewportFraction: 0.88,
                          enlargeCenterPage: true,
                          autoPlay: filteredCards.length > 1,
                          autoPlayInterval: const Duration(seconds: 6),
                          enableInfiniteScroll: filteredCards.length > 1,
                        ),
                        items: filteredCards,
                      );
                    },
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFeaturedCourses(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildFeaturedCourses() {
    // Build query based on whether we have a user category
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('courses')
        .where('status', isEqualTo: 'active');
    
    // If user has a category, filter by it — NO isFeatured requirement
    if (_userCategory != null && _profileComplete) {
      query = query.where('category', isEqualTo: _userCategory);
    }
    
    // Always order by enrollments (most popular first)
    query = query.orderBy('totalEnrollments', descending: true);
    
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCourseShimmer();
        }
        
        if (snapshot.hasError) {
          debugPrint('Courses error: ${snapshot.error}');
          return _buildCoursesError();
        }
        
        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyWithFallback();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            if (_profileComplete && _userCategory != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'For You — ${ContentFilter.getCategoryDisplayName(_userCategory)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            // Course list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length > 5 ? 5 : docs.length,
              itemBuilder: (ctx, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                data['id'] = docs[i].id;
                return CourseCard(
                  title: data['title'] ?? '',
                  facultyName: data['facultyName'] ?? '',
                  examType: data['category'] ?? '',
                  rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
                  price: (data['price'] as num?)?.toDouble() ?? 0.0,
                  originalPrice: (data['originalPrice'] as num?)?.toDouble(),
                  isFree: data['isFree'] ?? false,
                  isComingSoon: data['status'] == 'coming_soon',
                  onTap: () => context.go('/courses/detail/${docs[i].id}'),
                  onEnroll: () {},
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyWithFallback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_userCategory != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No ${ContentFilter.getCategoryDisplayName(_userCategory)} courses yet — explore all courses below',
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
              ),
            ),
          ),
        
        // Fallback: all active courses
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('courses')
              .where('status', isEqualTo: 'active')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return _buildCourseShimmer();
            final fallbackDocs = snap.data?.docs ?? [];
            if (fallbackDocs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '📚 Courses coming soon!',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fallbackDocs.length,
              itemBuilder: (c, i) {
                final d = fallbackDocs[i].data() as Map<String, dynamic>;
                d['id'] = fallbackDocs[i].id;
                return CourseCard(
                  title: d['title'] ?? '',
                  facultyName: d['facultyName'] ?? '',
                  examType: d['category'] ?? '',
                  rating: (d['rating'] as num?)?.toDouble() ?? 4.5,
                  price: (d['price'] as num?)?.toDouble() ?? 0.0,
                  originalPrice: (d['originalPrice'] as num?)?.toDouble(),
                  isFree: d['isFree'] ?? false,
                  isComingSoon: d['status'] == 'coming_soon',
                  onTap: () => context.go('/courses/detail/${fallbackDocs[i].id}'),
                  onEnroll: () {},
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseShimmer() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildCoursesError() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('Error loading courses'),
      ),
    );
  }

  Widget _buildAnnouncementBar(String text, String link) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEF4444),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: link.isNotEmpty
                  ? () async {
                      final Uri url = Uri.parse(link);
                      try {
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      } catch (_) {}
                    }
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '📢  ',
                    style: TextStyle(fontSize: 14),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (link.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _announcementDismissed = true;
              });
            },
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollingTicker(List<String> items, bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 20,
        child: MarqueeTicker(
          items: items,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF374151),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    String heading1,
    String heading2,
    String subheading,
    List<dynamic>? stats,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2240), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D2240).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading1,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              heading2,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subheading.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subheading,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (stats != null && stats.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: stats.map((statItem) {
                  final map = statItem as Map<String, dynamic>? ?? {};
                  final numVal = map['number']?.toString() ?? '';
                  final labelVal = map['label']?.toString() ?? '';
                  return Column(
                    children: [
                      Text(
                        numVal,
                        style: const TextStyle(
                          color: Color(0xFFF5A623),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labelVal,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MarqueeTicker extends StatefulWidget {
  final List<String> items;
  final TextStyle? style;
  final double speed;

  const MarqueeTicker({
    super.key,
    required this.items,
    this.style,
    this.speed = 40.0,
  });

  @override
  State<MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<MarqueeTicker> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (!_scrollController.hasClients) return;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent == 0) return;
    
    final duration = Duration(milliseconds: (maxScrollExtent / widget.speed * 1000).toInt());
    
    _scrollController.animateTo(
      maxScrollExtent,
      duration: duration,
      curve: Curves.linear,
    ).then((_) {
      if (mounted) {
        _scrollController.jumpTo(0);
        _startScrolling();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.items.join('   •   ');
    final displayText = '$text   •   $text   •   $text';
    
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        displayText,
        style: widget.style,
      ),
    );
  }
}
