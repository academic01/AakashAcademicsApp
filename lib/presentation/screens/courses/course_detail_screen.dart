import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/user_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Map<String, dynamic>? _courseData;
  bool _loading = true;
  bool _isEnrolled = false;
  bool _isEnrolling = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCourse();
    _checkEnrollmentStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkEnrollmentStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final doc = await FirebaseFirestore.instance
        .collection('enrollments')
        .doc('${uid}_${widget.courseId}')
        .get();
    
    if (mounted) {
      setState(() {
        _isEnrolled = doc.exists;
      });
    }
  }

  Future<void> _loadCourse() async {
    try {
      final data = await DatabaseService().getCourseById(widget.courseId);
      if (mounted) {
        setState(() {
          _courseData = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Login required'),
        content: const Text(
          'Please login to enroll in this course.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _scrollToVideos() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _initiatePayment(String uid) {
    if (_courseData == null) return;
    context.push('/checkout', extra: {
      'itemType': 'course',
      'itemId': widget.courseId,
      'itemTitle': _courseData!['title'] ?? 'Course',
      'originalPrice': (_courseData!['price'] as num? ?? 0).toDouble(),
    });
  }

  void _showCompleteProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '📋 Complete Profile First',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D2240),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'To enroll in courses, complete your profile so we can personalize your experience.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/complete-profile');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2240),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  'Complete Profile & Enroll',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E5E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enrollFree(String uid) async {
    setState(() => _isEnrolling = true);
    
    try {
      final courseId = widget.courseId;
      final courseTitle = _courseData?['title'] as String? ?? '';
      
      final batch = FirebaseFirestore.instance.batch();
      
      batch.set(
        FirebaseFirestore.instance
            .collection('enrollments')
            .doc('${uid}_$courseId'),
        {
          'userId': uid,
          'courseId': courseId,
          'courseTitle': courseTitle,
          'enrolledAt': FieldValue.serverTimestamp(),
          'progress': 0,
          'completedVideos': [],
          'lastVideoId': null,
          'lastWatchedAt': null,
          'isCompleted': false,
          'paymentAmount': 0,
        },
      );
      
      batch.update(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid),
        {
          'enrolledCourses': FieldValue.arrayUnion([courseId]),
          'xp': FieldValue.increment(50),
        },
      );
      
      batch.update(
        FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId),
        {
          'totalEnrollments': FieldValue.increment(1),
        },
      );
      
      await batch.commit();
      
      setState(() {
        _isEnrolling = false;
        _isEnrolled = true;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Enrolled successfully! Start learning now.'),
          backgroundColor: Color(0xFF22C55E),
          duration: Duration(seconds: 3),
        ),
      );
      
      setState(() {});
      
    } catch (e) {
      setState(() => _isEnrolling = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enrollment failed. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handleEnroll() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }
    
    final uid = user.uid;
    
    final enrollDoc = await FirebaseFirestore.instance
        .collection('enrollments')
        .doc('${uid}_${widget.courseId}')
        .get();
    
    if (enrollDoc.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already enrolled! Access your videos below.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      _scrollToVideos();
      return;
    }
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    
    final isProfileComplete = userDoc.data()?['isProfileComplete'] as bool? ?? false;
    
    if (!isProfileComplete) {
      _showCompleteProfileSheet();
      return;
    }
    
    if (_courseData == null) return;
    
    final isFree = _courseData!['isFree'] == true ||
        (_courseData!['price'] as num? ?? 0) == 0;
        
    if (isFree) {
      await _enrollFree(uid);
    } else {
      _initiatePayment(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title = _courseData?['title'] ?? 'Course Detail';
    final description = _courseData?['description'] ?? 'No description available.';
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final userId = user?.uid ?? '';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0D2240);

    return StreamBuilder<DocumentSnapshot>(
      stream: userId.isEmpty
          ? const Stream.empty()
          : FirebaseFirestore.instance.collection('enrollments').doc('${userId}_${widget.courseId}').snapshots(),
      builder: (context, enrollSnapshot) {
        final isEnrolled = enrollSnapshot.hasData && enrollSnapshot.data!.exists;

        return Scaffold(
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF0D2240),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D2240), Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _courseData?['category']?.toString().toUpperCase() ?? 'COURSE',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D2240)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_isEnrolling)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else if (_isEnrolled || isEnrolled)
                        ElevatedButton.icon(
                          onPressed: _scrollToVideos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text(
                            '▶ Continue Learning',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _handleEnroll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5A623),
                            foregroundColor: const Color(0xFF0D2240),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: Text(
                            (_courseData?['isFree'] == true || (_courseData?['price'] as num? ?? 0) == 0)
                                ? 'Enroll Now (Free)'
                                : 'Enroll Now — ₹${_courseData?['price']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    'Syllabus & Lectures',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2240),
                    ),
                  ),
                ),

                // Videos stream
                StreamBuilder<QuerySnapshot>(
                  stream: DatabaseService().streamVideos(widget.courseId),
                  builder: (context, videoSnapshot) {
                    if (videoSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (!videoSnapshot.hasData || videoSnapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Text('📹', style: TextStyle(fontSize: 40)),
                              SizedBox(height: 12),
                              Text(
                                '📹 Content will be available soon after enrollment',
                                style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final videos = videoSnapshot.data!.docs;
                    
                    // Group by chapterTitle client-side
                    final List<String> chapterOrder = [];
                    final Map<String, List<Map<String, dynamic>>> chapters = {};
                    
                    for (var doc in videos) {
                      final data = doc.data() as Map<String, dynamic>;
                      final id = doc.id;
                      final videoWithId = {...data, 'id': id};
                      final chapterTitle = data['chapterTitle'] as String? ?? data['chapter'] as String? ?? 'Introduction';
                      if (!chapters.containsKey(chapterTitle)) {
                        chapters[chapterTitle] = [];
                        chapterOrder.add(chapterTitle);
                      }
                      chapters[chapterTitle]!.add(videoWithId);
                    }

                    final enrolled = _isEnrolled || isEnrolled;
                    int videoCounter = 0;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chapterOrder.length,
                      itemBuilder: (context, chapterIndex) {
                        final chapterTitle = chapterOrder[chapterIndex];
                        final chapterVideos = chapters[chapterTitle]!;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: chapterIndex == 0,
                              iconColor: const Color(0xFF0D2240),
                              collapsedIconColor: Colors.grey,
                              title: Text(
                                chapterTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: primaryTextColor,
                                ),
                              ),
                              children: chapterVideos.map((video) {
                                final currentVideoIndex = videoCounter++;
                                final bool isFirstVideo = (currentVideoIndex == 0);
                                final bool isPlayable = enrolled || video['isFree'] == true || isFirstVideo;
                                final String videoTitle = video['title'] ?? video['videoTitle'] ?? 'Lecture Video';

                                String durationText = '';
                                if (video['duration'] != null) {
                                  durationText = video['duration'].toString();
                                } else if (video['durationSeconds'] != null) {
                                  final sec = video['durationSeconds'] as int;
                                  final min = sec ~/ 60;
                                  durationText = '$min min';
                                } else {
                                  durationText = '10 min';
                                }

                                final Color iconColor = isPlayable ? const Color(0xFF0D2240) : Colors.grey;
                                final IconData iconData = isPlayable ? Icons.play_arrow_rounded : Icons.lock_outline;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isPlayable
                                          ? const Color(0xFF0D2240).withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: iconColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    videoTitle,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D2240).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      durationText,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D2240),
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    if (isPlayable) {
                                      context.push(
                                        '/live/video/${video['id']}',
                                        extra: {
                                          'videoUrl': video['videoUrl'],
                                          'title': video['title'],
                                          'courseId': widget.courseId,
                                          'videoId': video['id'],
                                        },
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Enroll in this course to unlock all videos'),
                                          backgroundColor: Colors.grey,
                                        ),
                                      );
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
          floatingActionButton: isEnrolled
              ? FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF0D2240),
                  icon: const Icon(Iconsax.message_question, color: Colors.white),
                  label: const Text(
                    'Ask a Doubt',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => context.push(
                    '/ask-doubt',
                    extra: {
                      'courseId': widget.courseId,
                      'courseTitle': title,
                      'videoId': null,
                      'videoTitle': null,
                    },
                  ),
                )
              : null,
        );
      },
    );
  }
}
