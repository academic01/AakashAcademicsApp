/// Content filtering utility for profile-based personalization
/// Maps user profile (targetCourse + targetExam + currentClass) to content categories

class ContentFilter {
  static String? getCategoryFromProfile({
    String? targetCourse,
    String? targetExam,
    String? currentClass,
  }) {
    // Normalize: lowercase, trim all
    final course = (targetCourse ?? '').toLowerCase().trim();
    final exam = (targetExam ?? '').toLowerCase().trim();
    final cls = (currentClass ?? '').toLowerCase().trim();

    // Combine all three for matching
    final combined = '$course $exam $cls';

    // ── CUET ──
    if (combined.contains('cuet')) {
      return 'cuet';
    }

    // ── GOVT JOBS ──
    if (combined.contains('ssc') ||
        combined.contains('railway') ||
        combined.contains('dsssb') ||
        combined.contains('govt') ||
        combined.contains('government') ||
        combined.contains('police') ||
        combined.contains('banking') ||
        combined.contains('upsc')) {
      return 'govt';
    }

    // ── JEE ──
    if (combined.contains('jee')) {
      return 'jee';
    }

    // ── NEET ──
    if (combined.contains('neet')) {
      return 'neet';
    }

    // ── SENIOR / XI-XII / Boards 11-12 ──
    // IMPORTANT: check BEFORE 'school'
    // because "school" text can appear
    // in senior-level strings too
    if (combined.contains('xi') ||
        combined.contains('xii') ||
        combined.contains('11') ||
        combined.contains('12') ||
        combined.contains('senior') ||
        combined.contains('junior college') ||
        combined.contains('intermediate') ||
        combined.contains('science stream') ||
        combined.contains('commerce stream') ||
        combined.contains('humanities') ||
        combined.contains('arts stream') ||
        combined.contains('boards (xi') ||
        combined.contains('board xi')) {
      return 'senior';
    }

    // ── SCHOOL / VI-X / Boards 6-10 ──
    if (combined.contains('vi') ||
        combined.contains('vii') ||
        combined.contains('viii') ||
        combined.contains('ix') ||
        combined.contains('class 6') ||
        combined.contains('class 7') ||
        combined.contains('class 8') ||
        combined.contains('class 9') ||
        combined.contains('class 10') ||
        combined.contains('school success') ||
        combined.contains('foundation') ||
        combined.contains('middle school') ||
        combined.contains('boards (vi') ||
        combined.contains('board vi')) {
      return 'school';
    }

    // ── FALLBACK: null = show all ──
    return null;
  }

  static String getCategoryDisplayName(String? category) {
    switch (category) {
      case 'school':
        return 'School (VI-X)';
      case 'senior':
        return 'Boards (XI-XII)';
      case 'govt':
        return 'Govt Jobs';
      case 'cuet':
        return 'CUET 2026';
      case 'jee':
        return 'JEE';
      case 'neet':
        return 'NEET';
      default:
        return 'All Courses';
    }
  }

  static bool classMatchesCategory(Map<String, dynamic> liveClass, String? category) {
    if (category == null) return false;
    final subject = (liveClass['subject'] ?? '').toString().toLowerCase();
    final title = (liveClass['title'] ?? '').toString().toLowerCase();
    final combined = '$subject $title';

    switch (category) {
      case 'senior':
        return combined.contains('xi') ||
            combined.contains('xii') ||
            combined.contains('12') ||
            combined.contains('11') ||
            combined.contains('senior') ||
            combined.contains('humanities') ||
            combined.contains('commerce') ||
            combined.contains('science');
      case 'school':
        return combined.contains('vi') ||
            combined.contains('class 6') ||
            combined.contains('class 7') ||
            combined.contains('class 8') ||
            combined.contains('class 9') ||
            combined.contains('class 10') ||
            combined.contains('school');
      case 'govt':
        return combined.contains('ssc') ||
            combined.contains('railway') ||
            combined.contains('dsssb') ||
            combined.contains('govt');
      case 'cuet':
        return combined.contains('cuet');
      default:
        return false;
    }
  }
}
