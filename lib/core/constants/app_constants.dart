// App-wide constants
class AppConstants {
  // API
  static const String apiBaseUrl = 'https://api.aakashacademics.com/v1';
  static const Duration apiTimeoutDuration = Duration(seconds: 30);

  // Categories
  static const List<String> classCategories = [
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
  ];
  static const List<String> competitiveExams = ['CUET', 'GOVT', 'JEE', 'NEET'];

  // Pagination
  static const int paginationLimit = 20;

  // Cache
  static const int cacheExpirationHours = 24;

  // Navigation
  static const String routeHome = '/home';
  static const String routeLogin = '/login';
  static const String routeOnboarding = '/onboarding';
  static const String routeSplash = '/';
}

// Route names
class RouteNames {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String courses = '/courses';
  static const String courseDetail = '/course-detail';
  static const String live = '/live';
  static const String tests = '/tests';
  static const String testDetail = '/test-detail';
  static const String profile = '/profile';
}

// Storage keys
class StorageKeys {
  static const String userToken = 'user_token';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String isLoggedIn = 'is_logged_in';
  static const String onboardingComplete = 'onboarding_complete';
  static const String appTheme = 'app_theme';
  static const String lastSyncTime = 'last_sync_time';
  static const String studentProfile = 'student_profile';
  static const String profileComplete = 'profile_complete';
  static const String profileSkipped = 'profile_skipped';
  static const String authPhone = 'auth_phone';
}
