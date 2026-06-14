import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 10,
    this.padding,
    this.border,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ??
                (isDark
                    ? AppColors.darkCard.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.3)
                      : AppColors.border.withValues(alpha: 0.5),
                  width: 1.5,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}
