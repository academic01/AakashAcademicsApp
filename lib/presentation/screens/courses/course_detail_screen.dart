import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCourse();
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

  Future<void> _handleEnroll() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      if (!mounted) return;
      await showDialog<void>(
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
      return;
    }

    if (_courseData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course data not loaded. Please wait.')),
      );
      return;
    }

    try {
      final title = _courseData!['title'] ?? 'Course';
      final price = (_courseData!['price'] as num?)?.toDouble() ?? 0.0;

      await UserService().enrollInCourse(
        courseId: widget.courseId,
        courseTitle: title,
        paymentAmount: price,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course enrolled successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enroll: ${e.toString()}')),
      );
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

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course banner
            Container(
              height: 200,
              color: const Color(0xFF0D2240),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Course info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _handleEnroll,
                    icon: const Icon(Icons.add),
                    label: const Text('Enroll Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
