import 'package:flutter/material.dart';

class TestResultScreen extends StatefulWidget {
  final String resultId;

  const TestResultScreen({Key? key, required this.resultId}) : super(key: key);

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Score circle
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0D2240), width: 4),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '87.5',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2240),
                      ),
                    ),
                    Text(
                      'out of 100',
                      style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Result details
            _buildResultTile('Total Questions', '100'),
            _buildResultTile('Correct Answers', '87'),
            _buildResultTile('Wrong Answers', '10'),
            _buildResultTile('Unanswered', '3'),
            const SizedBox(height: 24),
            // Rank and percentile
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Your Rank'),
                      Text(
                        '245/1000',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Percentile'),
                      Text(
                        '75.5%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            ElevatedButton.icon(
              onPressed: () {
                // TODO: View solutions
              },
              icon: const Icon(Icons.description),
              label: const Text('View Solutions'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Retake test
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retake Test'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
