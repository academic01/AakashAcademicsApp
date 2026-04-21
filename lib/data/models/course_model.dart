enum CourseCategory { school, cuet, govt, jee, neet }

enum CourseDifficulty { beginner, intermediate, advanced }

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String category; // CUET, GOVT, JEE, NEET, CLASS_6-12
  final String difficulty;
  final double price;
  final double? discountedPrice;
  final int totalLessons;
  final int totalDuration; // in minutes
  final double rating;
  final int reviewCount;
  final String instructorId;
  final String instructorName;
  final String? instructorImage;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLive;
  final bool isFeatured;
  final List<String> tags;
  final int enrolledCount;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.category,
    required this.difficulty,
    required this.price,
    this.discountedPrice,
    required this.totalLessons,
    required this.totalDuration,
    required this.rating,
    required this.reviewCount,
    required this.instructorId,
    required this.instructorName,
    this.instructorImage,
    required this.createdAt,
    this.startDate,
    this.endDate,
    required this.isLive,
    required this.isFeatured,
    required this.tags,
    required this.enrolledCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'difficulty': difficulty,
      'price': price,
      'discountedPrice': discountedPrice,
      'totalLessons': totalLessons,
      'totalDuration': totalDuration,
      'rating': rating,
      'reviewCount': reviewCount,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'instructorImage': instructorImage,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isLive': isLive,
      'isFeatured': isFeatured,
      'tags': tags,
      'enrolledCount': enrolledCount,
    };
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'intermediate',
      price: (json['price'] ?? 0).toDouble(),
      discountedPrice: json['discountedPrice'] != null
          ? (json['discountedPrice']).toDouble()
          : null,
      totalLessons: json['totalLessons'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      instructorId: json['instructorId'] ?? '',
      instructorName: json['instructorName'] ?? '',
      instructorImage: json['instructorImage'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isLive: json['isLive'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      enrolledCount: json['enrolledCount'] ?? 0,
    );
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? category,
    String? difficulty,
    double? price,
    double? discountedPrice,
    int? totalLessons,
    int? totalDuration,
    double? rating,
    int? reviewCount,
    String? instructorId,
    String? instructorName,
    String? instructorImage,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLive,
    bool? isFeatured,
    List<String>? tags,
    int? enrolledCount,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      totalLessons: totalLessons ?? this.totalLessons,
      totalDuration: totalDuration ?? this.totalDuration,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      instructorImage: instructorImage ?? this.instructorImage,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLive: isLive ?? this.isLive,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      enrolledCount: enrolledCount ?? this.enrolledCount,
    );
  }

  @override
  String toString() => 'CourseModel(id: $id, title: $title)';
}
