import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Tests',
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
                  '150+ Tests',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '94% Success',
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
          // Category Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: const Color(0xFFF5A623),
            indicatorWeight: 3,
            labelColor: const Color(0xFF0D2240),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelColor: const Color(0xFF888888),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: _tabs.map((tab) => Tab(text: tab, height: 44)).toList(),
          ),
          // Tests List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => _buildTestsList(tab)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsList(String tab) {
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
                const Icon(Icons.inbox, size: 64, color: Color(0xFFCCCCCC)),
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
            // Trigger stream refresh by rebuilding
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final testDoc = docs[index];
                final test = testDoc.data() as Map<String, dynamic>;
                final testId = testDoc.id;

                return GestureDetector(
                  onTap: () => context.push('/tests/$testId'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        // Icon Container
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              test['category'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _getCategoryIcon(test['category']),
                            color: _getCategoryColor(test['category']),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Test Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                test['title'] ?? 'Test',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0D2240),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Details Row
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: const Color(
                                      0xFF888888,
                                    ).withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${test['duration'] ?? 180} min',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: const Color(0xFF888888),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.help_outline,
                                    size: 14,
                                    color: const Color(
                                      0xFF888888,
                                    ).withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${test['questions'] ?? 0} Q',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: const Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right Arrow
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFFF5A623),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'cuet':
        return const Color(0xFF7C3AED);
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

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'cuet':
        return Icons.school;
      case 'boards':
        return Icons.calculate;
      case 'govt':
        return Icons.gavel;
      case 'jee':
        return Icons.bolt;
      case 'neet':
        return Icons.healing;
      default:
        return Icons.quiz;
    }
  }
}
