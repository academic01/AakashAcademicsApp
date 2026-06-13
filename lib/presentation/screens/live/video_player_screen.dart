import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../data/services/user_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  Map<String, dynamic>? _videoData;
  bool _loading = true;
  double _percentWatched = 0.0;
  bool _alreadyCompleted = false;
  Timer? _periodicSaveTimer;

  @override
  void initState() {
    super.initState();
    _loadVideoAndCheckStatus();
    _startPeriodicLogging();
  }

  @override
  void dispose() {
    _periodicSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVideoAndCheckStatus() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('videos').doc(widget.videoId).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _videoData = data;
        });

        final courseId = data?['courseId'];
        if (courseId != null) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            final enrollDoc = await FirebaseFirestore.instance
                .collection('enrollments')
                .doc('${uid}_$courseId')
                .get();
            if (enrollDoc.exists) {
              final completedList = enrollDoc.data()?['completedVideos'] as List?;
              if (completedList != null && completedList.contains(widget.videoId)) {
                setState(() {
                  _alreadyCompleted = true;
                  _percentWatched = 100.0;
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading video data: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startPeriodicLogging() {
    _periodicSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _logProgress(completed: false);
    });
  }

  Future<void> _logProgress({required bool completed}) async {
    final courseId = _videoData?['courseId'];
    if (courseId == null) return;

    try {
      // Check already completed to avoid double XP
      final finalCompleted = completed && !_alreadyCompleted;

      await UserService().saveVideoProgress(
        courseId: courseId,
        videoId: widget.videoId,
        percentWatched: _percentWatched,
        completed: finalCompleted,
      );

      if (finalCompleted) {
        setState(() {
          _alreadyCompleted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save video progress: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title = _videoData?['title'] ?? 'Lesson Video';
    final desc = _videoData?['description'] ?? 'No description available.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          // Video player placeholder
          Container(
            height: 250,
            color: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle, color: Colors.white, size: 60),
                      const SizedBox(height: 12),
                      Text(
                        'Playing: $title',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_percentWatched.round()}% Watched',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          if (_alreadyCompleted)
                            const Text(
                              '✅ Completed',
                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      Slider(
                        value: _percentWatched,
                        min: 0.0,
                        max: 100.0,
                        activeColor: const Color(0xFFF5A623),
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          setState(() {
                            _percentWatched = val;
                          });
                          if (val >= 90.0 && !_alreadyCompleted) {
                            _logProgress(completed: true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Video details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _alreadyCompleted
                      ? null
                      : () {
                          setState(() {
                            _percentWatched = 100.0;
                          });
                          _logProgress(completed: true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2240),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    _alreadyCompleted ? 'Completed' : 'Mark as Complete',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
