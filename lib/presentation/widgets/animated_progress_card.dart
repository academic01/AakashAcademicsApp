import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';

class AnimatedProgressCard extends StatelessWidget {
  final double progress; // between 0.0 and 1.0
  final String title;

  const AnimatedProgressCard({
    super.key,
    required this.progress,
    this.title = "Today's Goal",
  });

  String _getMotivationalText(double pct) {
    if (pct <= 0.0) return "Let's start! 🚀";
    if (pct < 0.4) return "Off to a great start! 💪";
    if (pct < 0.7) return "Halfway there! Keep going! 🔥";
    if (pct < 1.0) return "Almost complete! You got this! ✨";
    return "Goal smashed! 🎉";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0D2240),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getMotivationalText(pct),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircularPercentIndicator(
            radius: 35.0,
            lineWidth: 8.0,
            animation: true,
            animationDuration: 1000,
            percent: pct,
            center: Text(
              "${(pct * 100).round()}%",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0D2240),
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: isDark ? AppColors.secondary : AppColors.primary,
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ).animate().scale(delay: 200.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
