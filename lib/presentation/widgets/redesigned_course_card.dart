import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/gradients.dart';

class RedesignedCourseCard extends StatefulWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;
  final bool isEnrolled;
  final int index;

  const RedesignedCourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.isEnrolled = false,
    this.index = 0,
  });

  @override
  State<RedesignedCourseCard> createState() => _RedesignedCourseCardState();
}

class _RedesignedCourseCardState extends State<RedesignedCourseCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final category = (course['category'] ?? 'school') as String;
    final gradient = AppGradients.getGradientForCategory(category);
    final emoji = AppGradients.getEmojiForCategory(category);
    
    final status = (course['status'] ?? 'active') as String;
    final isComingSoon = status == 'coming_soon';

    final isBestSeller = course['isBestseller'] == true;
    final isNew = course['isNew'] == true;

    final title = (course['title'] ?? 'Course Title') as String;
    final facultyName = (course['facultyName'] ?? 'Expert Faculty') as String;
    final price = course['price'] ?? 0;
    final rating = (course['rating'] as num? ?? 4.5).toDouble();

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _scale = 0.97);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Gradient Header Strip
              Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    // Semi-transparent emoji icon background
                    Positioned(
                      right: 12,
                      bottom: -15,
                      child: Opacity(
                        opacity: 0.15,
                        child: Text(
                          emoji,
                          style: const TextStyle(
                            fontSize: 70,
                            fontFamily: 'Emoji',
                          ),
                        ),
                      ),
                    ),
                    // Badges
                    if (isBestSeller || isNew)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            isBestSeller ? '🔥 BESTSELLER' : '✨ NEW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isBestSeller
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Body Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Faculty & Rating row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: gradient.colors.first.withValues(alpha: 0.2),
                          child: Text(
                            facultyName.isNotEmpty ? facultyName[0] : 'T',
                            style: TextStyle(
                              color: gradient.colors.first,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            facultyName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFF5A623),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Price and Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          price == 0 ? 'FREE' : '₹$price',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0D2240),
                          ),
                        ),
                        // Action Button
                        _buildActionButton(context, isComingSoon, gradient),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (widget.index * 50).ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildActionButton(BuildContext context, bool isComingSoon, LinearGradient gradient) {
    if (isComingSoon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 14, color: Colors.grey),
            SizedBox(width: 4),
            Text(
              'Notify Me',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isEnrolled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: gradient.colors.first, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Continue',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: gradient.colors.first,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.play_circle_outline_rounded,
              size: 14,
              color: gradient.colors.first,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        'Enroll Now',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
