import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String facultyName;
  final String examType;
  final double rating;
  final double price;
  final double? originalPrice;
  final bool isFree;
  final bool isEnrolled;
  final bool isComingSoon;
  final bool isBestseller;
  final VoidCallback onTap;
  final VoidCallback onEnroll;

  const CourseCard({
    super.key,
    required this.title,
    required this.facultyName,
    required this.examType,
    required this.rating,
    required this.price,
    this.originalPrice,
    this.isFree = false,
    this.isEnrolled = false,
    this.isComingSoon = false,
    this.isBestseller = false,
    required this.onTap,
    required this.onEnroll,
  });

  LinearGradient _getGradientByExamType() {
    switch (examType.toLowerCase()) {
      case 'school':
        return const LinearGradient(
          colors: [Color(0xFF0D2240), Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'senior':
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'govt':
        return const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cuet':
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'jee':
      case 'neet':
        return LinearGradient(
          colors: [
            const Color(0xFF6B7280).withOpacity(0.8),
            const Color(0xFF374151).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF0D2240), Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getExamBadgeColor() {
    switch (examType.toLowerCase()) {
      case 'school':
        return const Color(0xFF0D2240);
      case 'senior':
        return const Color(0xFF7C3AED);
      case 'govt':
        return const Color(0xFF16A34A);
      case 'cuet':
        return const Color(0xFF7C3AED);
      case 'jee':
      case 'neet':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF0D2240);
    }
  }

  String _getExamLabel() {
    switch (examType.toLowerCase()) {
      case 'school':
        return 'SCHOOL';
      case 'senior':
        return 'SENIOR';
      case 'govt':
        return 'GOVT';
      case 'cuet':
        return 'CUET';
      case 'jee':
        return 'JEE';
      case 'neet':
        return 'NEET';
      default:
        return 'COURSE';
    }
  }

  String _getEmoji() {
    switch (examType.toLowerCase()) {
      case 'school':
        return '📚';
      case 'senior':
        return '🎓';
      case 'govt':
        return '🏛️';
      case 'cuet':
        return '🎯';
      case 'jee':
        return '🔬';
      case 'neet':
        return '💊';
      default:
        return '📖';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _getGradientByExamType(),
                    ),
                    height: 140,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -15,
                          right: -15,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getEmoji(),
                                style: const TextStyle(fontSize: 34),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getExamLabel(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isBestseller)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5A623),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'BESTSELLER',
                                style: TextStyle(
                                  color: Color(0xFF0D2240),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ),
                        if (isEnrolled)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ENROLLED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 8,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                        if (isComingSoon)
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFF0D2240),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ðŸš€ Coming',
                                  style: TextStyle(
                                    color: Color(0xFF0D2240),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getExamBadgeColor().withValues(alpha: 0.1),
                              border: Border.all(
                                color: _getExamBadgeColor(),
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getExamLabel(),
                              style: TextStyle(
                                color: _getExamBadgeColor(),
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (isFree)
                            const Text(
                              'FREE',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            )
                          else
                            Text(
                              'â‚¹${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF0D2240),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0D2240),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 14,
                            color: Color(0xFF888888),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              facultyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFF5A623),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFFF5A623),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '(1.2K reviews)',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          if (originalPrice != null)
                            Text(
                              'â‚¹${originalPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: _buildActionButton(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (isComingSoon) {
      return OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You will be notified when this course launches!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF888888), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: const Text(
          'ðŸ”” Notify Me',
          style: TextStyle(
            color: Color(0xFF888888),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    } else if (isEnrolled) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF0D2240), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: const Text(
          'Continue â†’',
          style: TextStyle(
            color: Color(0xFF0D2240),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: onEnroll,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D2240),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Enroll Now',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }
  }
}
