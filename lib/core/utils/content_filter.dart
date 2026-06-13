/// Content filtering utility for profile-based personalization
/// Maps user profile (targetCourse + targetExam) to content categories

String? getCategoryFromProfile(String? targetCourse, String? targetExam) {
  final combined = '${targetCourse ?? ""} ${targetExam ?? ""}'.toLowerCase();

  if (combined.contains('cuet')) return 'cuet';
  if (combined.contains('school') ||
      combined.contains('vi-x') ||
      combined.contains('foundation'))
    return 'school';
  if (combined.contains('senior') ||
      combined.contains('xi-xii') ||
      combined.contains('science stream') ||
      combined.contains('commerce stream') ||
      combined.contains('humanities'))
    return 'senior';
  if (combined.contains('ssc') ||
      combined.contains('railway') ||
      combined.contains('dsssb') ||
      combined.contains('govt'))
    return 'govt';
  if (combined.contains('jee')) return 'jee';
  if (combined.contains('neet')) return 'neet';

  return null; // show all if unmatched
}

/// Get display name for category
String getCategoryDisplayName(String? category) {
  switch (category) {
    case 'cuet':
      return 'CUET';
    case 'school':
      return 'School';
    case 'senior':
      return 'Senior';
    case 'govt':
      return 'Govt Exams';
    case 'jee':
      return 'JEE';
    case 'neet':
      return 'NEET';
    default:
      return 'All';
  }
}
