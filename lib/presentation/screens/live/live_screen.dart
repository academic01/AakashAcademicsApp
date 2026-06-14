import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/gradients.dart';
import '../../../core/utils/content_filter.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/student_profile_service.dart';
import '../../../data/services/user_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StudentProfileService _studentProfileService = StudentProfileService();
  String? _userCategory;
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekDays = _generateCurrentWeek();
    _loadUserProfile();
  }

  List<DateTime> _generateCurrentWeek() {
    final now = DateTime.now();
    final currentDay = now.weekday; // 1 = Monday, 7 = Sunday
    // Start week from Monday
    final startOfWeek = now.subtract(Duration(days: currentDay - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      String? targetCourse = user?.targetCourse;
      String? targetExam = user?.targetExam;
      String? currentClass = user?.currentClass;

      if (user == null) {
        final profile = await _studentProfileService.loadProfile();
        if (profile != null) {
          targetCourse = profile.selectedCourse;
          targetExam = profile.classLevel;
        }
      }

      final category = ContentFilter.getCategoryFromProfile(
        targetCourse: targetCourse,
        targetExam: targetExam,
        currentClass: currentClass,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF7F8FC);
    final cardBgColor = isDark ? AppColors.darkCard : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0D2240);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Redesigned Header Accent Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFF472B6), Color(0xFF7C3AED)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Classes',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                          const Text(
                            '📺 Interactive Classroom',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Weekly day selector redesign
            Container(
              height: 75,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _weekDays.length,
                itemBuilder: (context, index) {
                  final date = _weekDays[index];
                  final isToday = date.day == DateTime.now().day &&
                      date.month == DateTime.now().month &&
                      date.year == DateTime.now().year;
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;

                  final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final dayName = weekdayNames[date.weekday - 1];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                        border: isToday && !isSelected
                            ? Border.all(color: const Color(0xFF7C3AED), width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white54 : Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF0D2240)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main Classes Stream list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
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
                            Icons.video_call_rounded,
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

                  // Sort: matching category first
                  if (_userCategory != null) {
                    classes.sort((a, b) {
                      final aMatches = ContentFilter.classMatchesCategory(a, _userCategory);
                      final bMatches = ContentFilter.classMatchesCategory(b, _userCategory);
                      if (aMatches && !bMatches) return -1;
                      if (!aMatches && bMatches) return 1;
                      
                      final aScheduled = a['scheduledAt'] as Timestamp?;
                      final bScheduled = b['scheduledAt'] as Timestamp?;
                      if (aScheduled == null && bScheduled == null) return 0;
                      if (aScheduled == null) return 1;
                      if (bScheduled == null) return -1;
                      return aScheduled.compareTo(bScheduled);
                    });
                  }

                  // Optional Filter by selected date could be added here,
                  // but we keep original logic/data mapping intact.

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
                        final category = liveClass['category'] ?? 'school';

                        final cardGrad = AppGradients.getGradientForCategory(category);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left accent category gradient stripe
                                  Container(
                                    width: 6,
                                    decoration: BoxDecoration(
                                      gradient: cardGrad,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Status & Category Row
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildStatusBadge(status),
                                              Text(
                                                category.toString().toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: cardGrad.colors.first,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Title
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: primaryTextColor,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Teacher Avatar & Name
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: cardGrad.colors.first.withOpacity(0.15),
                                                child: Text(
                                                  faculty.isNotEmpty ? faculty[0] : 'T',
                                                  style: TextStyle(
                                                    color: cardGrad.colors.first,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                faculty,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          // Timing Footer Info
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_month_rounded, size: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(scheduledTime),
                                                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(Icons.access_time_filled_rounded, size: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatTime(scheduledTime),
                                                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(Icons.timer_rounded, size: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${duration}m',
                                                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          // Action button based on status
                                          if (isLive || (isCompleted && (liveClass['recordingUrl'] as String?)?.isNotEmpty == true)) ...[
                                            const SizedBox(height: 14),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 44,
                                              child: isLive
                                                  ? Container(
                                                      decoration: BoxDecoration(
                                                        gradient: cardGrad,
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: cardGrad.colors.first.withOpacity(0.3),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          final streamUrl = liveClass['streamUrl'] ?? '';
                                                          context.push('/live/embed/${liveClass['id']}?url=${Uri.encodeComponent(streamUrl)}&title=${Uri.encodeComponent(title)}&faculty=${Uri.encodeComponent(faculty)}');
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.transparent,
                                                          shadowColor: Colors.transparent,
                                                          foregroundColor: Colors.white,
                                                          padding: EdgeInsets.zero,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Join Live Now',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : ElevatedButton(
                                                      onPressed: () {
                                                        final recordingUrl = liveClass['recordingUrl'] ?? '';
                                                        context.push('/live/embed/${liveClass['id']}?url=${Uri.encodeComponent(recordingUrl)}&title=${Uri.encodeComponent(title)}&faculty=${Uri.encodeComponent(faculty)}');
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[200],
                                                        foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                                        padding: EdgeInsets.zero,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        elevation: 0,
                                                      ),
                                                      child: const Text(
                                                        'Watch Recording',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ] else if (!isLive && !isCompleted) ...[
                                            const SizedBox(height: 14),
                                            _buildReminderButton(liveClass, isDark, primaryTextColor),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'live') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(end: const Offset(1.5, 1.5), duration: 600.ms),
            const SizedBox(width: 6),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'completed') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'COMPLETED',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w800,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD97706).withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'UPCOMING',
          style: TextStyle(
            color: Color(0xFFD97706),
            fontWeight: FontWeight.w800,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
  }

  Widget _buildReminderButton(Map<String, dynamic> liveClass, bool isDark, Color primaryTextColor) {
    final List<dynamic> registered = liveClass['registeredStudents'] as List? ?? [];
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isRegistered = uid != null && registered.contains(uid);

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: isRegistered
            ? null
            : () async {
                try {
                  await UserService().registerForLiveClass(liveClass['id']);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reminder set successfully!')),
                    );
                    setState(() {}); // refresh UI to update button state
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to set reminder: ${e.toString()}')),
                    );
                  }
                }
              },
        icon: Icon(
          isRegistered ? Icons.notifications_active : Icons.notifications_none,
          size: 15,
          color: isRegistered ? Colors.green : Colors.white,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isRegistered ? Colors.grey.withOpacity(0.2) : const Color(0xFF7C3AED),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        label: Text(
          isRegistered ? 'Reminder Set' : 'Set Reminder',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isRegistered ? (isDark ? Colors.white38 : Colors.grey) : Colors.white,
          ),
        ),
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
