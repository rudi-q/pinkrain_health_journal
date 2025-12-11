import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/util/helpers.dart';

import '../../../core/models/medicine_model.dart';
import '../../treatment/data/treatment.dart';
import '../../treatment/domain/treatment_manager.dart';

class IntakeLog {
  final Treatment treatment;
  final DateTime? doseTime; // Specific dose time for this log entry (null for legacy single-dose treatments)
  bool isTaken;
  bool isSkipped;

  IntakeLog(this.treatment, {this.doseTime, this.isTaken = false, this.isSkipped = false});

  /// Convert IntakeLog to a Map for storage
  Map<String, dynamic> toMap() {
    // Debug the ID being stored
    final treatmentId = treatment.id;
    if (treatmentId.isEmpty) {
      devPrint(
          "WARNING: Empty treatment ID in toMap for ${treatment.medicine.name}");
    }

    return {
      'treatment_id': treatmentId,
      'medicine_name': treatment.medicine.name,
      'medicine_type': treatment.medicine.type,
      'medicine_color': treatment.medicine.color,
      'dosage': treatment.medicine.specs.dosage,
      'unit': treatment.medicine.specs.unit,
      'treatment_plan_start_date':
          treatment.treatmentPlan.startDate.toIso8601String(),
      'treatment_plan_end_date':
          treatment.treatmentPlan.endDate.toIso8601String(),
      'dose_time': doseTime?.toIso8601String(), // Store specific dose time
      'is_taken': isTaken,
      'is_skipped': isSkipped,
    };
  }

  /// Create IntakeLog from a Map
  static IntakeLog fromMap(Map<String, dynamic> map) {
    try {
      // Extract fields with safe defaults
      final dynamic nameValue = map['medicine_name'];
      final dynamic typeValue = map['medicine_type'];
      final dynamic colorValue = map['medicine_color'];
      final dynamic dosageValue = map['dosage'];
      final dynamic unitValue = map['unit'];
      final dynamic isTakenValue = map['is_taken'];
      final dynamic isSkippedValue = map['is_skipped'];
      final dynamic startDateValue = map['treatment_plan_start_date'];
      final dynamic endDateValue = map['treatment_plan_end_date'];
      final dynamic treatmentIdValue = map['treatment_id'];
      final dynamic doseTimeValue = map['dose_time'];

      // Get treatment ID safely
      final String treatmentId =
          (treatmentIdValue is String) ? treatmentIdValue : '';
      if (treatmentId.isEmpty) {
        devPrint("WARNING: Empty treatment ID in fromMap for $nameValue");
      }
      
      // Parse dose time if available
      DateTime? doseTime;
      if (doseTimeValue != null && doseTimeValue is String) {
        try {
          doseTime = DateTime.parse(doseTimeValue);
        } catch (e) {
          doseTime = null;
        }
      }

      // Convert name, type, and color with safe defaults
      final String name =
          (nameValue is String) ? nameValue : 'Unknown Medicine';
      final String type = (typeValue is String) ? typeValue : 'pill';
      final String color = (colorValue is String) ? colorValue : 'white';

      // Convert dosage with safe default
      double dosage = 1.0;
      if (dosageValue != null) {
        if (dosageValue is int) {
          dosage = dosageValue.toDouble();
        } else if (dosageValue is double) {
          dosage = dosageValue;
        } else if (dosageValue is String) {
          try {
            dosage = double.parse(dosageValue);
          } catch (e) {
            // Keep default
          }
        }
      }

      // Convert unit with safe default
      final String unit = (unitValue is String) ? unitValue : 'mg';

      // Convert taken status with safe default
      bool isTaken = false;
      if (isTakenValue != null) {
        if (isTakenValue is bool) {
          isTaken = isTakenValue;
        } else if (isTakenValue is int) {
          isTaken = isTakenValue != 0;
        } else if (isTakenValue is String) {
          isTaken = isTakenValue.toLowerCase() == 'true' || isTakenValue == '1';
        }
      }

      // Convert skipped status with safe default
      bool isSkipped = false;
      if (isSkippedValue != null) {
        if (isSkippedValue is bool) {
          isSkipped = isSkippedValue;
        } else if (isSkippedValue is int) {
          isSkipped = isSkippedValue != 0;
        } else if (isSkippedValue is String) {
          isSkipped =
              isSkippedValue.toLowerCase() == 'true' || isSkippedValue == '1';
        }
      }

      // Enforce exclusivity: isTaken and isSkipped cannot both be true
      if (isTaken && isSkipped) {
        // If both are true, prioritize isTaken and set isSkipped to false
        isSkipped = false;
      }

      DateTime startDate = DateTime.now();
      try {
        if (startDateValue is String) {
          startDate = DateTime.parse(startDateValue);
        }
      } catch (e) {
        // Default logic
      }

      DateTime endDate = startDate.add(const Duration(days: 7));
      try {
        if (endDateValue is String) {
          endDate = DateTime.parse(endDateValue);
        }
      } catch (e) {
        // Default logic
      }

      // Create a medicine object
      final medicine = Medicine(
        name: name,
        type: type,
        color: color,
      );

      // Add specification
      medicine.addSpecification(
        Specification(
          dosage: dosage,
          unit: unit,
          useCase: '',
        ),
      );

      // Create treatment plan
      final treatmentPlan = TreatmentPlan(
        startDate: startDate,
        endDate: endDate,
        mealOption: 'No preference',
        instructions: '',
        frequency: const Duration(days: 1),
        timeOfDay: createTimeOfDay(12, 0),
      );

      // Create the treatment with the explicit ID
      final treatment = Treatment(
          id: treatmentId, medicine: medicine, treatmentPlan: treatmentPlan);

      // Log the ID we're using
      devPrint("Created treatment from map with ID: '$treatmentId'");

      return IntakeLog(treatment, doseTime: doseTime, isTaken: isTaken, isSkipped: isSkipped);
    } catch (e) {
      devPrint('Error in IntakeLog.fromMap: $e');
      // Create a fallback log entry
      final medicine = Medicine(
          name: 'Error Loading', type: 'pill', color: 'red')
        ..addSpecification(Specification(dosage: 0.0, unit: 'mg', useCase: ''));

      final plan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        timeOfDay: createTimeOfDay(12, 0),
      );

      final treatment = Treatment(medicine: medicine, treatmentPlan: plan);
      return IntakeLog(treatment);
    }
  }
}

class JournalLog {
  final Map<DateTime, List<IntakeLog>> medicationLogs = {};

  // Constructor with no initialization as the map is already created as a final field
  // Data will be loaded when getMedicationsForTheDay is called
  JournalLog();

  /// Deduplicate logs by (treatment_id, dose_time), preferring logs with
  /// taken/skipped status over unknown status.
  /// Returns the deduplicated list.
  List<IntakeLog> _deduplicateLogs(List<IntakeLog> logs) {
    final Map<String, IntakeLog> uniqueLogs = {};
    for (final log in logs) {
      // Create a unique key from treatment ID and dose time
      String key;
      if (log.doseTime != null) {
        final hour = log.doseTime!.hour;
        final minute = log.doseTime!.minute;
        key = '${log.treatment.id}_$hour:$minute';
      } else {
        key = '${log.treatment.id}_default';
      }
      
      // Keep the log with the most information (taken or skipped status)
      if (!uniqueLogs.containsKey(key)) {
        uniqueLogs[key] = log;
      } else {
        final existing = uniqueLogs[key]!;
        // Prefer taken/skipped over unknown
        if ((log.isTaken || log.isSkipped) && !existing.isTaken && !existing.isSkipped) {
          uniqueLogs[key] = log;
        }
      }
    }
    return uniqueLogs.values.toList();
  }

  /// Load medication logs from Hive storage
  Future<void> _loadMedicationLogs(DateTime date) async {
    date = date.normalize();
    
    // Load treatments once at the beginning to avoid redundant I/O
    final treatmentManager = TreatmentManager();
    await treatmentManager.loadTreatments(); // Ensure latest treatments are loaded
    final allTreatments = treatmentManager.treatments;
    
    try {
      // First, try to load from storage
      final logs = await HiveService.getMedicationLogsForDate(date);

      if (logs != null && logs.isNotEmpty) {
        // Convert the logs back to IntakeLog objects with safer type handling
        final List<IntakeLog> intakeLogs = [];

        for (final dynamic logEntry in logs) {
          try {
            if (logEntry is Map) {
              // Create a Map<String, dynamic> from the potentially untyped Map
              final Map<String, dynamic> typedMap = {};
              logEntry.forEach((key, value) {
                if (key is String) {
                  typedMap[key] = value;
                }
              });

              if (typedMap.isNotEmpty) {
                // Create the base IntakeLog
                final intakeLog = IntakeLog.fromMap(typedMap);

                // CRITICAL FIX: Update with the latest treatment data if it exists
                final treatmentId = intakeLog.treatment.id;
                final matchingTreatment = allTreatments.firstWhere(
                  (t) => t.id == treatmentId,
                  orElse: () => intakeLog.treatment,
                );

                // Use the updated treatment but preserve the intake status AND doseTime
                final updatedIntakeLog = IntakeLog(matchingTreatment,
                    doseTime: intakeLog.doseTime, // CRITICAL: Preserve the specific doseTime
                    isTaken: intakeLog.isTaken, 
                    isSkipped: intakeLog.isSkipped);
                intakeLogs.add(updatedIntakeLog);
              }
            }
          } catch (parseError) {
            'Error parsing individual log entry: $parseError'.log();
            // Skip this entry and continue with others
          }
        }

        // Deduplicate logs by (treatment_id, dose_time) - keep the most recent one
        if (intakeLogs.isNotEmpty) {
          final deduplicatedLogs = _deduplicateLogs(intakeLogs);
          final wasDeduplicated = deduplicatedLogs.length < intakeLogs.length;
          if (wasDeduplicated) {
            devPrint("Deduplicated ${intakeLogs.length} logs to ${deduplicatedLogs.length} unique entries");
          }
          medicationLogs[date] = deduplicatedLogs;
          return;
        }
      }
    } catch (e) {
      // If there's an error, we'll fall back to creating logs from current treatments
      'Error loading medication logs: $e'.log();
    }

    // If we don't have stored logs or there was an error, create logs for treatments active on this date
    if (!medicationLogs.containsKey(date) || medicationLogs[date]!.isEmpty) {
      // Filter treatments that are active on the specific date using the already loaded treatments
      final activeTreatments = allTreatments.where((treatment) {
        // Use the new shouldTakeOnDate method that respects selected days
        return treatment.treatmentPlan.shouldTakeOnDate(date);
      }).toList();

      if (activeTreatments.isNotEmpty) {
        devPrint(
            "Creating logs for ${activeTreatments.length} treatments active on ${date.toString().split(' ')[0]}");
        
        // Create one IntakeLog per dose time for each treatment
        final List<IntakeLog> logs = [];
        for (final treatment in activeTreatments) {
          final doseTimes = treatment.treatmentPlan.getAllDoseTimes();
          for (final doseTime in doseTimes) {
            logs.add(IntakeLog(treatment, doseTime: doseTime));
          }
        }
        
        medicationLogs[date] = logs;
        devPrint("Created ${logs.length} log entries (including multiple doses)");
      } else {
        devPrint(
            "No treatments active on ${date.toString().split(' ')[0]}, journal will be empty");
        medicationLogs[date] = [];
      }
    }
  }

  /// Save medication logs to Hive storage
  Future<void> saveMedicationLogs(DateTime date) async {
    date = date.normalize();
    try {
      // Ensure we have valid data to save
      if (medicationLogs.containsKey(date) &&
          medicationLogs[date] != null &&
          medicationLogs[date]!.isNotEmpty) {
        // Convert each log to a map, handling any potential errors
        final List<Map<String, dynamic>> logs = [];

        for (final log in medicationLogs[date]!) {
          try {
            logs.add(log.toMap());
          } catch (mapError) {
            'Error converting log to map: $mapError'.log();
            // Continue with other logs
          }
        }

        // Only save if we have valid logs
        if (logs.isNotEmpty) {
          await HiveService.saveMedicationLogsForDate(date, logs);
        }
      }
    } catch (e) {
      'Error saving medication logs: $e'.log();
    }
  }

  Future<List<IntakeLog>> getMedicationsForTheDay(DateTime date,
      {bool forceReload = false}) async {
    date = date.normalize();

    // Always reload from storage if force reload is requested
    if (forceReload ||
        !medicationLogs.containsKey(date) ||
        medicationLogs[date]!.isEmpty) {
      await _loadMedicationLogs(date);
      "Medications for ${date.toString()} loaded from storage (force: $forceReload)"
          .log();
    } else {
      "Using cached medications for ${date.toString()}".log();
    }

    return medicationLogs[date] ?? [];
  }

  /// Mean adherence for *all* active treatments between the two dates.
  /// Counts every day in the interval for every treatment, even if no
  /// log entry exists (missed doses stay missed).
  ///
  /// Returns 0.0 if no treatments are present at all.
  double getAdherenceRateAll(DateTime startDate, DateTime endDate) {
    // Normalise the bounds to midnight so we step cleanly day-by-day.
    final DateTime start =
        DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime end = DateTime(endDate.year, endDate.month, endDate.day);

    if (end.isBefore(start)) return 0.0;

    // 1️⃣  Figure out which treatments are *active* in this window.
    final Set<String> treatmentIds = <String>{};

    int takenDoseCount = 0;

    DateTime current = start;
    while (!current.isAfter(end)) {
      final logs = medicationLogs[current];
      if (logs != null && logs.isNotEmpty) {
        for (final log in logs) {
          treatmentIds.add(log.treatment.id);
          if (log.isTaken) takenDoseCount++;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    if (treatmentIds.isEmpty) return 0.0;

    // 2️⃣  Expected doses  =  (# days) × (# distinct treatments)
    final int daysInclusive = end.difference(start).inDays + 1;
    final int expectedDoseCount = treatmentIds.length * daysInclusive;

    final rawRate = takenDoseCount / expectedDoseCount;

    // Round to 4 decimals and turn back into a double:
    return (rawRate * 10000).round() / 10000;
  }

  /// Calculate adherence rate based on in-memory data
  /// Note: This method doesn't load data from storage - call getMedicationsForTheDay
  /// for all relevant dates before using this method for accurate results
  double getAdherenceRate(
      Treatment treatment, DateTime startDate, DateTime endDate) {
    int takenCount = 0;
    int totalDays = 0;

    DateTime currentDate = startDate.normalize();

    while (!currentDate.isAfter(endDate)) {
      final hasMedsForDate = medicationLogs.containsKey(currentDate) &&
          medicationLogs[currentDate] != null &&
          medicationLogs[currentDate]!.isNotEmpty;

      if (hasMedsForDate) {
        for (final log in medicationLogs[currentDate]!) {
          if (log.treatment.id == treatment.id) {
            takenCount += log.isTaken ? 1 : 0;
            totalDays++;
          }
        }
      }

      // Increment day safely
      final nextDate = currentDate.add(const Duration(days: 1));
      currentDate = DateTime(nextDate.year, nextDate.month, nextDate.day);
    }

    if (totalDays == 0) return 0.0;
    return takenCount / totalDays;
  }

  /// Get adherence counts (taken and scheduled) for a treatment.
  /// Precondition: `medicationLogs` must already be populated for every date in
  /// `startDate..endDate`; callers should preload via `getAdherenceCountsAsync`
  /// or by invoking `getMedicationsForTheDay` for each date to avoid
  /// under-counting scheduled doses. Returns a map with 'taken' and 'scheduled'
  /// keys.
  Map<String, int> getAdherenceCounts(
      Treatment treatment, DateTime startDate, DateTime endDate) {
    int takenCount = 0;
    int scheduledCount = 0;

    DateTime currentDate = startDate.normalize();

    while (!currentDate.isAfter(endDate)) {
      final hasMedsForDate = medicationLogs.containsKey(currentDate) &&
          medicationLogs[currentDate] != null &&
          medicationLogs[currentDate]!.isNotEmpty;

      if (hasMedsForDate) {
        for (final log in medicationLogs[currentDate]!) {
          if (log.treatment.id == treatment.id) {
            scheduledCount++;
            if (log.isTaken) takenCount++;
          }
        }
      }

      // Increment day safely
      final nextDate = currentDate.add(const Duration(days: 1));
      currentDate = DateTime(nextDate.year, nextDate.month, nextDate.day);
    }

    return {'taken': takenCount, 'scheduled': scheduledCount};
  }

  Future<void> _preloadMedicationLogs(
      DateTime startDate, DateTime endDate) async {
    // Collect all date futures and await them in batch for better performance
    final futures = <Future<List<IntakeLog>>>[];

    DateTime currentDate = startDate.normalize();
    while (!currentDate.isAfter(endDate)) {
      futures.add(getMedicationsForTheDay(currentDate));

      // Increment day safely
      final nextDate = currentDate.add(const Duration(days: 1));
      currentDate = DateTime(nextDate.year, nextDate.month, nextDate.day);
    }

    await Future.wait(futures);
  }

  /// Asynchronous version that loads data and returns adherence counts
  Future<Map<String, int>> getAdherenceCountsAsync(
      Treatment treatment, DateTime startDate, DateTime endDate) async {
    await _preloadMedicationLogs(startDate, endDate);
    return getAdherenceCounts(treatment, startDate, endDate);
  }

  /// Asynchronous version of getAdherenceRate that loads data from storage
  Future<double> getAdherenceRateAsync(
      Treatment treatment, DateTime startDate, DateTime endDate) async {
    await _preloadMedicationLogs(startDate, endDate);
    return getAdherenceRate(treatment, startDate, endDate);
  }

  /// Asynchronous version of getAdherenceRateAll that loads data from storage
  Future<double> getAdherenceRateAllAsync(
      DateTime startDate, DateTime endDate) async {
    await _preloadMedicationLogs(startDate, endDate);
    return getAdherenceRateAll(startDate, endDate);
  }

  /// Force reload medication logs for a specific date by clearing the cache
  Future<List<IntakeLog>> forceReloadMedicationLogs(DateTime date) async {
    date = date.normalize();
    // PERFORMANCE FIX: Only remove the specific date entry instead of clearing all
    medicationLogs.remove(date);

    // CRITICAL FIX: Ensure we get the most up-to-date treatments
    final treatmentManager = TreatmentManager();
    await treatmentManager.loadTreatments(); // Reload fresh from storage

    devPrint(
        "Force reloading medication logs for ${date.toString().split(' ')[0]} with ${treatmentManager.treatments.length} current treatments");

    // Get the existing logs if any
    final existingLogs = await HiveService.getMedicationLogsForDate(date);
    bool needsUpdate = false;

    // Create a new list for this date
    final updatedLogs = <IntakeLog>[];

    if (existingLogs != null && existingLogs.isNotEmpty) {
      devPrint("Found ${existingLogs.length} existing logs for this date");

      // For each existing log, try to find the updated treatment
      for (final logMap in existingLogs) {
        final medicineName = logMap['medicine_name'] as String?;
        
        // Convert taken status with safe default (matching fromMap logic)
        final isTakenValue = logMap['is_taken'];
        bool isTaken = false;
        if (isTakenValue != null) {
          if (isTakenValue is bool) {
            isTaken = isTakenValue;
          } else if (isTakenValue is int) {
            isTaken = isTakenValue != 0;
          } else if (isTakenValue is String) {
            isTaken = isTakenValue.toLowerCase() == 'true' || isTakenValue == '1';
          }
        }
        
        // Convert skipped status with safe default (matching fromMap logic)
        final isSkippedValue = logMap['is_skipped'];
        bool isSkipped = false;
        if (isSkippedValue != null) {
          if (isSkippedValue is bool) {
            isSkipped = isSkippedValue;
          } else if (isSkippedValue is int) {
            isSkipped = isSkippedValue != 0;
          } else if (isSkippedValue is String) {
            isSkipped = isSkippedValue.toLowerCase() == 'true' || isSkippedValue == '1';
          }
        }
        
        // Enforce exclusivity: isTaken and isSkipped cannot both be true
        if (isTaken && isSkipped) {
          isSkipped = false;
        }
        
        String treatmentId = logMap['treatment_id'] as String? ?? '';
        
        // Parse dose time if available
        DateTime? doseTime;
        final doseTimeValue = logMap['dose_time'];
        if (doseTimeValue != null && doseTimeValue is String) {
          try {
            doseTime = DateTime.parse(doseTimeValue);
          } catch (e) {
            doseTime = null;
          }
        }

        devPrint(
            "Processing journal entry for: $medicineName (ID: $treatmentId)");

        // First try to find by ID if present
        Treatment? updatedTreatment;
        if (treatmentId.isNotEmpty) {
          try {
            updatedTreatment = treatmentManager.treatments
                .firstWhere((t) => t.id == treatmentId);
            devPrint(
                "Found treatment by ID match: ${updatedTreatment.medicine.name}");
          } catch (e) {
            // No treatment found by ID
            devPrint("No treatment found with ID: $treatmentId");
          }
        }

        // If ID didn't match or was empty, try by name
        if (updatedTreatment == null &&
            medicineName != null &&
            medicineName.isNotEmpty) {
          try {
            updatedTreatment = treatmentManager.treatments.firstWhere((t) =>
                t.medicine.name.toLowerCase() == medicineName.toLowerCase());
            devPrint(
                "Found treatment by name match: ${updatedTreatment.medicine.name} with ID: ${updatedTreatment.id}");

            // If we found by name but ID is different, it's an update
            if (treatmentId != updatedTreatment.id) {
              devPrint(
                  "ID changed from '$treatmentId' to '${updatedTreatment.id}'");
              needsUpdate = true;
            }
          } catch (e) {
            devPrint("No treatment found with name: $medicineName");
          }
        }

        // If we found a treatment, check if it has multiple doses
        if (updatedTreatment != null) {
          final treatmentDoseCount = updatedTreatment.treatmentPlan.getAllDoseTimes().length;
          
          // If treatment now has multiple doses and this log doesn't have a doseTime,
          // or if the stored doseTime doesn't match any of the current treatment's dose times,
          // skip this log - we'll recreate all doses properly later
          if (treatmentDoseCount > 1) {
            final allTreatmentDoseTimes = updatedTreatment.treatmentPlan.getAllDoseTimes();
            if (doseTime == null) {
              // Old log without doseTime - skip it, we'll recreate all doses
              devPrint("Skipping old log without doseTime for ${updatedTreatment.medicine.name} (has $treatmentDoseCount doses now)");
              continue;
            }
            
            // Normalize doseTime to just hour:minute for comparison (ignore date part)
            final storedHour = doseTime.hour;
            final storedMinute = doseTime.minute;
            
            // Check if this doseTime matches one of the treatment's current dose times
            final doseTimeMatches = allTreatmentDoseTimes.any((t) => 
              t.hour == storedHour && t.minute == storedMinute
            );
            
            if (!doseTimeMatches) {
              // This dose time is no longer valid for this treatment - skip it
              devPrint("Skipping log with outdated doseTime $storedHour:$storedMinute for ${updatedTreatment.medicine.name}");
              continue;
            }
            
            // Create a normalized doseTime (using createTimeOfDay to match TreatmentPlan format)
            final normalizedDoseTime = createTimeOfDay(storedHour, storedMinute);
            final log = IntakeLog(updatedTreatment,
                doseTime: normalizedDoseTime, isTaken: isTaken, isSkipped: isSkipped);
            updatedLogs.add(log);
            devPrint("Added log for ${updatedTreatment.medicine.name} with doseTime: $storedHour:$storedMinute");
          } else {
            // Single dose treatment - check if the stored doseTime matches current timeOfDay
            final currentTimeOfDay = updatedTreatment.treatmentPlan.timeOfDay;
            final storedHour = doseTime?.hour;
            final storedMinute = doseTime?.minute;
            final currentHour = currentTimeOfDay.hour;
            final currentMinute = currentTimeOfDay.minute;
            
            // Preserve the log if:
            // 1. doseTime is null (will use treatment's default timeOfDay), OR
            // 2. doseTime matches current timeOfDay (time hasn't changed)
            // Only skip if doseTime is explicitly set and doesn't match (time was changed)
            if (doseTime == null || (storedHour == currentHour && storedMinute == currentMinute)) {
              // Use the treatment's timeOfDay if doseTime was null
              final logDoseTime = doseTime ?? createTimeOfDay(currentHour, currentMinute);
              final log = IntakeLog(updatedTreatment,
                  doseTime: logDoseTime, isTaken: isTaken, isSkipped: isSkipped);
              updatedLogs.add(log);
              devPrint("Added log for ${updatedTreatment.medicine.name} with doseTime: ${doseTime != null ? '$storedHour:$storedMinute' : '$currentHour:$currentMinute (from treatment)'}");
            } else {
              // Time changed - skip old log, it will be recreated with new time
              devPrint("Skipping outdated single-dose log for ${updatedTreatment.medicine.name} (old: $storedHour:$storedMinute, new: $currentHour:$currentMinute)");
            }
          }
        }
      }
    } else {
      // No existing logs, create new ones from treatments active on this date
      devPrint(
          "No existing logs, creating new ones from treatments active on ${date.toString().split(' ')[0]}");

      // Filter treatments that are active on the specific date
      final activeTreatments = treatmentManager.treatments.where((treatment) {
        // Use the new shouldTakeOnDate method that respects selected days
        return treatment.treatmentPlan.shouldTakeOnDate(date);
      }).toList();

      for (final treatment in activeTreatments) {
        // Create one log per dose time
        final doseTimes = treatment.treatmentPlan.getAllDoseTimes();
        for (final doseTime in doseTimes) {
          final log = IntakeLog(treatment, doseTime: doseTime);
          updatedLogs.add(log);
          needsUpdate = true;
          devPrint(
              "Created new log for ${treatment.medicine.name} at ${doseTime.hour}:${doseTime.minute} with ID: ${treatment.id}");
        }
      }
    }
    
    // Always check for new treatments that should be active on this date
    // but weren't in the existing logs (regardless of whether we had existing logs or not)
    final activeTreatments = treatmentManager.treatments.where((treatment) {
      return treatment.treatmentPlan.shouldTakeOnDate(date);
    }).toList();
    
    // Create a set of (treatment_id, dose_time) pairs already in updatedLogs
    final existingLogKeys = updatedLogs.map((log) {
      if (log.doseTime != null) {
        // Normalize to hour:minute format
        final hour = log.doseTime!.hour;
        final minute = log.doseTime!.minute;
        return '${log.treatment.id}_$hour:$minute';
      } else {
        return '${log.treatment.id}_default';
      }
    }).toSet();
    
    // Add any new treatment doses that should be active but aren't in logs yet
    for (final treatment in activeTreatments) {
      final doseTimes = treatment.treatmentPlan.getAllDoseTimes();
      for (final doseTime in doseTimes) {
        final hour = doseTime.hour;
        final minute = doseTime.minute;
        final timeKey = '$hour:$minute';
        final logKey = '${treatment.id}_$timeKey';
        
        if (!existingLogKeys.contains(logKey)) {
          final log = IntakeLog(treatment, doseTime: doseTime);
          updatedLogs.add(log);
          needsUpdate = true;
        }
      }
    }

    // Deduplicate logs by (treatment_id, dose_time) - keep the one with most info
    final deduplicatedLogs = _deduplicateLogs(updatedLogs);
    final wasDeduplicated = deduplicatedLogs.length < updatedLogs.length;
    if (wasDeduplicated) {
      devPrint("Deduplicated ${updatedLogs.length} logs to ${deduplicatedLogs.length} unique entries in forceReload");
    }

    // Update our in-memory store
    medicationLogs[date] = deduplicatedLogs;

    // If we made changes, save them
    if (needsUpdate || wasDeduplicated || deduplicatedLogs.length != (existingLogs?.length ?? 0)) {
      await saveMedicationLogs(date);
      devPrint(
          "Saved updated medication logs with ${deduplicatedLogs.length} entries");
    }

    return deduplicatedLogs;
  }

  /// Clear all cached medication logs to force reload from storage
  void clearAllCachedMedicationLogs() {
    medicationLogs.clear();
  }
}
