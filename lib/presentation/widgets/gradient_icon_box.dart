import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class GradientIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient? gradient;
  final Color? iconColor;
  final double padding;
  final double borderRadius;

  const GradientIconBox({
    super.key,
    required this.icon,
    this.size = 24,
    this.gradient,
    this.iconColor,
    this.padding = 10,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient ?? AppColors.secondaryGradient,
        boxShadow: [
          BoxShadow(
            color: (gradient?.colors.first ?? AppColors.secondary).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size,
        color: iconColor ?? Colors.white,
      ),
    );
  }
}
