import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/courses/courses_screen.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/live/live_screen.dart';
import '../screens/live/video_player_screen.dart';
import '../screens/live/live_video_embed_screen.dart';
import '../screens/tests/tests_screen.dart';
import '../screens/tests/test_attempt_screen.dart';
import '../screens/tests/test_result_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import 'bottom_nav.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String completeProfile = '/complete-profile';
  static const String home = '/home';
  static const String courses = '/courses';
  static const String courseDetail = '/course/:id';
  static const String live = '/live';
  static const String videoPlayer = '/video/:id';
  static const String tests = '/tests';
  static const String testAttempt = '/test/:id';
  static const String testResult = '/result/:id';
  static const String profile = '/profile';
  static const String leaderboard = '/leaderboard';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    redirect: _redirect,
    routes: [
      // Splash Screen
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),

      // Onboarding Screen
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),

      GoRoute(path: signup, builder: (context, state) => const SignupScreen()),

      // Complete Profile Screen
      GoRoute(
        path: completeProfile,
        builder: (context, state) => const CompleteProfileScreen(),
      ),

      // Bottom Navigation Shell Route
      ShellRoute(
        builder: (context, state, child) =>
            BottomNavBar(location: state.matchedLocation, child: child),
        routes: [
          // Home
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Courses
          GoRoute(
            path: '/courses',
            builder: (context, state) => const CoursesScreen(),
            routes: [
              // Course Detail
              GoRoute(
                path: 'detail/:id',
                builder: (context, state) {
                  final courseId = state.pathParameters['id'] ?? '';
                  return CourseDetailScreen(courseId: courseId);
                },
              ),
            ],
          ),

          // Live
          GoRoute(
            path: '/live',
            builder: (context, state) => const LiveScreen(),
            routes: [
              // Video Player
              GoRoute(
                path: 'video/:id',
                builder: (context, state) {
                  final videoId = state.pathParameters['id'] ?? '';
                  return VideoPlayerScreen(videoId: videoId);
                },
              ),
              // Embedded live viewer
              GoRoute(
                path: 'embed/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  final streamUrl = state.uri.queryParameters['url'] ?? '';
                  final title = state.uri.queryParameters['title'] ?? 'Live Class';
                  final facultyName = state.uri.queryParameters['faculty'] ?? '';
                  return LiveVideoEmbedScreen(
                    streamUrl: streamUrl.isNotEmpty ? streamUrl : id,
                    title: title,
                    facultyName: facultyName,
                  );
                },
              ),
            ],
          ),

          // Tests
          GoRoute(
            path: '/tests',
            builder: (context, state) => const TestsScreen(),
            routes: [
              // Test Attempt
              GoRoute(
                path: 'attempt/:id',
                builder: (context, state) {
                  final testId = state.pathParameters['id'] ?? '';
                  return TestAttemptScreen(testId: testId);
                },
              ),

              // Test Result
              GoRoute(
                path: 'result/:id',
                builder: (context, state) {
                  final resultId = state.pathParameters['id'] ?? '';
                  return TestResultScreen(resultId: resultId);
                },
              ),
            ],
          ),

          // Profile
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // Leaderboard (accessible from profile/tests)
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
        ],
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );

  /// Redirect logic for authentication
  static Future<String?> _redirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
    final profileComplete = prefs.getBool(StorageKeys.profileComplete) ?? false;
    final isOnSplash = state.matchedLocation == '/splash';
    final isOnAuth =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    final isOnOnboarding = state.matchedLocation == '/onboarding';
    final isOnProfileSetup = state.matchedLocation == '/complete-profile';

    // If on splash screen, let it handle the redirect
    if (isOnSplash) {
      return null;
    }

    // If user is logged in
    if (isLoggedIn) {
      // If profile is complete, allow access to app
      if (profileComplete) {
        // If trying to access auth screens, redirect to home
        if (isOnAuth || isOnOnboarding) {
          return '/home';
        }
        return null; // Stay on current route
      } else {
        // Profile not complete, redirect to profile setup
        if (!isOnProfileSetup) {
          return '/complete-profile';
        }
        return null;
      }
    }

    // If no login
    if (!isOnAuth && !isOnOnboarding && !isOnProfileSetup) {
      // Check if onboarding is complete
      final onboardingComplete =
          prefs.getBool(StorageKeys.onboardingComplete) ?? false;
      if (!onboardingComplete) {
        return '/onboarding';
      }
      return '/login';
    }

    return null;
  }
}

/// Extension method for easier navigation with route parameters
extension GoRouterX on GoRouter {
  void pushCourseDetail(String courseId) {
    push('/courses/detail/$courseId');
  }

  void pushVideoPlayer(String videoId) {
    push('/live/video/$videoId');
  }

  void pushLiveEmbed(String id, {String? streamUrl}) {
    if (streamUrl != null && streamUrl.isNotEmpty) {
      push('/live/embed/$id?url=${Uri.encodeComponent(streamUrl)}');
    } else {
      push('/live/embed/$id');
    }
  }

  void pushTestAttempt(String testId) {
    push('/tests/attempt/$testId');
  }

  void pushTestResult(String resultId) {
    push('/tests/result/$resultId');
  }
}
