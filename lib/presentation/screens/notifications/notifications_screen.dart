import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  @override
  void initState() {
    super.initState();
    _markAsSeen();
  }

  Future<void> _markAsSeen() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
          'lastSeenNotificationsAt': FieldValue.serverTimestamp(),
        });
    } catch (e) {
      debugPrint('Mark seen error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> _getNotificationsStream() {
    return FirebaseFirestore.instance
      .collection('notifications')
      .where('target', isEqualTo: 'all')
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs
          .map((d) => {
            ...d.data(),
            'id': d.id,
          })
          .toList();
        
        docs.sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });
        
        return docs;
      });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF7F8FC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0D2240),
              ),
            );
          }
          
          if (snapshot.hasError) {
            debugPrint('Notif error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading notifications'),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final notifications = snapshot.data ?? [];
          
          debugPrint('Notifications count: ${notifications.length}');
          
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔔', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Color(0xFF0D2240),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "You'll see updates here",
                    style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (ctx, i) {
              final notif = notifications[i];
              return _buildNotifCard(notif);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> notif) {
    final type = notif['type'] as String? ?? 'announcement';
    final title = notif['title'] as String? ?? '';
    final body = notif['body'] as String? ?? '';
    final createdAt = notif['createdAt'] as Timestamp?;
    
    final Map<String, dynamic> typeConfig = {
      'announcement': {
        'icon': Icons.campaign_rounded,
        'color': const Color(0xFF0D2240),
        'bg': const Color(0xFFEEF2FF),
        'emoji': '📢'
      },
      'live_class': {
        'icon': Icons.live_tv_rounded,
        'color': const Color(0xFFEF4444),
        'bg': const Color(0xFFFEF2F2),
        'emoji': '🔴'
      },
      'reminder': {
        'icon': Icons.alarm_rounded,
        'color': const Color(0xFFF5A623),
        'bg': const Color(0xFFFFF8E7),
        'emoji': '⏰'
      },
      'promotion': {
        'icon': Icons.local_offer_rounded,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
        'emoji': '🎁'
      },
    };
    
    final config = typeConfig[type] ?? typeConfig['announcement']!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: config['bg'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  config['emoji'] as String,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
