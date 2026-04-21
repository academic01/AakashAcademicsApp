class StudentProfile {
  const StudentProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.classLevel,
    required this.selectedCourse,
    this.schoolName,
  });

  final String fullName;
  final String phoneNumber;
  final String classLevel;
  final String selectedCourse;
  final String? schoolName;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'classLevel': classLevel,
      'selectedCourse': selectedCourse,
      'schoolName': schoolName,
    };
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      classLevel: json['classLevel'] as String? ?? '',
      selectedCourse: json['selectedCourse'] as String? ?? '',
      schoolName: json['schoolName'] as String?,
    );
  }

  String get initial {
    final trimmed = fullName.trim();
    return trimmed.isEmpty ? 'S' : trimmed[0].toUpperCase();
  }

  String get displayClassAndCourse => '$classLevel • $selectedCourse';
}
