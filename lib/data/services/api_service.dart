import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  static const String baseUrl = 'https://aakashacademics.com/api';
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;

  late Dio _dio;

  ApiService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: connectTimeout),
        receiveTimeout: const Duration(milliseconds: receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add JWT interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('user_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            // Token fetch failed, continue without it
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Unauthorized - clear prefs and navigate to login
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_token');
              await prefs.remove(StorageKeys.onboardingComplete);
              // Note: In production, use proper navigation
              // For now, just clear the token
            } catch (e) {
              // Ignore clearing errors
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ============ AUTH ENDPOINTS ============

  Future<Map<String, dynamic>> sendOTP(String phone) async {
    try {
      final response = await _dio.post(
        '/auth/send-otp',
        data: {'phone': phone},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to send OTP: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String phone, String otp) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {'phone': phone, 'otp': otp},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to verify OTP: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to register: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ============ COURSE ENDPOINTS ============

  Future<List<dynamic>> getCourses({String? category}) async {
    try {
      final params = <String, dynamic>{};
      if (category != null) {
        params['category'] = category;
      }
      final response = await _dio.get('/courses', queryParameters: params);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch courses: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> getCourseById(String id) async {
    try {
      final response = await _dio.get('/courses/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch course: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> enrollCourse(String courseId) async {
    try {
      final response = await _dio.post(
        '/courses/enroll',
        data: {'course_id': courseId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to enroll course: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ============ VIDEO ENDPOINTS ============

  Future<List<dynamic>> getVideos(String courseId) async {
    try {
      final response = await _dio.get('/videos/$courseId');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch videos: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> saveProgress(String videoId, double percent) async {
    try {
      await _dio.post(
        '/videos/$videoId/progress',
        data: {'progress_percent': percent},
      );
    } on DioException catch (e) {
      throw Exception('Failed to save progress: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ============ TEST ENDPOINTS ============

  Future<List<dynamic>> getTests({String? category}) async {
    try {
      final params = <String, dynamic>{};
      if (category != null) {
        params['category'] = category;
      }
      final response = await _dio.get('/tests', queryParameters: params);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch tests: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> getTestQuestions(String testId) async {
    try {
      final response = await _dio.get('/tests/$testId/questions');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch questions: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> submitTest(
    String testId,
    Map<String, dynamic> answers,
  ) async {
    try {
      final response = await _dio.post(
        '/tests/$testId/submit',
        data: {'answers': answers},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to submit test: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ============ LIVE ENDPOINTS ============

  Future<List<dynamic>> getLiveSchedule() async {
    try {
      final response = await _dio.get('/live/schedule');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch schedule: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentLive() async {
    try {
      final response = await _dio.get('/live/current');
      if (response.data == null) {
        return null;
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to fetch current live: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ============ GAMIFICATION ENDPOINTS ============

  Future<Map<String, dynamic>> getUserXP(String userId) async {
    try {
      final response = await _dio.get('/gamification/xp/$userId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch XP: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> addXP(int xp, String reason) async {
    try {
      final response = await _dio.post(
        '/gamification/add-xp',
        data: {'xp': xp, 'reason': reason},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to add XP: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<dynamic>> getLeaderboard(String type) async {
    try {
      final response = await _dio.get('/leaderboard/$type');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch leaderboard: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ============ DASHBOARD ENDPOINTS ============

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _dio.get('/users/dashboard');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch dashboard: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ============ USER ENDPOINTS ============

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to fetch profile: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/profile/update', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
