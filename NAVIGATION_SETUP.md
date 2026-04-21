# Required Dependencies for Aakash Academics Navigation

Add these to your `pubspec.yaml` under dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Navigation
  go_router: ^13.0.0
  
  # State Management
  provider: ^6.0.0
  
  # Local Storage
  shared_preferences: ^2.2.0
  
  # HTTP Client
  http: ^1.1.0
  
  # Icons (Optional - for Iconsax icons)
  iconsax: ^0.0.8
  
  # Firebase (Optional - comment out until Firebase is set up)
  # firebase_core: ^2.24.0
  # firebase_auth: ^4.10.0
  # cloud_firestore: ^4.14.0
```

Run: `flutter pub get` after adding dependencies

## What Changed

### Files Modified:
1. **app.dart** - Updated to use MaterialApp.router with GoRouter
2. **main.dart** - Already configured with Provider setup

### New Files Created:
1. **lib/presentation/navigation/app_router.dart** - Complete GoRouter configuration with:
   - 13 routes (splash, auth, shell with bottom nav, detail screens)
   - Auth redirect logic using SharedPreferences
   - Route extension methods for easier navigation

2. **lib/presentation/navigation/bottom_nav.dart** - Custom bottom navigation bar with:
   - 5 animated tabs (Home, Courses, Live, Tests, Profile)
   - Yellow indicator dot for active tab
   - AnimatedContainer scale & color transitions
   - 250ms duration animations

### New Screen Files Created:
1. **signup_screen.dart** - User registration
2. **course_detail_screen.dart** - Course overview
3. **video_player_screen.dart** - Video lesson player
4. **test_attempt_screen.dart** - Test taking interface
5. **test_result_screen.dart** - Result display & analytics
6. **leaderboard_screen.dart** - Global/category leaderboard

## Usage

### Navigate with GoRouter:
```dart
// Basic navigation
context.go('/home');
context.push('/courses');

// With parameters
context.go('/courses/detail/course_123');

// Using extension methods
final router = GoRouter.of(context);
router.pushCourseDetail('course_123');
router.pushVideoPlayer('video_456');
router.pushTestAttempt('test_789');
router.pushTestResult('result_101');
```

### Auth Flow:
- User without token → Shown onboarding or login
- User with token → Redirected to /home
- Token managed via SharedPreferences (key: 'user_token')

## Next Steps:
1. Run `flutter pub get`
2. Integrate with Firebase Auth when ready
3. Update `AuthService` to save tokens to SharedPreferences
4. Add proper animations and transitions as needed
5. Implement error handling and loading states
