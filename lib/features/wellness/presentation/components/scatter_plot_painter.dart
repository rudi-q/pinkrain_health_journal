import 'package:flutter/material.dart';

class ScatterPlotPainter extends CustomPainter {
  final List<Map<String, dynamic>> correlationData;
  
  ScatterPlotPainter({
    required this.correlationData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (correlationData.isEmpty) return;

    // Add padding to keep points away from edges
    final padding = 8.0;
    final plotWidth = size.width - (padding * 2);
    final plotHeight = size.height - (padding * 2);

    final pointPaint = Paint()
      ..color = Colors.pink[400]!
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.green[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Calculate min/max values for scaling
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var point in correlationData) {
      final x = (point['x'] as num).toDouble();
      final y = (point['y'] as num).toDouble();
      
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // Handle edge case: all points have same x or y value
    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    
    // If all points are the same, just draw them in the center
    if (rangeX == 0 && rangeY == 0) {
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      canvas.drawCircle(Offset(centerX, centerY), 5, pointPaint);
      return;
    }

    // Draw scatter points
    for (var point in correlationData) {
      final x = (point['x'] as num).toDouble();
      final y = (point['y'] as num).toDouble();

      // Scale the points to fit the canvas with padding
      final scaledX = rangeX > 0 
          ? padding + plotWidth * ((x - minX) / rangeX)
          : size.width / 2;
      final scaledY = rangeY > 0 
          ? padding + plotHeight * (1 - ((y - minY) / rangeY))
          : size.height / 2;

      canvas.drawCircle(Offset(scaledX, scaledY), 4, pointPaint);
    }

    // Calculate and draw trend line using linear regression
    if (correlationData.length > 1 && rangeX > 0) {
      double sumX = 0;
      double sumY = 0;
      double sumXY = 0;
      double sumX2 = 0;
      int n = correlationData.length;

      for (var point in correlationData) {
        final x = (point['x'] as num).toDouble();
        final y = (point['y'] as num).toDouble();
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
      }

      final denominator = n * sumX2 - sumX * sumX;
      if (denominator.abs() > 0.0001) { // Avoid division by zero
        final slope = (n * sumXY - sumX * sumY) / denominator;
        final intercept = (sumY - slope * sumX) / n;

        // Draw trend line
        final startY = slope * minX + intercept;
        final endY = slope * maxX + intercept;

        // Scale trend line points
        final scaledStartX = padding;
        final scaledStartY = rangeY > 0 
            ? padding + plotHeight * (1 - ((startY - minY) / rangeY))
            : size.height / 2;
        final scaledEndX = padding + plotWidth;
        final scaledEndY = rangeY > 0 
            ? padding + plotHeight * (1 - ((endY - minY) / rangeY))
            : size.height / 2;

        // Clamp line to visible area
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.drawLine(
          Offset(scaledStartX, scaledStartY.clamp(0, size.height)),
          Offset(scaledEndX, scaledEndY.clamp(0, size.height)),
          linePaint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}