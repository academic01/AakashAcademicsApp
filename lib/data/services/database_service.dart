import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // U  // Save/Update user profile
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // Stream user data (real-time updates)
  Stream<DocumentSnapshot> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Update XP
  Future<void> addXP(String uid, int xp) async {
    await _db.collection('users').doc(uid).update({
      'xp': FieldValue.increment(xp),
    });
    // Check and update rank
    await _updateRank(uid);
  }

  // Update streak
  Future<void> updateStreak(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final lastLogin = (data['lastLoginAt'] as Timestamp?)?.toDate();
    final now = DateTime.now();

    int streak = data['streak'] ?? 0;

    if (lastLogin != null) {
      final diff = now.difference(lastLogin).inDays;
      if (diff == 1) {
        streak++; // Continue streak
      } else if (diff > 1) {
        streak = 1; // Reset streak
      }
      // diff == 0: same day, no change
    } else {
      streak = 1;
    }

    await _db.collection('users').doc(uid).update({
      'streak': streak,
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateRank(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    final xp = doc.data()?['xp'] ?? 0;
    String rank;
    int level;

    if (xp >= 15000) {
      rank = 'Legend';
      level = 5;
    } else if (xp >= 7000) {
      rank = 'Elite';
      level = 4;
    } else if (xp >= 3000) {
      rank = 'Champion';
      level = 3;
    } else if (xp >= 1000) {
      rank = 'Scholar';
      level = 2;
    } else {
      rank = 'Rookie';
      level = 1;
    }

    await _db.collection('users').doc(uid).update({
      'rank': rank,
      'level': level,
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // COURSE OPERATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━

  // Get all courses (filtered)
  Future<List<Map<String, dynamic>>> getCourses({String? category}) async {
    Query query = _db.collection('courses');

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    final list = snapshot.docs
        .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
        .where((c) {
          final status = c['status'];
          return status == 'active' || status == 'coming_soon';
        })
        .toList();

    // Sort in memory: isFeatured (descending), then createdAt (descending)
    list.sort((a, b) {
      final aFeatured = a['isFeatured'] == true ? 1 : 0;
      final bFeatured = b['isFeatured'] == true ? 1 : 0;
      if (aFeatured != bFeatured) {
        return bFeatured.compareTo(aFeatured);
      }
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return list;
  }

  // Get single course
  Future<Map<String, dynamic>?> getCourseById(String courseId) async {
    final doc = await _db.collection('courses').doc(courseId).get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  // Stream courses
  Stream<QuerySnapshot> streamCourses({String? category}) {
    Query query = _db.collection('courses');

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots();
  }

  // Get course videos
  Future<List<Map<String, dynamic>>> getCourseVideos(String courseId) async {
    final snapshot = await _db
        .collection('videos')
        .where('courseId', isEqualTo: courseId)
        .orderBy('chapterIndex')
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
        .toList();
  }

  // Stream course videos
  Stream<QuerySnapshot> streamVideos(String courseId) {
    return _db
        .collection('videos')
        .where('courseId', isEqualTo: courseId)
        .orderBy('chapterIndex')
        .orderBy('order')
        .snapshots();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // ENROLLMENT OPERATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━

  // Enroll in course
  Future<bool> enrollInCourse(String userId, String courseId) async {
    try {
      final enrollId = '${userId}_$courseId';

      // Create enrollment record
      await _db.collection('enrollments').doc(enrollId).set({
        'userId': userId,
        'courseId': courseId,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0,
        'completedVideos': [],
        'isCompleted': false,
      });

      // Add course to user's enrolled list
      await _db.collection('users').doc(userId).update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      });

      // Increment enrollment count
      await _db.collection('courses').doc(courseId).update({
        'totalEnrollments': FieldValue.increment(1),
      });

      // Add XP for enrolling
      await addXP(userId, 50);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if enrolled
  Future<bool> isEnrolled({
    required String userId,
    required String courseId,
  }) async {
    final doc = await _db
        .collection('enrollments')
        .doc('${userId}_$courseId')
        .get();
    return doc.exists;
  }

  // Get user enrollments
  Future<List<Map<String, dynamic>>> getUserEnrollments(String userId) async {
    final snapshot = await _db
        .collection('enrollments')
        .where('userId', isEqualTo: userId)
        .orderBy('enrolledAt', descending: true)
        .get();

    return snapshot.docs.map((d) => d.data()).toList();
  }

  // Save video progress
  Future<void> saveVideoProgress({
    required String userId,
    required String courseId,
    required String videoId,
    required double progress,
    required bool completed,
  }) async {
    final enrollId = '${userId}_$courseId';

    Map<String, dynamic> updates = {
      'lastVideoId': videoId,
      'lastWatchedAt': FieldValue.serverTimestamp(),
    };

    if (completed) {
      updates['completedVideos'] = FieldValue.arrayUnion([videoId]);
    }

    await _db.collection('enrollments').doc(enrollId).update(updates);

    // Add XP for completing video
    if (completed) {
      await addXP(userId, 10);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // TEST OPERATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━

  // Get tests
  Future<List<Map<String, dynamic>>> getTests({String? category}) async {
    Query query = _db.collection('tests').orderBy('order');

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
        .toList();
  }

  // Stream tests
  Stream<QuerySnapshot> streamTests({String? category}) {
    Query query = _db.collection('tests').orderBy('order');

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots();
  }

  // Get test questions
  Future<List<Map<String, dynamic>>> getTestQuestions(String testId) async {
    final snapshot = await _db
        .collection('questions')
        .where('testId', isEqualTo: testId)
        .get();

    final questions = snapshot.docs
        .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
        .toList();

    questions.shuffle(); // Randomize
    return questions;
  }

  // Submit test result
  Future<Map<String, dynamic>> submitTest({
    required String userId,
    required String testId,
    required Map<String, dynamic> answers,
    required int timeTaken,
    required List<Map<String, dynamic>> questions,
  }) async {
    // Calculate score
    int score = 0;
    int totalMarks = questions.length;

    for (var q in questions) {
      final userAnswer = answers[q['id']];
      if (userAnswer != null && userAnswer == q['correctOption']) {
        score++;
      }
    }

    final percentage = (score / totalMarks * 100).round();

    // Save result
    final resultRef = await _db.collection('testResults').add({
      'userId': userId,
      'testId': testId,
      'score': score,
      'totalMarks': totalMarks,
      'percentage': percentage,
      'answers': answers,
      'timeTaken': timeTaken,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    // Add XP
    int xpEarned = 50;
    if (percentage >= 90)
      xpEarned = 150;
    else if (percentage >= 70)
      xpEarned = 100;
    await addXP(userId, xpEarned);

    return {
      'resultId': resultRef.id,
      'score': score,
      'totalMarks': totalMarks,
      'percentage': percentage,
      'xpEarned': xpEarned,
    };
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // LEADERBOARD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final snapshot = await _db
        .collection('users')
        .where('isActive', isEqualTo: true)
        .orderBy('xp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .asMap()
        .entries
        .map(
          (e) => {
            ...e.value.data() as Map<String, dynamic>,
            'position': e.key + 1,
          },
        )
        .toList();
  }

  // Stream leaderboard (real-time updates)
  Stream<List<Map<String, dynamic>>> streamLeaderboard() {
    return _db
        .collection('users')
        .where('isActive', isEqualTo: true)
        .orderBy('xp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .asMap()
            .entries
            .map((e) => {
                  ...e.value.data(),
                  'position': e.key + 1,
                })
            .toList());
  }

  // Stream user test results count
  Stream<int> streamTestResultsCount(String userId) {
    return _db
        .collection('testResults')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Stream user enrollments count
  Stream<int> streamEnrollmentsCount(String userId) {
    return _db
        .collection('enrollments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Stream featured courses (for home screen)
  Stream<List<Map<String, dynamic>>> streamFeaturedCourses() {
    return _db
        .collection('courses')
        .where('status', isEqualTo: 'active')
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList());
  }

  // Stream all active courses
  Stream<List<Map<String, dynamic>>> streamActiveCourses() {
    return _db
        .collection('courses')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList());
  }


  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // LIVE CLASSES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<List<Map<String, dynamic>>> getLiveClasses() async {
    final snapshot = await _db
        .collection('liveClasses')
        .where(
          'scheduledAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 2)),
          ),
        )
        .orderBy('scheduledAt')
        .limit(20)
        .get();

    return snapshot.docs
        .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
        .toList();
  }

  Stream<QuerySnapshot> streamLiveClasses() {
    return _db
        .collection('liveClasses')
        .orderBy('scheduledAt', descending: false)
        .snapshots();
  }

  Stream<Map<String, dynamic>?> streamCurrentLiveClass() {
    return _db
        .collection('liveClasses')
        .where('status', isEqualTo: 'live')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return {...doc.data(), 'id': doc.id};
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // SITE SETTINGS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<Map<String, dynamic>?> getSiteSettings() async {
    final doc = await _db.collection('settings').doc('site_settings').get();
    return doc.data();
  }

  Stream<DocumentSnapshot> streamSettings() {
    return _db.collection('settings').doc('site_settings').snapshots();
  }

  Stream<DocumentSnapshot> streamSiteSettings() {
    return _db.collection('settings').doc('site_settings').snapshots();
  }
}
