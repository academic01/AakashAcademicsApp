enum TestType { mock, practice, fullLength }

enum TestStatus { notStarted, inProgress, completed, expired }

class TestModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final String category; // CUET, GOVT, JEE, NEET
  final String testType; // mock, practice, fullLength
  final int totalQuestions;
  final int totalMarks;
  final int durationMinutes;
  final int negativeMarks; // in percentage
  final double? passingPercentage;
  final DateTime createdAt;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isLive;
  final bool isFeatured;
  final int totalAttempts;
  final double averageScore;
  final int totalParticipants;
  final List<String> topics;
  final String? solutionUrl;

  TestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    required this.category,
    required this.testType,
    required this.totalQuestions,
    required this.totalMarks,
    required this.durationMinutes,
    required this.negativeMarks,
    this.passingPercentage,
    required this.createdAt,
    required this.startDateTime,
    required this.endDateTime,
    required this.isLive,
    required this.isFeatured,
    required this.totalAttempts,
    required this.averageScore,
    required this.totalParticipants,
    required this.topics,
    this.solutionUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'courseId': courseId,
      'category': category,
      'testType': testType,
      'totalQuestions': totalQuestions,
      'totalMarks': totalMarks,
      'durationMinutes': durationMinutes,
      'negativeMarks': negativeMarks,
      'passingPercentage': passingPercentage,
      'createdAt': createdAt.toIso8601String(),
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'isLive': isLive,
      'isFeatured': isFeatured,
      'totalAttempts': totalAttempts,
      'averageScore': averageScore,
      'totalParticipants': totalParticipants,
      'topics': topics,
      'solutionUrl': solutionUrl,
    };
  }

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      courseId: json['courseId'] ?? '',
      category: json['category'] ?? '',
      testType: json['testType'] ?? 'practice',
      totalQuestions: json['totalQuestions'] ?? 0,
      totalMarks: json['totalMarks'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      negativeMarks: json['negativeMarks'] ?? 0,
      passingPercentage: json['passingPercentage'] != null
          ? (json['passingPercentage']).toDouble()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      startDateTime: json['startDateTime'] != null
          ? DateTime.parse(json['startDateTime'])
          : DateTime.now(),
      endDateTime: json['endDateTime'] != null
          ? DateTime.parse(json['endDateTime'])
          : DateTime.now().add(const Duration(hours: 2)),
      isLive: json['isLive'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      totalAttempts: json['totalAttempts'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      totalParticipants: json['totalParticipants'] ?? 0,
      topics: List<String>.from(json['topics'] ?? []),
      solutionUrl: json['solutionUrl'],
    );
  }

  TestModel copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    String? category,
    String? testType,
    int? totalQuestions,
    int? totalMarks,
    int? durationMinutes,
    int? negativeMarks,
    double? passingPercentage,
    DateTime? createdAt,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isLive,
    bool? isFeatured,
    int? totalAttempts,
    double? averageScore,
    int? totalParticipants,
    List<String>? topics,
    String? solutionUrl,
  }) {
    return TestModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      category: category ?? this.category,
      testType: testType ?? this.testType,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalMarks: totalMarks ?? this.totalMarks,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      negativeMarks: negativeMarks ?? this.negativeMarks,
      passingPercentage: passingPercentage ?? this.passingPercentage,
      createdAt: createdAt ?? this.createdAt,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      isLive: isLive ?? this.isLive,
      isFeatured: isFeatured ?? this.isFeatured,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      averageScore: averageScore ?? this.averageScore,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      topics: topics ?? this.topics,
      solutionUrl: solutionUrl ?? this.solutionUrl,
    );
  }

  @override
  String toString() => 'TestModel(id: $id, title: $title)';
}
