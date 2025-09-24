/// Reusable theme configurations for wellness charts with Cristalyse
import 'package:flutter/material.dart';
import 'package:cristalyse/cristalyse.dart';

/// Chart themes for consistent wellness app styling
class WellnessChartThemes {
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color secondaryPurple = Color(0xFF8E44AD);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color warningOrange = Color(0xFFE67E22);
  static const Color dangerRed = Color(0xFFE74C3C);
  static const Color neutralGray = Color(0xFF95A5A6);

  /// Default theme for mood trend charts
  static ChartTheme get moodTrend {
    return ChartTheme.defaultTheme().copyWith(
      backgroundColor: Colors.white,
      gridColor: Colors.grey[200]!,
      primaryColor: primaryBlue,
      colorPalette: [primaryBlue, secondaryPurple, accentGreen, warningOrange, dangerRed],
      axisTextStyle: TextStyle(color: Colors.grey[600]!, fontSize: 12),
      padding: const EdgeInsets.all(16),
      plotBackgroundColor: Colors.white,
      borderColor: Colors.transparent,
      axisColor: Colors.grey[300]!,
      axisWidth: 1.0,
      gridWidth: 1.0,
      pointSizeDefault: 6.0,
      pointSizeMin: 2.0,
      pointSizeMax: 12.0,
    );
  }

  /// Theme for correlation analysis charts
  static ChartTheme get correlation {
    return ChartTheme.defaultTheme().copyWith(
      backgroundColor: Colors.white,
      gridColor: Colors.grey[200]!,
      primaryColor: accentGreen,
      colorPalette: [accentGreen, dangerRed, neutralGray, primaryBlue],
      axisTextStyle: TextStyle(color: Colors.grey[600]!, fontSize: 12),
      padding: const EdgeInsets.all(16),
      plotBackgroundColor: Colors.white,
      borderColor: Colors.transparent,
      axisColor: Colors.grey[300]!,
      axisWidth: 1.0,
      gridWidth: 1.0,
      pointSizeDefault: 6.0,
      pointSizeMin: 2.0,
      pointSizeMax: 12.0,
    );
  }

  /// Theme for prediction charts with confidence intervals
  static ChartTheme get prediction {
    return ChartTheme.defaultTheme().copyWith(
      backgroundColor: Colors.white,
      gridColor: Colors.grey[200]!,
      primaryColor: primaryBlue,
      colorPalette: [primaryBlue, Color(0xFF9B59B6), secondaryPurple, neutralGray],
      axisTextStyle: TextStyle(color: Colors.grey[600]!, fontSize: 12),
      padding: const EdgeInsets.all(16),
      plotBackgroundColor: Colors.white,
      borderColor: Colors.transparent,
      axisColor: Colors.grey[300]!,
      axisWidth: 1.0,
      gridWidth: 1.0,
      pointSizeDefault: 6.0,
      pointSizeMin: 2.0,
      pointSizeMax: 12.0,
    );
  }

  /// Dark theme variant for mood trends
  static ChartTheme get moodTrendDark {
    return ChartTheme.darkTheme().copyWith(
      backgroundColor: Color(0xFF2C3E50),
      gridColor: Color(0xFF34495E),
      primaryColor: Color(0xFF5DADE2),
      colorPalette: [Color(0xFF5DADE2), Color(0xFFAB7BE8), accentGreen, warningOrange],
      axisTextStyle: TextStyle(color: Colors.grey[300]!, fontSize: 12),
    );
  }

  /// Get gradient colors for positive correlations
  static List<Color> get positiveGradient => [
    accentGreen.withValues(alpha: 0.3),
    accentGreen.withValues(alpha: 0.8),
  ];

  /// Get gradient colors for negative correlations
  static List<Color> get negativeGradient => [
    dangerRed.withValues(alpha: 0.3),
    dangerRed.withValues(alpha: 0.8),
  ];

  /// Get gradient colors for mood trends
  static List<Color> get moodGradient => [
    primaryBlue.withValues(alpha: 0.3),
    primaryBlue.withValues(alpha: 0.8),
  ];

  /// Get gradient colors for prediction confidence intervals
  static List<Color> get confidenceGradient => [
    secondaryPurple.withValues(alpha: 0.1),
    secondaryPurple.withValues(alpha: 0.3),
  ];
}

/// Extension to provide commonly used styling patterns
extension ChartStyling on WellnessChartThemes {
  /// Standard container decoration for chart widgets
  static BoxDecoration get chartContainer => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withValues(alpha: 0.1),
        spreadRadius: 1,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Standard padding for chart containers
  static const EdgeInsets chartPadding = EdgeInsets.all(16);

  /// Standard spacing between chart elements
  static const double standardSpacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 24.0;

  /// Standard text styles for chart titles
  static const TextStyle chartTitle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.black87,
  );

  /// Standard text styles for chart descriptions
  static TextStyle get chartDescription => TextStyle(
    color: Colors.grey[600],
    fontSize: 12,
    height: 1.3,
  );

  /// Standard text styles for chart legends
  static TextStyle get legendText => TextStyle(
    color: Colors.grey[600],
    fontSize: 12,
  );

  /// Standard text styles for small labels
  static TextStyle get smallLabel => TextStyle(
    color: Colors.grey[600],
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}

/// Predefined color schemes for different chart types
class WellnessColorSchemes {
  /// Color scheme for mood levels (1-5 scale)
  static const List<Color> moodColors = [
    Color(0xFFE74C3C), // Very Bad - Red
    Color(0xFFE67E22), // Bad - Orange  
    Color(0xFFF39C12), // Neutral - Yellow
    Color(0xFF27AE60), // Good - Green
    Color(0xFF2ECC71), // Great - Bright Green
  ];

  /// Color scheme for correlation analysis
  static const List<Color> correlationColors = [
    Color(0xFFE74C3C), // Strong negative
    Color(0xFFE67E22), // Moderate negative
    Color(0xFF95A5A6), // Neutral
    Color(0xFF27AE60), // Moderate positive
    Color(0xFF2ECC71), // Strong positive
  ];

  /// Color scheme for time-based data
  static const List<Color> timeSeriesColors = [
    Color(0xFF3498DB), // Primary blue
    Color(0xFF9B59B6), // Purple
    Color(0xFF1ABC9C), // Teal
    Color(0xFFE67E22), // Orange
    Color(0xFFE74C3C), // Red
  ];

  /// Get color based on mood value (1-5 scale)
  static Color getMoodColor(double mood) {
    final index = (mood - 1).clamp(0, 4).round();
    return moodColors[index];
  }

  /// Get color based on correlation strength (-1 to 1)
  static Color getCorrelationColor(double correlation) {
    final normalized = ((correlation + 1) / 2 * 4).clamp(0, 4).round();
    return correlationColors[normalized];
  }
}