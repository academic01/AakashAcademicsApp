import 'dart:math' as math;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: iconSize,
          height: iconSize * 0.72,
          child: CustomPaint(
            painter: _AcademyLogoPainter(
              primaryColor: primaryColor,
              accentColor: accentColor,
              pageColor: pageColor,
            ),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: iconSize * 0.1),
          Text(
            'AAKASH',
            style: TextStyle(
              fontSize: iconSize * 0.25,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: iconSize * 0.02,
              height: 1,
            ),
          ),
          SizedBox(height: iconSize * 0.015),
          Text(
            'ACADEMICS',
            style: TextStyle(
              fontSize: iconSize * 0.1,
              fontWeight: FontWeight.w700,
              color: subtitleColor,
              letterSpacing: iconSize * 0.055,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class _AcademyLogoPainter extends CustomPainter {
  const _AcademyLogoPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.pageColor,
  });

  final Color primaryColor;
  final Color accentColor;
  final Color pageColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final lightPaint = Paint()
      ..color = pageColor
      ..style = PaintingStyle.fill;

    final eraserPaint = Paint()
      ..color = const Color(0xFFE47B89)
      ..style = PaintingStyle.fill;

    final bookRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.06,
        size.height * 0.58,
        size.width * 0.42,
        size.height * 0.18,
      ),
      Radius.circular(size.height * 0.09),
    );
    canvas.drawRRect(bookRect, fillPaint);
    canvas.drawRRect(bookRect, strokePaint);

    final pagesRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.085,
        size.height * 0.615,
        size.width * 0.315,
        size.height * 0.11,
      ),
      Radius.circular(size.height * 0.05),
    );
    canvas.drawRRect(pagesRect, lightPaint);
    canvas.drawRRect(pagesRect, strokePaint);

    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.64 + (i * 0.02));
      canvas.drawLine(
        Offset(size.width * 0.11, y),
        Offset(size.width * 0.375, y),
        Paint()
          ..color = primaryColor.withOpacity(0.75)
          ..strokeWidth = size.width * 0.006
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.save();
    canvas.translate(size.width * 0.19, size.height * 0.5);
    canvas.rotate(-math.pi / 4.4);
    final pencilBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, -size.height * 0.03, size.width * 0.23, size.height * 0.06),
      Radius.circular(size.height * 0.015),
    );
    canvas.drawRRect(pencilBody, accentPaint);
    canvas.drawRRect(pencilBody, strokePaint);
    final pencilTip = Path()
      ..moveTo(-size.width * 0.035, 0)
      ..lineTo(0, -size.height * 0.038)
      ..lineTo(0, size.height * 0.038)
      ..close();
    canvas.drawPath(
      pencilTip,
      Paint()..color = const Color(0xFFEFDCC3),
    );
    canvas.drawPath(pencilTip, strokePaint);
    final leadTip = Path()
      ..moveTo(-size.width * 0.045, 0)
      ..lineTo(-size.width * 0.029, -size.height * 0.012)
      ..lineTo(-size.width * 0.029, size.height * 0.012)
      ..close();
    canvas.drawPath(leadTip, fillPaint);
    canvas.restore();

    final aPath = Path()
      ..moveTo(size.width * 0.37, size.height * 0.11)
      ..quadraticBezierTo(
        size.width * 0.41,
        size.height * 0.06,
        size.width * 0.46,
        size.height * 0.1,
      )
      ..lineTo(size.width * 0.62, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.67,
        size.width * 0.73,
        size.height * 0.69,
      )
      ..lineTo(size.width * 0.53, size.height * 0.69)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.69,
        size.width * 0.45,
        size.height * 0.63,
      )
      ..lineTo(size.width * 0.29, size.height * 0.69)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.65,
        size.width * 0.36,
        size.height * 0.58,
      )
      ..close();
    canvas.drawPath(aPath, fillPaint);

    final leftInset = Path()
      ..moveTo(size.width * 0.36, size.height * 0.17)
      ..lineTo(size.width * 0.40, size.height * 0.17)
      ..lineTo(size.width * 0.28, size.height * 0.6)
      ..lineTo(size.width * 0.24, size.height * 0.6)
      ..close();
    canvas.drawPath(leftInset, lightPaint);
    canvas.drawPath(leftInset, strokePaint);

    canvas.drawCircle(
      Offset(size.width * 0.46, size.height * 0.41),
      size.width * 0.065,
      lightPaint,
    );

    for (var i = 0; i < 4; i++) {
      final dx = size.width * (0.52 + (i * 0.03));
      canvas.drawLine(
        Offset(dx, size.height * 0.12),
        Offset(dx + size.width * 0.035, size.height * 0.34),
        Paint()
          ..color = primaryColor
          ..strokeWidth = size.width * 0.008
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(dx + size.width * 0.07, size.height * 0.46),
        Offset(dx + size.width * 0.105, size.height * 0.68),
        Paint()
          ..color = primaryColor
          ..strokeWidth = size.width * 0.008
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.save();
    canvas.translate(size.width * 0.62, size.height * 0.26);
    canvas.rotate(-0.1);
    final eraserRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * 0.07, size.height * 0.16),
      Radius.circular(size.height * 0.02),
    );
    canvas.drawRRect(eraserRect, accentPaint);
    canvas.drawRRect(eraserRect, strokePaint);
    final eraserTop = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * 0.07, size.height * 0.05),
      Radius.circular(size.height * 0.02),
    );
    canvas.drawRRect(eraserTop, eraserPaint);
    canvas.drawLine(
      Offset(0, size.height * 0.055),
      Offset(size.width * 0.07, size.height * 0.055),
      strokePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.012, size.height * 0.025),
      Offset(size.width * 0.058, size.height * 0.025),
      strokePaint,
    );
    canvas.restore();

    final chalkRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.73,
        size.height * 0.595,
        size.width * 0.18,
        size.height * 0.11,
      ),
      Radius.circular(size.height * 0.05),
    );
    canvas.drawRRect(chalkRect, accentPaint);
    canvas.drawRRect(chalkRect, strokePaint);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.65),
      size.width * 0.036,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.65),
      size.width * 0.036,
      strokePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.70, size.height * 0.65),
        radius: size.width * 0.025,
      ),
      -math.pi / 2,
      math.pi,
      false,
      strokePaint,
    );
    for (var i = 1; i <= 2; i++) {
      final x = size.width * (0.78 + (i * 0.05));
      canvas.drawLine(
        Offset(x, size.height * 0.605),
        Offset(x, size.height * 0.695),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AcademyLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.pageColor != pageColor;
  }
}
