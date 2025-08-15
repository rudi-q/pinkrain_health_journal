import 'dart:async';

import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/treatment/services/medication_notification_service.dart';

/// Service to handle daily reset operations for the app
/// This follows clean architecture by separating the daily reset logic
/// from the notification service itself
class DailyResetService {
  static final DailyResetService _instance = DailyResetService._internal();
  
  factory DailyResetService() {
    return _instance;
  }
  
  DailyResetService._internal();
  
  Timer? _resetTimer;
  
  /// Initialize the daily reset service
  void initialize() {
    // Schedule the first reset
    _scheduleNextReset();
  }
  
  /// Schedule the next reset at midnight
  void _scheduleNextReset() {
    // Calculate time until midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);
    
    devPrint('🕛 Scheduling daily reset in ${timeUntilMidnight.inHours} hours and ${timeUntilMidnight.inMinutes % 60} minutes');
    
    // Cancel any existing timer
    _resetTimer?.cancel();
    
    // Schedule the reset
    _resetTimer = Timer(timeUntilMidnight, () {
      _performDailyReset();
      
      // Schedule the next reset
      _scheduleNextReset();
    });
  }
  
  /// Perform daily reset operations
  void _performDailyReset() {
    devPrint('🔄 Performing daily reset operations');
    
    // Reset medication notifications
    final medicationNotificationService = MedicationNotificationService();
    medicationNotificationService.resetDailyNotifications();
    
    devPrint('✅ Daily reset completed');
  }
  
  /// Dispose of resources
  void dispose() {
    _resetTimer?.cancel();
  }
}
