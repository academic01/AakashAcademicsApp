import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> resolveCanonicalUid(User firebaseUser) async {
    final phone = firebaseUser.phoneNumber;
    
    if (phone == null) {
      // Google sign-in with no phone linked yet — use Firebase UID as-is
      return firebaseUser.uid;
    }
    
    // Check if a user document ALREADY exists with this phone number under a DIFFERENT uid
    final query = await _firestore
      .collection('users')
      .where('phone', isEqualTo: phone)
      .limit(1)
      .get();
    
    if (query.docs.isNotEmpty) {
      final existingUid = query.docs.first.id;
      if (existingUid != firebaseUser.uid) {
        return existingUid;
      }
    }
    
    return firebaseUser.uid;
  }

  Future<void> ensureUserDocument(User firebaseUser) async {
    final ref = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await ref.get();
    final refCode = firebaseUser.uid.length >= 6
        ? firebaseUser.uid.substring(0, 6).toUpperCase()
        : firebaseUser.uid.toUpperCase();
    
    if (!snapshot.exists) {
      // NEW USER - create full document
      await ref.set({
        'uid': firebaseUser.uid,
        'phone': firebaseUser.phoneNumber,
        'email': firebaseUser.email,
        'name': firebaseUser.displayName,
        'avatar': firebaseUser.photoURL,
        'schoolCollege': null,
        'currentClass': null,
        'targetCourse': null,
        'targetExam': null,
        'isProfileComplete': false,
        'xp': 0,
        'level': 1,
        'streak': 1,
        'rank': 'Rookie',
        'badges': [],
        'enrolledCourses': [],
        'role': 'student',
        'isActive': true,
        'loginCount': 1,
        'referralCode': refCode,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'fcmToken': null,
        'lastSeenNotificationsAt': null,
      });
    } else {
      // RETURNING USER - update login tracking + streak
      await _updateLoginAndStreak(ref, snapshot.data()!);
      if (snapshot.data()?['referralCode'] == null) {
        await ref.update({'referralCode': refCode});
      }
    }
  }

  Future<void> _updateLoginAndStreak(
    DocumentReference ref, 
    Map<String, dynamic> data) async {
    
    final lastLogin = (data['lastLoginAt'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    int streak = data['streak'] ?? 1;
    
    if (lastLogin != null) {
      final lastDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(lastDay).inDays;
      
      if (diff == 1) {
        streak = streak + 1; // continued
      } else if (diff > 1) {
        streak = 1; // broken, reset
      }
      // diff == 0: same day, no change
    }
    
    await ref.update({
      'loginCount': FieldValue.increment(1),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'streak': streak,
    });
  }

  Stream<int> unreadNotificationCount(String uid) {
    return _firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .asyncExpand((userDoc) {
        final lastSeen = userDoc.data()?['lastSeenNotificationsAt'] as Timestamp?;
        
        Query query = _firestore.collection('notifications')
          .where('target', whereIn: [
            'all',
            'All Students',
            'ALL',
            'everyone',
            uid,
          ]);
        
        if (lastSeen != null) {
          query = query.where('createdAt', isGreaterThan: lastSeen);
        }
        
        return query.snapshots().map((snap) => snap.docs.length);
      });
  }

  Future<void> updateLastSeenNotifications(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastSeenNotificationsAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveProfile({
    required String name,
    required String schoolCollege,
    required String currentClass,
    required String targetCourse,
    required String targetExam,
    String? phone,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    final Map<String, dynamic> updates = {
      'name': name,
      'schoolCollege': schoolCollege,
      'currentClass': currentClass,
      'targetCourse': targetCourse,
      'targetExam': targetExam,
      'isProfileComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (phone != null) {
      updates['phone'] = phone;
    }
    
    await _firestore.collection('users').doc(uid).update(updates);
  }

  Future<void> skipProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection('users').doc(uid).update({
      'isProfileComplete': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> savePhoneAndSkip({required String phone}) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection('users').doc(uid).update({
      'phone': phone,
      'isProfileComplete': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> enrollInCourse({
    required String courseId,
    required String courseTitle,
    double paymentAmount = 0,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = _firestore.batch();
    
    final enrollRef = _firestore.collection('enrollments').doc('${uid}_$courseId');
    
    batch.set(enrollRef, {
      'userId': uid,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'enrolledAt': FieldValue.serverTimestamp(),
      'progress': 0,
      'completedVideos': [],
      'lastVideoId': null,
      'lastWatchedAt': null,
      'isCompleted': false,
      'paymentAmount': paymentAmount,
    });
    
    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {
      'enrolledCourses': FieldValue.arrayUnion([courseId]),
      'xp': FieldValue.increment(50),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    final courseRef = _firestore.collection('courses').doc(courseId);
    batch.update(courseRef, {
      'totalEnrollments': FieldValue.increment(1),
    });
    
    await batch.commit();
  }

  Future<void> saveVideoProgress({
    required String courseId,
    required String videoId,
    required double percentWatched,
    required bool completed,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final enrollRef = _firestore.collection('enrollments').doc('${uid}_$courseId');
    
    Map<String, dynamic> updates = {
      'lastVideoId': videoId,
      'lastWatchedAt': FieldValue.serverTimestamp(),
    };
    
    if (completed) {
      updates['completedVideos'] = FieldValue.arrayUnion([videoId]);
      
      // Award XP only once per video
      // (check if already in completedVideos before this call to avoid double XP —
      // do this check in the calling widget before invoking this function)
      await _firestore.collection('users').doc(uid).update({
        'xp': FieldValue.increment(10),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await enrollRef.update(updates);
    
    // Recalculate progress percentage
    final enrollDoc = await enrollRef.get();
    final completedVideos = (enrollDoc.data()?['completedVideos'] as List?) ?? [];
    
    final courseDoc = await _firestore.collection('courses').doc(courseId).get();
    final totalVideos = courseDoc.data()?['totalVideos'] ?? 1;
    
    final progress = totalVideos > 0
      ? ((completedVideos.length / totalVideos) * 100).clamp(0, 100).round()
      : 0;
    
    await enrollRef.update({
      'progress': progress,
      'isCompleted': progress >= 100,
    });
  }

  Future<Map<String, dynamic>> submitTestResult({
    required String testId,
    required String testTitle,
    required Map<String, dynamic> answers,
    required List<Map<String, dynamic>> questions,
    required int timeTakenSeconds,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    int score = 0;
    for (var q in questions) {
      final userAnswer = answers[q['id']];
      if (userAnswer != null && userAnswer == q['correctOption']) {
        score++;
      }
    }
    
    final totalMarks = questions.length;
    final percentage = totalMarks > 0
      ? (score / totalMarks * 100).round()
      : 0;
    
    int xpEarned = 50;
    if (percentage >= 90) xpEarned = 150;
    else if (percentage >= 70) xpEarned = 100;
    
    final resultRef = await _firestore.collection('testResults').add({
      'userId': uid,
      'testId': testId,
      'testTitle': testTitle,
      'score': score,
      'totalMarks': totalMarks,
      'percentage': percentage,
      'answers': answers.map((k, v) => MapEntry(k, v)),
      'timeTakenSeconds': timeTakenSeconds,
      'xpEarned': xpEarned,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    
    await _firestore.collection('users').doc(uid).update({
      'xp': FieldValue.increment(xpEarned),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await _updateRankAndLevel(uid);
    
    return {
      'resultId': resultRef.id,
      'score': score,
      'totalMarks': totalMarks,
      'percentage': percentage,
      'xpEarned': xpEarned,
    };
  }

  Future<void> _updateRankAndLevel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final xp = doc.data()?['xp'] ?? 0;
    
    String rank;
    int level;
    if (xp >= 15000) { 
      rank = 'Legend'; level = 5; 
    } else if (xp >= 7000) { 
      rank = 'Elite'; level = 4; 
    } else if (xp >= 3000) { 
      rank = 'Champion'; level = 3; 
    } else if (xp >= 1000) { 
      rank = 'Scholar'; level = 2; 
    } else { 
      rank = 'Rookie'; level = 1; 
    }
    
    await _firestore.collection('users').doc(uid).update({
      'rank': rank, 
      'level': level,
    });
  }

  Future<void> registerForLiveClass(String liveClassId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    await _firestore.collection('liveClasses').doc(liveClassId).update({
      'registeredStudents': FieldValue.arrayUnion([uid]),
    });
  }
}
