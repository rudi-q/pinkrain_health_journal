/// Common data structures and types for wellness charts
import 'package:flutter/material.dart';

/// Data point for mood trends over time
class MoodDataPoint {
  final DateTime date;
  final double mood;
  final String? note;

  const MoodDataPoint({
    required this.date,
    required this.mood,
    this.note,
  });

  /// Convert to map for Cristalyse
  Map<String, dynamic> toChartData(int index) {
    return {
      'x': index.toDouble(),
      'y': mood,
      'date': date,
      'note': note,
    };
  }
}

/// Data point for correlation analysis
class CorrelationDataPoint {
  final String factor;
  final double correlation;
  final String description;

  const CorrelationDataPoint({
    required this.factor,
    required this.correlation,
    required this.description,
  });

  /// Convert to map for Cristalyse
  Map<String, dynamic> toChartData(int index) {
    return {
      'x': index.toDouble(),
      'y': correlation,
      'factor': factor,
      'description': description,
    };
  }
}

/// Data point for prediction charts
class PredictionDataPoint {
  final DateTime date;
  final double predicted;
  final double upperConfidence;
  final double lowerConfidence;
  final bool isHistorical;

  const PredictionDataPoint({
    required this.date,
    required this.predicted,
    required this.upperConfidence,
    required this.lowerConfidence,
    required this.isHistorical,
  });

  /// Convert to map for Cristalyse
  Map<String, dynamic> toChartData(int index) {
    return {
      'x': index.toDouble(),
      'y': predicted,
      'upper': upperConfidence,
      'lower': lowerConfidence,
      'date': date,
      'isHistorical': isHistorical,
    };
  }
}

/// Time range options for charts
enum ChartTimeRange {
  day,
  month,
  year;

  String get displayName {
    switch (this) {
      case ChartTimeRange.day:
        return 'Day';
      case ChartTimeRange.month:
        return 'Month';
      case ChartTimeRange.year:
        return 'Year';
    }
  }
}

/// Chart configuration for consistent styling and behavior
class WellnessChartConfig {
  final String title;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final double height;
  final bool showLegend;
  final bool showGrid;
  final bool enableTooltips;

  const WellnessChartConfig({
    required this.title,
    required this.description,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.purple,
    this.height = 200,
    this.showLegend = true,
    this.showGrid = true,
    this.enableTooltips = true,
  });

  WellnessChartConfig copyWith({
    String? title,
    String? description,
    Color? primaryColor,
    Color? secondaryColor,
    double? height,
    bool? showLegend,
    bool? showGrid,
    bool? enableTooltips,
  }) {
    return WellnessChartConfig(
      title: title ?? this.title,
      description: description ?? this.description,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      height: height ?? this.height,
      showLegend: showLegend ?? this.showLegend,
      showGrid: showGrid ?? this.showGrid,
      enableTooltips: enableTooltips ?? this.enableTooltips,
    );
  }
}

/// Mood scale constants and utilities
class MoodScale {
  static const double minMood = 1.0;
  static const double maxMood = 5.0;
  
  static const Map<int, String> moodLabels = {
    1: 'Very Bad',
    2: 'Bad',
    3: 'Neutral',
    4: 'Good',
    5: 'Great',
  };

  static const Map<int, String> moodEmojis = {
    1: '😢',
    2: '😔',
    3: '😐',
    4: '😊',
    5: '😁',
  };

  static String getMoodLabel(double mood) {
    final roundedMood = mood.round().clamp(1, 5);
    return moodLabels[roundedMood] ?? 'Unknown';
  }

  static String getMoodEmoji(double mood) {
    final roundedMood = mood.round().clamp(1, 5);
    return moodEmojis[roundedMood] ?? '❓';
  }

  static Color getMoodColor(double mood) {
    if (mood <= 2) return Colors.red[300]!;
    if (mood <= 3) return Colors.orange[300]!;
    if (mood <= 4) return Colors.green[300]!;
    return Colors.green[500]!;
  }
}