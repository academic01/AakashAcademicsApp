import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/gradients.dart';
import '../../../core/utils/content_filter.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/student_profile_service.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();
  final StudentProfileService _studentProfileService = StudentProfileService();

  Future<bool> _hasTestAccess(String testId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final pkgQuery = await FirebaseFirestore.instance
        .collection('packagePurchases')
        .where('userId', isEqualTo: uid)
        .where('testIds', arrayContains: testId)
        .limit(1)
        .get();

    if (pkgQuery.docs.isNotEmpty) {
      final validTill = (pkgQuery.docs.first.data()['validTill'] as Timestamp?)?.toDate();
      return validTill == null || validTill.isAfter(DateTime.now());
    }

    return false;
  }

  final List<String> _tabs = [
    'All',
    'School',
    'Boards',
    'Govt',
    'CUET',
    'Coming Soon',
  ];

  late final Stream<QuerySnapshot> _testsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadUserProfile();

    // Initialize stream for all tests (filtering will be done in-memory)
    _testsStream = _dbService.streamTests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      String? targetCourse = user?.targetCourse;
      String? targetExam = user?.targetExam;
      String? currentClass = user?.currentClass;

      if (user == null) {
        final profile = await _studentProfileService.loadProfile();
        if (profile != null) {
          targetCourse = profile.selectedCourse;
          targetExam = profile.classLevel;
        }
      }

      final category = ContentFilter.getCategoryFromProfile(
        targetCourse: targetCourse,
        targetExam: targetExam,
        currentClass: currentClass,
      );
      if (category == null) return;

      int tabIndex = -1;
      if (category == 'school') {
        tabIndex = _tabs.indexOf('School');
      } else if (category == 'senior') {
        tabIndex = _tabs.indexOf('Boards');
      } else if (category == 'govt') {
        tabIndex = _tabs.indexOf('Govt');
      } else if (category == 'cuet') {
        tabIndex = _tabs.indexOf('CUET');
      }

      if (tabIndex != -1 && mounted) {
        setState(() {
          _tabController.index = tabIndex;
        });
      }
    } catch (_) {
      // Continue without profile defaults
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF7F8FC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Redesigned stats header as side-by-side gradient stat cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: AppGradients.school,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppGradients.school.colors.first.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📝', style: TextStyle(fontSize: 20)),
                          SizedBox(height: 8),
                          Text(
                            '150+ Tests',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          Text(
                            'Curated Syllabus',
                            style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: AppGradients.govtJobs,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppGradients.govtJobs.colors.first.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎯', style: TextStyle(fontSize: 20)),
                          SizedBox(height: 8),
                          Text(
                            '94% Success',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          Text(
                            'Avg Student Score',
                            style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Banner for Test Packages
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF0D2240)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Text('📦', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Packages Available!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Unlock multiple tests at one price',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/test-packages'),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: const Color(0xFF0D2240),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View All →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

            // Tab bar redesign with pill styling and gradient selection indicators
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 40,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2240), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white54 : const Color(0xFF6B7280),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),

            // Tests List View redone
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) => _buildTestsList(tab)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestsList(String tab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkCard : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0D2240);

    return StreamBuilder<QuerySnapshot>(
      stream: _testsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📝', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 16),
                  Text(
                    'No tests available yet — check back soon!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final test = doc.data() as Map<String, dynamic>;
          final status = test['status'] ?? 'active';

          if (tab == 'Coming Soon') {
            return status == 'coming_soon';
          }

          // For all other tabs, we only show 'active' status
          if (status == 'coming_soon') {
            return false;
          }

          final category = test['category']?.toString().toLowerCase() ?? '';
          switch (tab) {
            case 'All':
              return true;
            case 'School':
              return category == 'school' ||
                  category.contains('school') ||
                  category.contains('vi') ||
                  category.contains('vii') ||
                  category.contains('viii') ||
                  category.contains('ix') ||
                  category.contains('class 6') ||
                  category.contains('class 7') ||
                  category.contains('class 8') ||
                  category.contains('class 9') ||
                  category.contains('class 10') ||
                  category.contains('foundation');
            case 'Boards':
              return category == 'boards' ||
                  category == 'senior' ||
                  category.contains('senior') ||
                  category.contains('boards') ||
                  category.contains('xi') ||
                  category.contains('xii') ||
                  category.contains('11') ||
                  category.contains('12') ||
                  category.contains('humanities') ||
                  category.contains('commerce') ||
                  category.contains('science');
            case 'Govt':
              return category == 'govt' ||
                  category.contains('govt') ||
                  category.contains('ssc') ||
                  category.contains('railway') ||
                  category.contains('dsssb');
            case 'CUET':
              return category == 'cuet' || category.contains('cuet');
            default:
              return false;
          }
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📝', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 16),
                  Text(
                    'No tests available yet — check back soon!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
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
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final testDoc = docs[index];
              final test = testDoc.data() as Map<String, dynamic>;
              final testId = testDoc.id;
              final category = test['category'] ?? 'school';

              final cardGrad = AppGradients.getGradientForCategory(category);
              final emoji = AppGradients.getEmojiForCategory(category);
              final isLocked = test['isLocked'] == true;

              return FutureBuilder<bool>(
                future: _hasTestAccess(testId),
                builder: (context, accessSnapshot) {
                  final hasAccess = accessSnapshot.data ?? false;
                  final showUnlocked = !isLocked || hasAccess;

                  return GestureDetector(
                    onTap: () {
                      final questionCount = test['questions'] ?? 0;
                      if (questionCount == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This test is being prepared. Questions are not available yet.'),
                            backgroundColor: Colors.amber,
                          ),
                        );
                        return;
                      }
                      if (!showUnlocked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('This test is locked. Purchase a package to unlock.'),
                            backgroundColor: Colors.red,
                            action: SnackBarAction(
                              label: 'Packages',
                              textColor: Colors.white,
                              onPressed: () => context.push('/test-packages'),
                            ),
                          ),
                        );
                        return;
                      }
                      context.push('/tests/attempt/$testId');
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Redesigned Gradient Emoji circular avatar icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: cardGrad,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: cardGrad.colors.first.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22, fontFamily: 'Emoji'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Text Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  test['title'] ?? 'Test',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 13, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${test['duration'] ?? 180} min',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.quiz_outlined, size: 13, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${test['questions'] ?? 0} Qs',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Custom circular Play/Lock Action Icon
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: showUnlocked ? cardGrad : null,
                              color: showUnlocked ? null : Colors.grey[200],
                              shape: BoxShape.circle,
                              boxShadow: !showUnlocked
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: cardGrad.colors.first.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                            ),
                            child: Icon(
                              showUnlocked ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                              size: 18,
                              color: showUnlocked ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.08);
            },
          ),
        );
      },
    );
  }
}
