import 'package:cloud_firestore/cloud_firestore.dart';

String timeAgo(Timestamp? timestamp) {
  if (timestamp == null) return '';
  final date = timestamp.toDate();
  final now = DateTime.now();
  final diff = now.difference(date);
  
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  
  return '${date.day}/${date.month}/${date.year}';
}
