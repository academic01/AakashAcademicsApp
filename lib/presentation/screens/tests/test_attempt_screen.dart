import 'package:flutter/material.dart';

class TestAttemptScreen extends StatefulWidget {
  final String testId;

  const TestAttemptScreen({Key? key, required this.testId}) : super(key: key);

  @override
  State<TestAttemptScreen> createState() => _TestAttemptScreenState();
}

class _TestAttemptScreenState extends State<TestAttemptScreen> {
  late PageController _pageController;
  int _currentQuestion = 0;
  final int _totalQuestions = 100;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // TODO: Show confirmation dialog before leaving
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test Attempt'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '${_currentQuestion + 1}/$_totalQuestions',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Timer and progress
            Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFFF9F9F9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer),
                      const SizedBox(width: 8),
                      const Text('Time: 2:30:45'),
                    ],
                  ),
                  LinearProgressIndicator(
                    value: (_currentQuestion + 1) / _totalQuestions,
                    minHeight: 6,
                  ),
                ],
              ),
            ),
            // Questions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentQuestion = index;
                  });
                },
                itemCount: _totalQuestions,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Question content goes here'),
                        const SizedBox(height: 24),
                        // Options
                        ...List.generate(4, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: RadioListTile<int>(
                              value: i,
                              groupValue: -1,
                              onChanged: (value) {
                                // TODO: Save answer
                              },
                              title: Text(
                                'Option ${String.fromCharCode(65 + i)}',
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentQuestion > 0
                        ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Submit test
                    },
                    child: const Text('Submit'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _currentQuestion < _totalQuestions - 1
                        ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
