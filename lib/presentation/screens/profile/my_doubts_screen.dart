import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

class MyDoubtsScreen extends StatelessWidget {
  const MyDoubtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0D2240);
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text(
          'My Doubts Q&A',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D2240),
        foregroundColor: Colors.white,
      ),
      body: uid.isEmpty
          ? const Center(child: Text('Please log in to view your doubts.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doubts')
                  .where('userId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading doubts: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            'No Doubts Asked Yet',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Got stuck while watching a video lecture? Use the "Ask a Doubt" button under any player to submit your queries.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final doubts = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: doubts.length,
                  itemBuilder: (context, index) {
                    final doubt = doubts[index].data() as Map<String, dynamic>;
                    final videoTitle = doubt['videoTitle'] ?? 'Lecture Video';
                    final question = doubt['question'] ?? 'No question text';
                    final answer = doubt['answer'] as String?;
                    final status = doubt['status'] ?? 'pending';
                    final isAnswered = status == 'resolved' || (answer != null && answer.isNotEmpty);

                    final statusColor = isAnswered ? Colors.green : Colors.orange;
                    final statusLabel = isAnswered ? 'ANSWERED' : 'PENDING TUTOR';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.04),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  videoTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Q: $question',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                          if (isAnswered) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡 ', style: TextStyle(fontSize: 16)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tutor Answer',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        answer!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 10),
                            Text(
                              'Our educators are reviewing your question. You will see their answer here.',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
