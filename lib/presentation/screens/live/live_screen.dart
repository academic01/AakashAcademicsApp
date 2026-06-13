import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/content_filter.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/student_profile_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StudentProfileService _studentProfileService = StudentProfileService();
  String? _userCategory;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _studentProfileService.loadProfile();
      if (profile == null) return;

      final category = getCategoryFromProfile(
        profile.selectedCourse,
        profile.classLevel,
      );
      if (category == null) return;

      if (!mounted) return;
      setState(() {
        _userCategory = category;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Live Classes',
          style: TextStyle(
            color: Color(0xFF0D2240),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.streamLiveClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_call,
                    size: 64,
                    color: Color(0xFFCCCCCC),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No live classes scheduled',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            );
          }

          final classes = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();

          if (_userCategory != null) {
            classes.sort((a, b) {
              final aMatch = (a['category'] ?? '').toString().toLowerCase() ==
                  _userCategory!.toLowerCase();
              final bMatch = (b['category'] ?? '').toString().toLowerCase() ==
                  _userCategory!.toLowerCase();
              if (aMatch && !bMatch) return -1;
              if (!aMatch && bMatch) return 1;
              return 0;
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final liveClass = classes[index];
                final status = liveClass['status'] ?? 'scheduled';
                final isLive = status == 'live';
                final isCompleted = status == 'completed';

                final scheduledAt = liveClass['scheduledAt'] as Timestamp?;
                final scheduledTime = scheduledAt?.toDate() ?? DateTime.now();
                final title = liveClass['title'] ?? 'Live Class';
                final faculty = liveClass['facultyName'] ?? 'Faculty';
                final duration = liveClass['duration'] ?? 60;

                return GestureDetector(
                  onTap: () {
                    if (isLive) {
                      final streamUrl = liveClass['streamUrl'] ?? '';
                      context.push('/live/embed/${liveClass['id']}?url=${Uri.encodeComponent(streamUrl)}&title=${Uri.encodeComponent(title)}&faculty=${Uri.encodeComponent(faculty)}');
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isLive
                          ? const Color(0xFFDC2626).withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLive
                            ? const Color(0xFFDC2626).withOpacity(0.3)
                            : const Color(0xFFE5E7EB),
                        width: isLive ? 2 : 1,
                      ),
                      boxShadow: isLive
                          ? [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge & Title Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isLive)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFDC2626,
                                            ).withOpacity(0.5),
                                            blurRadius: 4,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFDC2626,
                                        ).withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isLive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '🔴 LIVE NOW',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF888888),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'COMPLETED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0D2240),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Faculty Name
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 14,
                              color: Color(0xFF888888),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                faculty,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: const Color(0xFF888888),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Date, Time, Duration
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: const Color(0xFF888888).withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(scheduledTime),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: const Color(0xFF888888),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: const Color(0xFF888888).withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatTime(scheduledTime),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: const Color(0xFF888888),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: const Color(0xFF888888).withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${duration}m',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                        if (isLive) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final streamUrl = liveClass['streamUrl'] ?? '';
                                context.push('/live/embed/${liveClass['id']}?url=${Uri.encodeComponent(streamUrl)}&title=${Uri.encodeComponent(title)}&faculty=${Uri.encodeComponent(faculty)}');
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Join Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5A623),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ] else if (isCompleted &&
                            (liveClass['recordingUrl'] as String?)
                                    ?.isNotEmpty ==
                                true) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final recordingUrl = liveClass['recordingUrl'] ?? '';
                                context.push('/live/embed/${liveClass['id']}?url=${Uri.encodeComponent(recordingUrl)}&title=${Uri.encodeComponent(title)}&faculty=${Uri.encodeComponent(faculty)}');
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Watch Recording'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final classDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (classDate == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (classDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
