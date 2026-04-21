import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/academy_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() {
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final profileComplete = prefs.getBool('profileComplete') ?? false;
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (!onboardingComplete) {
        context.go('/onboarding');
      } else if (isLoggedIn) {
        context.go(profileComplete ? '/home' : '/complete-profile');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AcademyLogo(iconSize: 170, subtitleColor: Color(0xFF0D2240)),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Your Rank. Your Rules.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF888888),
              ),
            ),

            const SizedBox(height: 48),

            // Animated Loading Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedDot(0),
                const SizedBox(width: 8),
                _buildAnimatedDot(1),
                const SizedBox(width: 8),
                _buildAnimatedDot(2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF0D2240),
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .fade(duration: 600.ms, delay: (index * 150).ms, begin: 0.3, end: 1.0)
        .then()
        .fade(duration: 600.ms, begin: 1.0, end: 0.3);
  }
}
