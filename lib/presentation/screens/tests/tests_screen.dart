import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({Key? key}) : super(key: key);

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'All',
    'School',
    'Boards',
    'Govt',
    'CUET🆕',
    'Coming Soon',
  ];

  final List<TestData> _allTests = [
    // Priority 1 - CUET
    TestData(
      id: '1',
      title: 'CUET 2026 FULL MOCK TEST',
      tag: 'CUET',
      status: 'active',
      duration: 195,
      questions: 150,
      isFree: true,
      isNew: true,
      isLocked: false,
      category: 'cuet',
      icon: Icons.school,
      iconColor: const Color(0xFF7C3AED),
    ),
    // Priority 2 - Boards/School
    TestData(
      id: '2',
      title: 'CLASS 10 MATHS FULL TEST',
      tag: 'BOARDS',
      status: 'active',
      duration: 180,
      questions: 80,
      isFree: true,
      isNew: false,
      isLocked: false,
      category: 'boards',
      icon: Icons.calculate,
      iconColor: const Color(0xFF0D2240),
    ),
    TestData(
      id: '3',
      title: 'CLASS 10 SCIENCE MOCK TEST',
      tag: 'BOARDS',
      status: 'active',
      duration: 150,
      questions: 60,
      isFree: true,
      isNew: false,
      isLocked: false,
      category: 'boards',
      icon: Icons.science,
      iconColor: const Color(0xFF0D2240),
    ),
    TestData(
      id: '4',
      title: 'CLASS 12 PHYSICS CHAPTER TEST',
      tag: 'SENIOR',
      status: 'active',
      duration: 90,
      questions: 45,
      isFree: true,
      isNew: false,
      isLocked: false,
      category: 'boards',
      icon: Icons.flash_on,
      iconColor: const Color(0xFF7C3AED),
    ),
    TestData(
      id: '5',
      title: 'CLASS 12 ACCOUNTANCY MOCK',
      tag: 'COMMERCE',
      status: 'active',
      duration: 120,
      questions: 60,
      isFree: true,
      isNew: false,
      isLocked: false,
      category: 'boards',
      icon: Icons.book,
      iconColor: const Color(0xFF7C3AED),
    ),
    // Priority 3 - Govt
    TestData(
      id: '6',
      title: 'SSC CGL FULL MOCK TEST 1',
      tag: 'GOVT JOBS',
      status: 'active',
      duration: 60,
      questions: 100,
      isFree: true,
      isNew: false,
      isLocked: false,
      category: 'govt',
      icon: Icons.work,
      iconColor: const Color(0xFF16A34A),
    ),
    TestData(
      id: '7',
      title: 'RAILWAY NTPC MOCK TEST',
      tag: 'GOVT JOBS',
      status: 'active',
      duration: 90,
      questions: 100,
      isFree: true,
      isNew: false,
      isLocked: false,
      category: 'govt',
      icon: Icons.train,
      iconColor: const Color(0xFF16A34A),
    ),
    // Priority 4 - Coming Soon
    TestData(
      id: '8',
      title: 'FULL JEE MOCK TEST 1',
      tag: 'JEE•SOON',
      status: 'locked',
      duration: 180,
      questions: 90,
      isFree: false,
      isNew: false,
      isLocked: true,
      category: 'coming-soon',
      icon: Icons.rocket,
      iconColor: const Color(0xFF6B7280),
    ),
    TestData(
      id: '9',
      title: 'NEET BIOLOGY CHAPTER TEST',
      tag: 'NEET•SOON',
      status: 'locked',
      duration: 120,
      questions: 60,
      isFree: false,
      isNew: false,
      isLocked: true,
      category: 'coming-soon',
      icon: Icons.favorite,
      iconColor: const Color(0xFF6B7280),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TestData> _getTestsForTab(String tab) {
    switch (tab) {
      case 'School':
        return _allTests.where((t) => t.category == 'school').toList();
      case 'Boards':
        return _allTests.where((t) => t.category == 'boards').toList();
      case 'Govt':
        return _allTests.where((t) => t.category == 'govt').toList();
      case 'CUET🆕':
        return _allTests.where((t) => t.category == 'cuet').toList();
      case 'Coming Soon':
        return _allTests.where((t) => t.category == 'coming-soon').toList();
      default:
        return _allTests;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Arena'),
        titleTextStyle: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
        backgroundColor: Colors.white,
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
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            unselectedLabelColor: const Color(0xFF888888),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
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
    final tests = _getTestsForTab(tab);

    return SingleChildScrollView(
      child: Column(
        children: [
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];

              // Add coming soon divider before locked tests
              if (test.isLocked && (index == 0 || !tests[index - 1].isLocked)) {
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          '🔜 Coming Soon Tests',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF888888),
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TestCard(
                        test: test,
                        onTap: () {
                          if (test.isLocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'JEE batch launching mid-2026!\n'
                                  'Tap Notify Me to get alerted.',
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            context.push('/tests/attempt/${test.id}');
                          }
                        },
                      ),
                    ),
                  ],
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TestCard(
                  test: test,
                  onTap: () {
                    if (test.isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'JEE batch launching mid-2026!\n'
                            'Tap Notify Me to get alerted.',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      context.push('/tests/attempt/${test.id}');
                    }
                  },
                ),
              );
            },
          ),
          // Scholarship Info Card
          if (tab == 'All' || tab == 'CUET🆕')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scholarship Test',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Earn up to ₹2,00,000',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scholarship test opening soon!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A623),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Attempt Now',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TestCard extends StatelessWidget {
  final TestData test;
  final VoidCallback onTap;

  const TestCard({Key? key, required this.test, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: test.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(test.icon, color: test.iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          // Test Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges Row
                Row(
                  children: [
                    // Exam Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getBadgeColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        test.tag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D2240),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Status Badge
                    if (test.isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Title
                Text(
                  test.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2240),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Duration & Questions Row
                Row(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF888888),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${test.duration} min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.description,
                          size: 14,
                          color: Color(0xFF888888),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${test.questions} Q',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Button
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: test.isLocked
                    ? const Color(0xFFE5E7EB)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                test.isLocked ? Icons.lock : Icons.play_arrow,
                color: test.isLocked ? const Color(0xFF888888) : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor() {
    if (test.tag.contains('CUET')) return const Color(0xFF7C3AED);
    if (test.tag.contains('GOVT')) return const Color(0xFF16A34A);
    if (test.tag.contains('JEE') || test.tag.contains('NEET')) {
      return const Color(0xFF6B7280);
    }
    return const Color(0xFF0D2240);
  }
}

class TestData {
  final String id;
  final String title;
  final String tag;
  final String status;
  final int duration;
  final int questions;
  final bool isFree;
  final bool isNew;
  final bool isLocked;
  final String category;
  final IconData icon;
  final Color iconColor;

  TestData({
    required this.id,
    required this.title,
    required this.tag,
    required this.status,
    required this.duration,
    required this.questions,
    required this.isFree,
    required this.isNew,
    required this.isLocked,
    required this.category,
    required this.icon,
    required this.iconColor,
  });
}
