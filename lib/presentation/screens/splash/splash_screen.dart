import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

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
      final isLoggedIn = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
      final profileComplete =
          prefs.getBool(StorageKeys.profileComplete) ?? false;
      final onboardingComplete =
          prefs.getBool(StorageKeys.onboardingComplete) ?? false;

      if (!mounted) return;

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
      backgroundColor: const Color(0xFFF0F2F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, 
                (i) => Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D2240),
                    shape: BoxShape.circle))
                .animate(
                  onPlay: (controller) => controller.repeat(),
                  delay: Duration(milliseconds: i * 200))
                .fadeIn(duration: const Duration(milliseconds: 600))
                .then()
                .fadeOut(duration: const Duration(milliseconds: 600))),
            ),
          ],
        ),
      ),
    );
  }
}
