import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';

class AskDoubtScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String? videoId;
  final String? videoTitle;

  const AskDoubtScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.videoId,
    this.videoTitle,
  });

  @override
  State<AskDoubtScreen> createState() => _AskDoubtScreenState();
}

class _AskDoubtScreenState extends State<AskDoubtScreen> {
  final _questionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submitDoubt() async {
    final text = _questionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('doubts').add({
        'userId': uid,
        'courseId': widget.courseId,
        'courseTitle': widget.courseTitle,
        'videoId': widget.videoId,
        'videoTitle': widget.videoTitle,
        'questionText': text,
        'status': 'pending',
        'answer': null,
        'answeredBy': null,
        'answeredAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isSubmitting = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Question submitted! Our faculty will answer soon.'),
          backgroundColor: Color(0xFF22C55E),
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Doubt', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D2240),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Context card
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle, color: Color(0xFF0D2240), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course: ${widget.courseTitle}',
                          style: const TextStyle(
                            color: Color(0xFF0D2240),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (widget.videoTitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Video: ${widget.videoTitle}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Question input
            const Text(
              'Your Question *',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _questionController,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Type your question clearly...\n\nExample: "I didn\'t understand the concept of X. Can you explain it differently?"',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterStyle: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tips box
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Tips for a good question:',
                    style: TextStyle(
                      color: Color(0xFFE65C00),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _tip('Be specific about what you don\'t understand'),
                  _tip('Mention the topic/chapter'),
                  _tip('Describe what you already tried'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDoubt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2240),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Submitting...', style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.send_1, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Submit Question',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(color: Color(0xFFE65C00))),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
}
