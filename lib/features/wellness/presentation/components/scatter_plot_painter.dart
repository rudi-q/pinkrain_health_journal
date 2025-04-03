import 'package:flutter/material.dart';

class ScatterPlotPainter extends CustomPainter {
  final List<Map<String, dynamic>> correlationData;
  
  ScatterPlotPainter({
    required this.correlationData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (correlationData.isEmpty) return;

    final paint = Paint()
      ..color = Colors.pink[100]!
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.green[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Calculate min/max values for scaling
    double minX = 100.0;
    double maxX = 0.0;
    double minY = 5.0;
    double maxY = 1.0;

    for (var point in correlationData) {
      final x = point['x'] as double;
      final y = point['y'] as double;
      
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // Draw scatter points
    for (var point in correlationData) {
      final x = point['x'] as double;
      final y = point['y'] as double;

      // Scale the points to fit the canvas
      final scaledX = size.width * ((x - minX) / (maxX - minX));
      final scaledY = size.height * (1 - ((y - minY) / (maxY - minY)));

      canvas.drawCircle(Offset(scaledX, scaledY), 3, paint);
    }

    // Calculate and draw trend line using linear regression
    if (correlationData.length > 1) {
      double sumX = 0;
      double sumY = 0;
      double sumXY = 0;
      double sumX2 = 0;
      int n = correlationData.length;

      for (var point in correlationData) {
        final x = point['x'] as double;
        final y = point['y'] as double;
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
      }

      final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      final intercept = (sumY - slope * sumX) / n;

      // Draw trend line
      final startX = minX;
      final endX = maxX;
      final startY = slope * startX + intercept;
      final endY = slope * endX + intercept;

      // Scale trend line points
      final scaledStartX = size.width * ((startX - minX) / (maxX - minX));
      final scaledStartY = size.height * (1 - ((startY - minY) / (maxY - minY)));
      final scaledEndX = size.width * ((endX - minX) / (maxX - minX));
      final scaledEndY = size.height * (1 - ((endY - minY) / (maxY - minY)));

      canvas.drawLine(
        Offset(scaledStartX, scaledStartY),
        Offset(scaledEndX, scaledEndY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}