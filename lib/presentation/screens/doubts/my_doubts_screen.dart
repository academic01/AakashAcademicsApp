import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class MyDoubtsScreen extends StatefulWidget {
  const MyDoubtsScreen({super.key});

  @override
  State<MyDoubtsScreen> createState() => _MyDoubtsScreenState();
}

class _MyDoubtsScreenState extends State<MyDoubtsScreen> {
  final Map<String, bool> _expandedStates = {};

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return 'Just now';
    if (createdAt is Timestamp) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inDays > 7) {
        final date = createdAt.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'Just now';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0D2240);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Doubts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D2240),
        foregroundColor: Colors.white,
      ),
      body: uid == null
          ? const Center(child: Text('Please log in to view your doubts.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doubts')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🤔', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 16),
                          Text(
                            'No doubts asked yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Ask a doubt from any course or video you're studying",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 200,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => context.go('/courses'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D2240),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text(
                                'Browse Courses →',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Client-side sort to avoid requiring composite indexes (Requirement 1)
                final docs = List<DocumentSnapshot>.from(snapshot.data!.docs);
                docs.sort((a, b) {
                  final aTime = a['createdAt'] as Timestamp?;
                  final bTime = b['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime); // descending
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final status = data['status'] ?? 'pending';
                    final isAnswered = status == 'answered';
                    final isExpanded = _expandedStates[docId] ?? false;

                    final String courseTitle = data['courseTitle'] ?? 'Course';
                    final String questionText = data['questionText'] ?? '';
                    final String? answer = data['answer'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedStates[docId] = !isExpanded;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isAnswered ? const Color(0xFFDCFCE7) : const Color(0xFFFFF8E7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isAnswered ? Iconsax.tick_circle : Iconsax.clock,
                                color: isAnswered ? const Color(0xFF16A34A) : const Color(0xFFF5A623),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          courseTitle.toUpperCase(),
                                          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isAnswered ? const Color(0xFF16A34A).withOpacity(0.1) : const Color(0xFFF5A623).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isAnswered ? 'Answered' : 'Pending',
                                          style: TextStyle(
                                            color: isAnswered ? const Color(0xFF16A34A) : const Color(0xFFF5A623),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    questionText,
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: isExpanded ? null : 3,
                                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatTime(data['createdAt']),
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  if (isAnswered && answer != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '💬 Faculty Answer:',
                                            style: TextStyle(
                                              color: Color(0xFF16A34A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            answer,
                                            style: const TextStyle(
                                              color: Color(0xFF166534),
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
