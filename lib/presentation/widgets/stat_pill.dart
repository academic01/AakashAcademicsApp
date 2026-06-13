import 'package:flutter/material.dart';

class StatPill extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color? color;

  const StatPill({
    Key? key,
    required this.emoji,
    required this.value,
    required this.label,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color ?? (isDark ? Colors.white : const Color(0xFF0D2240)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black45,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
