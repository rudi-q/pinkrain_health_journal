/// Reusable tooltip, hover, and click handlers for wellness charts
import 'package:flutter/material.dart';
import 'package:cristalyse/cristalyse.dart';
import 'chart_data_models.dart';

/// Centralized interactions for wellness charts
class WellnessChartInteractions {
  /// Tooltip configuration for mood trend charts
  static TooltipConfig moodTrendTooltip(ChartTimeRange timeRange) {
    return TooltipConfig(
      builder: (point) => _MoodTrendTooltip(
        point: point,
        timeRange: timeRange,
      ),
      showDelay: const Duration(milliseconds: 100),
      hideDelay: const Duration(milliseconds: 300),
    );
  }

  /// Tooltip configuration for correlation analysis charts
  static TooltipConfig correlationTooltip() {
    return TooltipConfig(
      builder: (point) => _CorrelationTooltip(point: point),
      showDelay: const Duration(milliseconds: 100),
      hideDelay: const Duration(milliseconds: 300),
    );
  }

  /// Tooltip configuration for prediction charts
  static TooltipConfig predictionTooltip() {
    return TooltipConfig(
      builder: (point) => _PredictionTooltip(point: point),
      showDelay: const Duration(milliseconds: 100),
      hideDelay: const Duration(milliseconds: 300),
    );
  }

  /// Hover configuration for highlighting data points
  static HoverConfig standardHover() {
    return HoverConfig(
      onHover: (point) => _highlightPoint(point),
      onExit: (point) => _unhighlightPoint(point),
      hitTestRadius: 12.0,
    );
  }

  /// Click configuration for mood data points
  static ClickConfig moodDataClick(Function(dynamic)? onTap) {
    return ClickConfig(
      onTap: onTap ?? _defaultMoodTap,
      hitTestRadius: 15.0,
    );
  }

  /// Click configuration for correlation data points
  static ClickConfig correlationDataClick(Function(dynamic)? onTap) {
    return ClickConfig(
      onTap: onTap ?? _defaultCorrelationTap,
      hitTestRadius: 15.0,
    );
  }

  // Private helper methods
  static void _highlightPoint(dynamic point) {
    // Implementation for highlighting points on hover
    // This would be used to change visual state
  }

  static void _unhighlightPoint(dynamic point) {
    // Implementation for removing highlight
  }

  static void _defaultMoodTap(dynamic point) {
    // Default action for mood data point tap
    debugPrint('Mood point tapped: ${point.getDisplayValue('y')}');
  }

  static void _defaultCorrelationTap(dynamic point) {
    // Default action for correlation data point tap
    debugPrint('Correlation point tapped: ${point.getDisplayValue('factor')}');
  }
}

/// Custom tooltip widget for mood trend data
class _MoodTrendTooltip extends StatelessWidget {
  final dynamic point;
  final ChartTimeRange timeRange;

  const _MoodTrendTooltip({
    required this.point,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    final moodValue = point.getDisplayValue('y') as double;
    final date = point.getDisplayValue('date') as DateTime?;
    final note = point.getDisplayValue('note') as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(date, timeRange),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                MoodScale.getMoodEmoji(moodValue),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                MoodScale.getMoodLabel(moodValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date, ChartTimeRange timeRange) {
    if (date == null) return 'Unknown date';
    
    switch (timeRange) {
      case ChartTimeRange.day:
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      case ChartTimeRange.month:
        return '${date.day}/${date.month}';
      case ChartTimeRange.year:
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[date.month - 1];
    }
  }
}

/// Custom tooltip widget for correlation analysis data
class _CorrelationTooltip extends StatelessWidget {
  final dynamic point;

  const _CorrelationTooltip({required this.point});

  @override
  Widget build(BuildContext context) {
    final factor = point.getDisplayValue('factor') as String? ?? 'Unknown';
    final correlation = point.getDisplayValue('y') as double;
    final description = point.getDisplayValue('description') as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: Colors.grey[100]!,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            factor,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(correlation * 100).toStringAsFixed(0)}% correlation',
            style: TextStyle(
              color: correlation >= 0 ? Colors.green[600] : Colors.red[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom tooltip widget for prediction data
class _PredictionTooltip extends StatelessWidget {
  final dynamic point;

  const _PredictionTooltip({required this.point});

  @override
  Widget build(BuildContext context) {
    final predicted = point.getDisplayValue('y') as double;
    final upper = point.getDisplayValue('upper') as double?;
    final lower = point.getDisplayValue('lower') as double?;
    final date = point.getDisplayValue('date') as DateTime?;
    final isHistorical = point.getDisplayValue('isHistorical') as bool? ?? true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date != null ? '${date.day}/${date.month}' : 'Unknown date',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHistorical ? Icons.history : Icons.trending_up,
                color: isHistorical ? Colors.blue[300] : Colors.purple[300],
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isHistorical ? 'Historical' : 'Predicted',
                style: TextStyle(
                  color: isHistorical ? Colors.blue[300] : Colors.purple[300],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            MoodScale.getMoodLabel(predicted),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isHistorical && upper != null && lower != null) ...[
            const SizedBox(height: 4),
            Text(
              'Range: ${MoodScale.getMoodLabel(lower)} - ${MoodScale.getMoodLabel(upper)}',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Helper class for common interaction patterns
class InteractionHelpers {
  /// Format time labels based on time range
  static String formatTimeLabel(double value, ChartTimeRange timeRange) {
    switch (timeRange) {
      case ChartTimeRange.day:
        final hour = value.toInt();
        if (hour == 0) return '12 AM';
        if (hour == 12) return '12 PM';
        if (hour < 12) return '$hour AM';
        return '${hour - 12} PM';
        
      case ChartTimeRange.month:
        return '${value.toInt() + 1}';
        
      case ChartTimeRange.year:
        final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
        return months[value.toInt().clamp(0, 11)];
    }
  }

  /// Format correlation labels
  static String formatCorrelationLabel(double value) {
    if (value == 1) return '+100%';
    if (value == 0.5) return '+50%';
    if (value == 0) return '0%';
    if (value == -0.5) return '-50%';
    if (value == -1) return '-100%';
    return '';
  }
}