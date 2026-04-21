class UserModel {
  final String uid;
  final String phone;
  final String? email;
  final String? name;
  final String? schoolCollege;
  final String? currentClass;
  final String? targetCourse;
  final String? targetExam;
  final String? avatar;
  final bool isProfileComplete;
  final bool isNewUser;
  final String? token;
  final int xp;
  final int streak;
  final String rank;
  final List<String> enrolledCourses;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.phone,
    this.email,
    this.name,
    this.schoolCollege,
    this.currentClass,
    this.targetCourse,
    this.targetExam,
    this.avatar,
    this.isProfileComplete = false,
    this.isNewUser = true,
    this.token,
    this.xp = 0,
    this.streak = 0,
    this.rank = 'Rookie',
    this.enrolledCourses = const [],
    required this.createdAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phone': phone,
      'email': email,
      'name': name,
      'schoolCollege': schoolCollege,
      'currentClass': currentClass,
      'targetCourse': targetCourse,
      'targetExam': targetExam,
      'avatar': avatar,
      'isProfileComplete': isProfileComplete,
      'isNewUser': isNewUser,
      'token': token,
      'xp': xp,
      'streak': streak,
      'rank': rank,
      'enrolledCourses': enrolledCourses,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      name: json['name'],
      schoolCollege: json['schoolCollege'],
      currentClass: json['currentClass'],
      targetCourse: json['targetCourse'],
      targetExam: json['targetExam'],
      avatar: json['avatar'],
      isProfileComplete: json['isProfileComplete'] ?? false,
      isNewUser: json['isNewUser'] ?? true,
      token: json['token'],
      xp: json['xp'] ?? 0,
      streak: json['streak'] ?? 0,
      rank: json['rank'] ?? 'Rookie',
      enrolledCourses: List<String>.from(json['enrolledCourses'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // Copy with method
  UserModel copyWith({
    String? name,
    String? email,
    String? schoolCollege,
    String? currentClass,
    String? targetCourse,
    String? targetExam,
    String? avatar,
    bool? isProfileComplete,
    int? xp,
    int? streak,
    String? rank,
    List<String>? enrolledCourses,
  }) {
    return UserModel(
      uid: uid,
      phone: phone,
      email: email ?? this.email,
      name: name ?? this.name,
      schoolCollege: schoolCollege ?? this.schoolCollege,
      currentClass: currentClass ?? this.currentClass,
      targetCourse: targetCourse ?? this.targetCourse,
      targetExam: targetExam ?? this.targetExam,
      avatar: avatar ?? this.avatar,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isNewUser: false,
      token: token,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      rank: rank ?? this.rank,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, phone: $phone, name: $name)';
}
