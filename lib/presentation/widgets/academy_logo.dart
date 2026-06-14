import 'package:flutter/material.dart';

class AcademyLogo extends StatelessWidget {
  const AcademyLogo({
    super.key,
    this.iconSize = 120,
    this.showWordmark = true,
    this.primaryColor = const Color(0xFF10324B),
    this.accentColor = const Color(0xFFF0B400),
    this.textColor = const Color(0xFF10324B),
    this.subtitleColor = const Color(0xFF10324B),
    this.pageColor = Colors.white,
  });

  final double iconSize;
  final bool showWordmark;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Color subtitleColor;
  final Color pageColor;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
    );
  }
}
