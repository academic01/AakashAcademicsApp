import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TestResultScreen extends StatefulWidget {
  final String resultId;

  const TestResultScreen({super.key, required this.resultId});

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  Map<String, dynamic>? _resultData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResultData();
  }

  Future<void> _loadResultData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('testResults').doc(widget.resultId).get();
      if (doc.exists && mounted) {
        setState(() {
          _resultData = doc.data();
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_resultData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test Result')),
        body: const Center(
          child: Text('Test result document not found.'),
        ),
      );
    }

    final testTitle = _resultData!['testTitle'] ?? 'Test Result';
    final score = _resultData!['score'] ?? 0;
    final totalMarks = _resultData!['totalMarks'] ?? 0;
    final percentage = _resultData!['percentage'] ?? 0;
    final xpEarned = _resultData!['xpEarned'] ?? 50;
    final timeTaken = _resultData!['timeTakenSeconds'] ?? 0;
    final wrongAnswers = totalMarks - score;

    return Scaffold(
      appBar: AppBar(title: Text(testTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Text(
              testTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D2240)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Score circle
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: percentage >= 70 ? const Color(0xFF22C55E) : const Color(0xFF0D2240),
                  width: 6,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: percentage >= 70 ? const Color(0xFF22C55E) : const Color(0xFF0D2240),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$score / $totalMarks Marks',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF888888), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Result statistics card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  _buildResultRow('Correct Answers', '$score', Colors.green),
                  const Divider(),
                  _buildResultRow('Incorrect Answers', '$wrongAnswers', Colors.red),
                  const Divider(),
                  _buildResultRow('Time Taken', _formatTime(timeTaken), Colors.black87),
                  const Divider(),
                  _buildResultRow('XP Earned', '+$xpEarned XP', const Color(0xFFF5A623)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Back button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/tests');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2240),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  'Back to Tests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666), fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}
