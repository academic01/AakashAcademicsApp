import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/gradients.dart';
import '../../../core/utils/content_filter.dart';
import '../../../data/models/student_profile.dart';
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

  final List<String> _tabs = [
    'All',
    'School',
    'Boards',
    'Govt',
    'CUET',
    'Coming Soon',
  ];

  late final Map<String, Stream<QuerySnapshot>> _testStreams;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadUserProfile();

    // Initialize streams for each category
    _testStreams = {
      'All': _dbService.streamTests(),
      'School': _dbService.streamTests(category: 'school'),
      'Boards': _dbService.streamTests(category: 'boards'),
      'Govt': _dbService.streamTests(category: 'govt'),
      'CUET': _dbService.streamTests(category: 'cuet'),
      'Coming Soon': _dbService.streamTests(category: 'coming_soon'),
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
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

      final tabIndex = _tabs.indexWhere(
        (tab) =>
            tab.toLowerCase() == category.toLowerCase() ||
            tab.toLowerCase().contains(category.toLowerCase()),
      );
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
    final cardBgColor = isDark ? AppColors.darkCard : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0D2240);

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
      stream: _testStreams[tab],
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
                  'No tests available',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

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

              return GestureDetector(
                onTap: () => context.push('/tests/$testId'),
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
                          gradient: isLocked ? null : cardGrad,
                          color: isLocked ? Colors.grey[200] : null,
                          shape: BoxShape.circle,
                          boxShadow: isLocked
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
                          isLocked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded,
                          size: 18,
                          color: isLocked ? Colors.grey : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.08);
            },
          ),
        );
      },
    );
  }
}
