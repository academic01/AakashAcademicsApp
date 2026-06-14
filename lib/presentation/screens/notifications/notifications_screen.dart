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
  // IDs of notifications the user has individually dismissed
  Set<String> _dismissedIds = {};
  // If set, notifications created before this time are hidden (Clear All)
  Timestamp? _clearedAt;
  bool _userDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserDismissState();
    _markAsSeen();
  }

  /// Load dismissed IDs and clearedAt from the user's Firestore doc
  Future<void> _loadUserDismissState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!mounted) return;

      final data = doc.data() ?? {};
      final dismissed = List<String>.from(
          data['dismissedNotificationIds'] ?? []);
      final clearedAt = data['notificationsClearedAt'] as Timestamp?;

      setState(() {
        _dismissedIds = dismissed.toSet();
        _clearedAt = clearedAt;
        _userDataLoaded = true;
      });
    } catch (e) {
      debugPrint('Load dismiss state error: $e');
      if (mounted) setState(() => _userDataLoaded = true);
    }
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

  /// Dismiss a single notification — stores its ID in user's Firestore doc
  Future<void> _dismissNotification(String id) async {
    setState(() => _dismissedIds.add(id));

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'dismissedNotificationIds': FieldValue.arrayUnion([id]),
      });
    } catch (e) {
      debugPrint('Dismiss error: $e');
      // Roll back if Firestore update failed
      if (mounted) setState(() => _dismissedIds.remove(id));
    }
  }

  /// Clear all notifications — stores a timestamp in user's Firestore doc
  Future<void> _clearAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Optimistic update
    final now = Timestamp.now();
    setState(() {
      _clearedAt = now;
      _dismissedIds = {};
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'notificationsClearedAt': FieldValue.serverTimestamp(),
        // Also reset the individual dismissed list
        'dismissedNotificationIds': [],
      });
    } catch (e) {
      debugPrint('Clear all error: $e');
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

      // Sort client-side by createdAt descending (newest first)
      docs.sort((a, b) {
        final aTime =
            (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bTime =
            (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });

      return docs;
    });
  }

  /// Filter raw notifications by dismissed IDs and clearedAt timestamp
  List<Map<String, dynamic>> _filterNotifications(
      List<Map<String, dynamic>> all) {
    return all.where((notif) {
      final id = notif['id'] as String? ?? '';

      // Skip individually dismissed
      if (_dismissedIds.contains(id)) return false;

      // Skip notifications created before "Clear All" timestamp
      if (_clearedAt != null) {
        final createdAt = notif['createdAt'] as Timestamp?;
        if (createdAt != null &&
            createdAt.millisecondsSinceEpoch <=
                _clearedAt!.millisecondsSinceEpoch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear All Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'This will remove all notifications from your view. New notifications will still appear.',
          style: TextStyle(color: Color(0xFF555555), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Clear All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
        actions: [
          TextButton.icon(
            onPressed: _showClearAllDialog,
            icon: const Icon(Icons.clear_all_rounded,
                size: 18, color: Color(0xFFEF4444)),
            label: const Text(
              'Clear All',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: !_userDataLoaded
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D2240)))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getNotificationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF0D2240)),
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
                          style: const TextStyle(
                              fontSize: 11, color: Colors.red),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allNotifications = snapshot.data ?? [];
                final notifications = _filterNotifications(allNotifications);

                debugPrint(
                    'Notifications count: ${notifications.length} (of ${allNotifications.length} total)');

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔔',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text(
                          'No notifications',
                          style: TextStyle(
                            color: Color(0xFF0D2240),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          "You'll see updates here",
                          style: TextStyle(
                              color: Color(0xFF888888), fontSize: 13),
                        ),
                        if (_clearedAt != null || _dismissedIds.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextButton(
                              onPressed: () async {
                                // Undo: reset cleared state
                                final uid = FirebaseAuth
                                    .instance.currentUser?.uid;
                                if (uid == null) return;
                                setState(() {
                                  _clearedAt = null;
                                  _dismissedIds = {};
                                });
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update({
                                  'notificationsClearedAt':
                                      FieldValue.delete(),
                                  'dismissedNotificationIds': [],
                                });
                              },
                              child: const Text(
                                'Restore notifications',
                                style: TextStyle(
                                    color: Color(0xFF0D2240),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
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
                    final id = notif['id'] as String? ?? '';
                    return Dismissible(
                      key: Key(id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.white, size: 26),
                            SizedBox(height: 4),
                            Text('Remove',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        await _dismissNotification(id);
                        return false; // We manage removal via state
                      },
                      child: _buildNotifCard(notif),
                    );
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
            color: Colors.black.withValues(alpha: 0.04),
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
