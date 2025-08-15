import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:pillow/core/util/helpers.dart';

/// Service responsible for handling medication actions (take, snooze, etc.)
/// This follows clean architecture by separating action handling from notifications
class MedicationActionService {
  static final MedicationActionService _instance = MedicationActionService._internal();
  
  factory MedicationActionService() {
    return _instance;
  }
  
  MedicationActionService._internal();
  
  static const String _boxName = 'medication_actions';
  static const String _medicationStatusKey = 'medication_status';
  
  /// Initialize the service
  Future<void> initialize() async {
    // Open Hive box for persistent storage
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    
    devPrint('MedicationActionService initialized');
  }
  
  /// Handle a medication being marked as taken
  /// This updates the medication status in the database
  Future<bool> markMedicationAsTaken(String medicationId, {Map<String, dynamic>? metadata}) async {
    try {
      final box = await Hive.openBox(_boxName);
      
      // Get current medication status
      final statusMap = _getMedicationStatus(box);
      
      // Update the status for this medication
      statusMap[medicationId] = {
        'status': 'taken',
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
      };
      
      // Save updated status
      await box.put(_medicationStatusKey, statusMap);
      
      // Notify listeners if this was successful
      // In a real implementation, this would update UI components
      
      devPrint('✅ Medication $medicationId marked as taken');
      return true;
    } catch (e) {
      devPrint('❌ Error marking medication as taken: $e');
      return false;
    }
  }
  
  /// Handle a medication being snoozed
  /// Returns true if successfully snoozed
  Future<bool> snoozeMedication(String medicationId, {
    int snoozeMinutes = 5,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final box = await Hive.openBox(_boxName);
      
      // Get current medication status
      final statusMap = _getMedicationStatus(box);
      
      // Calculate snooze time
      final snoozeUntil = DateTime.now().add(Duration(minutes: snoozeMinutes));
      
      // Update the status for this medication
      statusMap[medicationId] = {
        'status': 'snoozed',
        'timestamp': DateTime.now().toIso8601String(),
        'snoozeUntil': snoozeUntil.toIso8601String(),
        'metadata': metadata ?? {},
      };
      
      // Save updated status
      await box.put(_medicationStatusKey, statusMap);
      
      devPrint('✅ Medication $medicationId snoozed until $snoozeUntil');
      return true;
    } catch (e) {
      devPrint('❌ Error snoozing medication: $e');
      return false;
    }
  }
  
  /// Get medication status from Hive
  Map<String, dynamic> _getMedicationStatus(Box box) {
    final data = box.get(_medicationStatusKey);
    
    if (data == null) {
      return {};
    }
    
    try {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      } else if (data is String) {
        return json.decode(data);
      }
    } catch (e) {
      devPrint('Error parsing medication status: $e');
    }
    
    return {};
  }
  
  /// Check if a medication has been taken
  Future<bool> isMedicationTaken(String medicationId) async {
    try {
      final box = await Hive.openBox(_boxName);
      final statusMap = _getMedicationStatus(box);
      
      if (statusMap.containsKey(medicationId)) {
        final status = statusMap[medicationId];
        return status['status'] == 'taken';
      }
      
      return false;
    } catch (e) {
      devPrint('Error checking medication status: $e');
      return false;
    }
  }
  
  /// Get the status of a specific medication (for testing purposes)
  Future<Map<String, dynamic>> getMedicationStatus(String medicationId) async {
    try {
      final box = await Hive.openBox(_boxName);
      final statusMap = _getMedicationStatus(box);
      
      if (statusMap.containsKey(medicationId)) {
        return Map<String, dynamic>.from(statusMap[medicationId]);
      }
      
      return {};
    } catch (e) {
      devPrint('Error getting medication status: $e');
      return {};
    }
  }
}
