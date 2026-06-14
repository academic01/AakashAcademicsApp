import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/user_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String? videoUrl;
  final String? title;
  final String? courseId;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.videoUrl,
    this.title,
    this.courseId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  Map<String, dynamic>? _videoData;
  bool _loading = true;
  double _percentWatched = 0.0;
  bool _alreadyCompleted = false;
  Timer? _periodicSaveTimer;
  Timer? _progressTimer;

  late final WebViewController _webViewController;
  bool _webViewInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.title != null || widget.videoUrl != null) {
      _videoData = {
        'title': widget.title,
        'videoUrl': widget.videoUrl,
        'courseId': widget.courseId,
      };
      if (widget.videoUrl != null) {
        _initWebViewController(widget.videoUrl!);
      }
    }
    _loadVideoAndCheckStatus();
    _startPeriodicLogging();
    _startProgressTracking();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _periodicSaveTimer?.cancel();
    // Save progress on exit (Requirement 3)
    final courseId = _videoData?['courseId'] ?? widget.courseId;
    if (courseId != null && courseId.isNotEmpty) {
      final completed = _percentWatched >= 90.0 && !_alreadyCompleted;
      UserService().saveVideoProgress(
        courseId: courseId,
        videoId: widget.videoId,
        percentWatched: _percentWatched,
        completed: completed,
      ).catchError((e) {
        debugPrint('Error saving progress on dispose: $e');
      });
    }
    super.dispose();
  }

  void _initWebViewController(String url) {
    if (_webViewInitialized) return;
    final embedUrl = _getEmbedUrl(url);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(embedUrl));
    setState(() {
      _webViewInitialized = true;
    });
  }

  String _getEmbedUrl(String url) {
    final u = url.trim();
    final uri = Uri.tryParse(u);
    if (uri == null) return u;

    // youtu.be short links
    if (uri.host.contains('youtu.be')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (id.isNotEmpty) return 'https://www.youtube.com/embed/$id?autoplay=1';
    }

    // youtube.com watch?v=
    if (uri.host.contains('youtube.com')) {
      final vid = uri.queryParameters['v'];
      if (vid != null && vid.isNotEmpty) {
        return 'https://www.youtube.com/embed/$vid?autoplay=1';
      }
      if (uri.path.contains('/embed/')) return u;
    }

    return u;
  }

  Future<void> _loadVideoAndCheckStatus() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('videos').doc(widget.videoId).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _videoData = data;
        });

        final videoUrl = data?['videoUrl'] ?? data?['url'];
        if (videoUrl != null) {
          _initWebViewController(videoUrl);
        }

        final courseId = data?['courseId'] ?? widget.courseId;
        if (courseId != null) {
          final courseDoc = await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseId)
              .get();
          if (courseDoc.exists && mounted) {
            setState(() {
              _videoData = {
                ...?data,
                'courseTitle': courseDoc.data()?['title'] ?? 'Course',
              };
            });
          }
          
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

  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_videoData == null) return;
      if (_alreadyCompleted) return;

      int durationSeconds = 600; // default 10 min
      if (_videoData!['durationSeconds'] != null) {
        durationSeconds = _videoData!['durationSeconds'] as int;
      } else if (_videoData!['duration'] != null) {
        final durStr = _videoData!['duration'].toString();
        final match = RegExp(r'(\d+)').firstMatch(durStr);
        if (match != null) {
          durationSeconds = (int.tryParse(match.group(1)!) ?? 10) * 60;
        }
      }

      if (durationSeconds <= 0) durationSeconds = 600;

      if (mounted) {
        setState(() {
          final increment = (1 / durationSeconds) * 100;
          _percentWatched = (_percentWatched + increment).clamp(0.0, 100.0);
        });

        if (_percentWatched >= 90.0 && !_alreadyCompleted) {
          _logProgress(completed: true);
          _showXPToast();
        }
      }
    });
  }

  void _showXPToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Lesson completed! +10 XP earned!'),
        backgroundColor: Color(0xFF22C55E),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _logProgress({required bool completed}) async {
    final courseId = _videoData?['courseId'] ?? widget.courseId;
    if (courseId == null || courseId.isEmpty) return;

    try {
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
      debugPrint('Error saving progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && !_webViewInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title = _videoData?['title'] ?? widget.title ?? 'Lesson Video';
    final desc = _videoData?['description'] ?? 'No description available.';
    final courseId = _videoData?['courseId'] ?? widget.courseId ?? '';
    final courseTitle = _videoData?['courseTitle'] ?? 'Course';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D2240),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Video player WebView
          Container(
            height: 250,
            color: Colors.black,
            child: _webViewInitialized
                ? WebViewWidget(controller: _webViewController)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          // Progress bar just below video
          LinearProgressIndicator(
            value: _percentWatched / 100,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5A623)),
          ),
          // Video details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_percentWatched.round()}% Watched',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (_alreadyCompleted)
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Completed (+10 XP)',
                            style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2240)),
                ),
                const SizedBox(height: 12),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _alreadyCompleted
                        ? null
                        : () {
                            setState(() {
                              _percentWatched = 100.0;
                            });
                            _logProgress(completed: true);
                            _showXPToast();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2240),
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _alreadyCompleted ? 'Completed' : 'Mark as Complete',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    icon: const Icon(
                      Iconsax.message_question,
                      color: Color(0xFF0D2240),
                    ),
                    label: const Text(
                      'Ask a Doubt',
                      style: TextStyle(
                        color: Color(0xFF0D2240),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => context.push(
                      '/ask-doubt',
                      extra: {
                        'courseId': courseId,
                        'courseTitle': courseTitle,
                        'videoId': widget.videoId,
                        'videoTitle': title,
                      },
                    ),
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
