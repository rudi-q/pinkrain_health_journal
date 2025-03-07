import 'package:flutter/material.dart';

// Custom painter for scatter plot
class ScatterPlotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pink[100]!
      ..style = PaintingStyle.fill;

    // Draw scatter points
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.7), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.6), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.5), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.3), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.25), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 3, paint);

    // Draw trend line
    final linePaint = Paint()
      ..color = Colors.green[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.1),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}