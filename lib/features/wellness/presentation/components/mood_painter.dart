import 'package:flutter/material.dart';
import 'dart:math' as math;

// Custom painter for mood icons
class MoodPainter extends CustomPainter {
  final int mood;
  final bool isSelected;

  MoodPainter(this.mood, this.isSelected);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSelected
          ? Colors.pink[300]!.withOpacity(0.8)
          : Colors.grey[400]!.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = isSelected
          ? Colors.pink[300]!.withOpacity(0.8)
          : Colors.grey[400]!.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    switch (mood) {
      case 0: // Very sad
        // Sad mouth with deeper curve
        final center = Offset(size.width / 2, size.height / 2 + 8);
        canvas.drawArc(
          Rect.fromCenter(
              center: center, width: size.width - 4, height: size.height - 4),
          0.2, // Slightly offset from PI for a more natural curve
          math.pi * 0.8, // Wider arc for more pronounced sadness
          false,
          paint,
        );

        // Sad eyes (teardrops)
        _drawTeardropEye(canvas,
            Offset(size.width / 2 - 6, size.height / 2 - 8), paint, fillPaint);
        _drawTeardropEye(canvas,
            Offset(size.width / 2 + 6, size.height / 2 - 8), paint, fillPaint);
        break;

      case 1: // Sad
        // Slightly curved down mouth
        final center = Offset(size.width / 2, size.height / 2 + 6);
        canvas.drawArc(
          Rect.fromCenter(
              center: center, width: size.width - 4, height: size.height - 8),
          0.1,
          math.pi * 0.9,
          false,
          paint,
        );

        // Slightly downturned eyes
        _drawDownturnedEye(
            canvas, Offset(size.width / 2 - 6, size.height / 2 - 8), paint);
        _drawDownturnedEye(
            canvas, Offset(size.width / 2 + 6, size.height / 2 - 8), paint);
        break;

      case 2: // Neutral
        // Straight mouth with slightly curved ends
        final mouthY = size.height / 2 + 4;
        canvas.drawLine(
          Offset(size.width / 2 - 8, mouthY),
          Offset(size.width / 2 + 8, mouthY),
          paint,
        );

        // Neutral eyes
        _drawNeutralEye(canvas, Offset(size.width / 2 - 6, size.height / 2 - 8),
            paint, fillPaint);
        _drawNeutralEye(canvas, Offset(size.width / 2 + 6, size.height / 2 - 8),
            paint, fillPaint);
        break;

      case 3: // Happy
        // Upward curved mouth
        final center = Offset(size.width / 2, size.height / 2 - 2);
        canvas.drawArc(
          Rect.fromCenter(
              center: center, width: size.width - 4, height: size.height - 8),
          0,
          math.pi,
          false,
          paint,
        );

        // Happy eyes (curved upward)
        _drawHappyEye(
            canvas, Offset(size.width / 2 - 6, size.height / 2 - 8), paint);
        _drawHappyEye(
            canvas, Offset(size.width / 2 + 6, size.height / 2 - 8), paint);
        break;

      case 4: // Very happy
        // Wide smile with cheeks
        final center = Offset(size.width / 2, size.height / 2 - 4);
        canvas.drawArc(
          Rect.fromCenter(
              center: center, width: size.width - 2, height: size.height - 6),
          0,
          math.pi,
          false,
          paint,
        );

        // Very happy eyes (curved upward with rosy cheeks)
        _drawVeryHappyEye(
            canvas, Offset(size.width / 2 - 6, size.height / 2 - 8), paint);
        _drawVeryHappyEye(
            canvas, Offset(size.width / 2 + 6, size.height / 2 - 8), paint);

        // Add rosy cheeks
        if (isSelected) {
          final cheekPaint = Paint()
            ..color = Colors.pink[100]!.withOpacity(0.6)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(
              Offset(size.width / 2 - 8, size.height / 2), 2, cheekPaint);
          canvas.drawCircle(
              Offset(size.width / 2 + 8, size.height / 2), 2, cheekPaint);
        }
        break;
    }
  }

  void _drawTeardropEye(
      Canvas canvas, Offset center, Paint paint, Paint fillPaint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - 2)
      ..lineTo(center.dx - 1.5, center.dy + 2)
      ..lineTo(center.dx + 1.5, center.dy + 2)
      ..close();
    canvas.drawPath(path, fillPaint);
  }

  void _drawDownturnedEye(Canvas canvas, Offset center, Paint paint) {
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 6, height: 6),
      math.pi * 0.8,
      math.pi * 0.4,
      false,
      paint,
    );
  }

  void _drawNeutralEye(
      Canvas canvas, Offset center, Paint paint, Paint fillPaint) {
    canvas.drawCircle(center, 1.5, fillPaint);
  }

  void _drawHappyEye(Canvas canvas, Offset center, Paint paint) {
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 6, height: 6),
      math.pi * 0.1,
      math.pi * 0.8,
      false,
      paint,
    );
  }

  void _drawVeryHappyEye(Canvas canvas, Offset center, Paint paint) {
    // Curved line for happy eyes
    final path = Path()
      ..moveTo(center.dx - 3, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - 4, center.dx + 3, center.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
