import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinkrain/core/util/helpers.dart';

/// A global navigator key that can be used to navigate from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Store pending navigation requests that couldn't be processed immediately
final List<_PendingNavigation> _pendingNavigations = [];

/// A class to store pending navigation requests
class _PendingNavigation {
  final String medicationId;
  final DateTime timestamp;

  _PendingNavigation(this.medicationId) : timestamp = DateTime.now();
}

/// A helper class to handle navigation from outside the widget context
class NavigationHelper {
  /// Navigate to the journal screen and show medication details for a specific medication
  static void navigateToJournalAndShowMedication(String medicationId) {
    if (navigatorKey.currentContext == null) {
      devPrint('❌ Cannot navigate: no context available, storing for later');
      
      // Store the navigation request for later processing
      _pendingNavigations.add(_PendingNavigation(medicationId));
      
      // Schedule a check to see if the context becomes available
      _scheduleNavigationRetry();
      return;
    }

    // Navigate to the journal screen with the medication ID as a query parameter
    GoRouter.of(navigatorKey.currentContext!).go('/journal?medicationId=$medicationId');
    devPrint('✅ Navigated to journal screen with medication ID: $medicationId');
  }
  
  /// Schedule a retry for pending navigations
  static void _scheduleNavigationRetry() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _processPendingNavigations();
    });
  }
  
  /// Process any pending navigation requests
  static void _processPendingNavigations() {
    if (_pendingNavigations.isEmpty) return;
    
    if (navigatorKey.currentContext != null) {
      final pending = _pendingNavigations.removeAt(0);
      devPrint('🔄 Processing pending navigation for medication ID: ${pending.medicationId}');
      
      // Navigate to the journal screen with the medication ID
      GoRouter.of(navigatorKey.currentContext!).go('/journal?medicationId=${pending.medicationId}');
    } else {
      // Context still not available, schedule another retry
      _scheduleNavigationRetry();
    }
  }
  
  /// Check for pending navigations (call this when the app is fully initialized)
  static void checkPendingNavigations() {
    _processPendingNavigations();
  }
}

/// A global function that can be called from anywhere to navigate to the journal screen
void navigateToJournalAndShowMedication(String medicationId) {
  NavigationHelper.navigateToJournalAndShowMedication(medicationId);
}
