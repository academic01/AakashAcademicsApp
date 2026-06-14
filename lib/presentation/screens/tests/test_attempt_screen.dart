import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/user_service.dart';

class TestAttemptScreen extends StatefulWidget {
  final String testId;

  const TestAttemptScreen({super.key, required this.testId});

  @override
  State<TestAttemptScreen> createState() => _TestAttemptScreenState();
}

class _TestAttemptScreenState extends State<TestAttemptScreen> {
  final DatabaseService _dbService = DatabaseService();
  late PageController _pageController;
  int _currentQuestionIdx = 0;
  List<Map<String, dynamic>> _questions = [];
  Map<String, int> _answers = {};
  bool _loading = true;
  String _testTitle = 'Test Attempt';
  
  // Timer state
  int _timeTakenSeconds = 0;
  Timer? _timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadTestData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeTakenSeconds++;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    
    final hStr = h > 0 ? '${h.toString().padLeft(2, '0')}:' : '';
    final mStr = '${m.toString().padLeft(2, '0')}:';
    final sStr = s.toString().padLeft(2, '0');
    
    return '$hStr$mStr$sStr';
  }

  Future<void> _loadTestData() async {
    try {
      final testDoc = await FirebaseFirestore.instance.collection('tests').doc(widget.testId).get();
      if (testDoc.exists) {
        _testTitle = testDoc.data()?['title'] ?? 'Test';
      }
      
      final qList = await _dbService.getTestQuestions(widget.testId);
      if (mounted) {
        setState(() {
          _questions = qList;
          _loading = false;
        });
        if (_questions.isNotEmpty) {
          _startTimer();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _submitTest() async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit Test'),
        content: Text('Are you sure you want to submit? You have answered ${_answers.length} out of ${_questions.length} questions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D2240)),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final res = await UserService().submitTestResult(
        testId: widget.testId,
        testTitle: _testTitle,
        answers: _answers,
        questions: _questions,
        timeTakenSeconds: _timeTakenSeconds,
      );

      if (!mounted) return;
      
      // Go to test result screen
      context.replace('/tests/result/${res['resultId']}');
    } catch (e) {
      setState(() => _isSubmitting = false);
      _startTimer(); // resume timer on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit test results: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_testTitle),
          backgroundColor: const Color(0xFF0D2240),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'This test is being prepared',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2240),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Questions are not available yet for this test. Please check back later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2240),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIdx];
    final questionId = currentQuestion['id'] as String;
    final selectedOption = _answers[questionId];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Exit Test?'),
            content: const Text('Are you sure you want to leave? Your progress for this attempt will not be saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Resume'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (exit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_testTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  '${_currentQuestionIdx + 1}/${_questions.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: _isSubmitting
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Submitting test results... Please wait.'),
                  ],
                ),
              )
            : Column(
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
                            const Icon(Icons.timer_outlined, color: Color(0xFF0D2240)),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_timeTakenSeconds),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_currentQuestionIdx + 1) / _questions.length,
                              minHeight: 6,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D2240)),
                              backgroundColor: Colors.black12,
                            ),
                          ),
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
                          _currentQuestionIdx = index;
                        });
                      },
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        final qText = question['questionText'] ?? 'Question Text';
                        final options = List<String>.from(question['options'] ?? []);

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Question ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D2240),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                qText,
                                style: const TextStyle(fontSize: 15, height: 1.5),
                              ),
                              const SizedBox(height: 24),
                              // Options
                              ...List.generate(options.length, (i) {
                                final isSelected = selectedOption == i;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF0D2240) : Colors.black12,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected ? const Color(0xFF0D2240).withValues(alpha: 0.05) : Colors.white,
                                  ),
                                  child: RadioListTile<int>(
                                    value: i,
                                    groupValue: selectedOption,
                                    activeColor: const Color(0xFF0D2240),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value != null) {
                                          _answers[question['id']] = value;
                                        }
                                      });
                                    },
                                    title: Text(
                                      options[i],
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? const Color(0xFF0D2240) : Colors.black87,
                                      ),
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
                          onPressed: _currentQuestionIdx > 0
                              ? () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2240),
                          ),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          label: const Text('Previous', style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: _submitTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                          ),
                          child: const Text('Submit Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton.icon(
                          onPressed: _currentQuestionIdx < _questions.length - 1
                              ? () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2240),
                          ),
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          label: const Text('Next', style: TextStyle(color: Colors.white)),
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
