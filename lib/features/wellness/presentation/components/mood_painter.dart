import 'package:flutter/material.dart';

// Custom painter for mood icons
class MoodPainter extends CustomPainter {
  final int mood;
  final bool isSelected;

  MoodPainter(this.mood, this.isSelected);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSelected ? Colors.white : Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (mood) {
      case 0: // Very sad
        final center = Offset(size.width / 2, size.height / 2 + 5);
        canvas.drawArc(
          Rect.fromCenter(center: center, width: size.width, height: size.height),
          3.14, // PI (180 degrees, making it upside down)
          3.14, // PI (180 degrees arc)
          false,
          paint,
        );
        // Eyes
        canvas.drawCircle(Offset(size.width / 2 - 8, size.height / 2 - 10), 1, paint);
        canvas.drawCircle(Offset(size.width / 2 + 8, size.height / 2 - 10), 1, paint);
        break;
      case 1: // Sad
        final center = Offset(size.width / 2, size.height + 5);
        canvas.drawArc(
          Rect.fromCenter(center: center, width: size.width, height: size.height),
          3.14, // PI (180 degrees, making it upside down)
          3.14, // PI (180 degrees arc)
          false,
          paint,
        );
        // Eyes
        canvas.drawLine(
          Offset(size.width / 2 - 8, size.height / 2 - 10),
          Offset(size.width / 2 - 3, size.height / 2 - 10),
          paint,
        );
        canvas.drawLine(
          Offset(size.width / 2 + 3, size.height / 2 - 10),
          Offset(size.width / 2 + 8, size.height / 2 - 10),
          paint,
        );
        break;
      case 2: // Neutral
      // Mouth - straight line
        canvas.drawLine(
          Offset(size.width / 2 - 10, size.height / 2 + 10),
          Offset(size.width / 2 + 10, size.height / 2 + 10),
          paint,
        );
        // Eyes
        canvas.drawLine(
          Offset(size.width / 2 - 8, size.height / 2 - 10),
          Offset(size.width / 2 - 3, size.height / 2 - 10),
          paint,
        );
        canvas.drawLine(
          Offset(size.width / 2 + 3, size.height / 2 - 10),
          Offset(size.width / 2 + 8, size.height / 2 - 10),
          paint,
        );
        break;
      case 3: // Happy
        final center = Offset(size.width / 2, size.height / 2 + 5);
        canvas.drawArc(
          Rect.fromCenter(center: center, width: size.width, height: size.height),
          0, // 0 degrees (starting from the right)
          3.14, // PI (180 degrees arc)
          false,
          paint,
        );
        // Eyes
        canvas.drawCircle(Offset(size.width / 2 - 8, size.height / 2 - 10), 1, paint);
        canvas.drawCircle(Offset(size.width / 2 + 8, size.height / 2 - 10), 1, paint);
        break;
      case 4: // Very happy
        final center = Offset(size.width / 2, size.height / 2);
        canvas.drawArc(
          Rect.fromCenter(center: center, width: size.width, height: size.height - 5),
          0, // 0 degrees (starting from the right)
          3.14, // PI (180 degrees arc)
          false,
          paint,
        );
        // Eyes
        canvas.drawCircle(Offset(size.width / 2 - 8, size.height / 2 - 14), 1, paint);
        canvas.drawCircle(Offset(size.width / 2 + 8, size.height / 2 - 14), 1, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}