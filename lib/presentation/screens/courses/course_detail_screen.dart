import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/user_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
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

    final success = await DatabaseService().enrollInCourse(user.uid, widget.courseId);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course enrolled successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to enroll. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
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
                  'Course: ${widget.courseId}',
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
                  const Text(
                    'Course Title',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Course Description',
                    style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
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
