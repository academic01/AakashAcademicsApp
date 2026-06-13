import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/academy_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingComplete, true);
    if (mounted) {
      context.go('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _skipOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // PageView
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildSlide(
                emoji: '📚',
                emojiBackgroundColor: const Color(0xFF0D2240),
                title: 'Learn From Best Faculty',
                subtitle:
                    'Class 6-12, CUET 2026\nand Govt Jobs all in one place',
              ),
              _buildSlide(
                emoji: '🏆',
                emojiBackgroundColor: const Color(0xFFF5A623),
                title: 'Practice & Test Yourself',
                subtitle:
                    '10,000+ questions with\ndetailed analysis and ranking',
              ),
              _buildSlide(
                emoji: '🚀',
                emojiBackgroundColor: const Color(0xFF22C55E),
                title: 'Earn XP & Climb Ranks',
                subtitle: 'Gamified learning makes\nstudying fun and rewarding',
              ),
            ],
          ),

          const Positioned(
            top: 52,
            left: 0,
            right: 0,
            child: Center(
              child: AcademyLogo(
                iconSize: 90,
                textColor: Color(0xFF0D2240),
                subtitleColor: Color(0xFFF5A623),
              ),
            ),
          ),

          // Skip Button (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: TextButton(
              onPressed: _skipOnboarding,
              child: const Text(
                'Skip →',
                style: TextStyle(
                  color: Color(0xFF0D2240),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Bottom Section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      activeDotColor: const Color(0xFF0D2240),
                      dotColor: const Color(0xFFCCCCCC),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 8,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Next / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2240),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == 2 ? 'Get Started →' : 'Next →',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  Widget _buildSlide({
    required String emoji,
    required Color emojiBackgroundColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 88),
            // Emoji Circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: emojiBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D2240),
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF888888),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
