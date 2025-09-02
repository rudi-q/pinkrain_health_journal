import 'dart:math';

import 'package:pinkrain/core/models/medicine_model.dart';
import 'package:pinkrain/core/services/hive_service.dart';

import '../../../core/util/helpers.dart';
import '../data/treatment.dart';

/// Generate a simple unique ID without external dependencies
String generateUniqueId() {
  final random = Random();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final randomPart = random.nextInt(1000000).toString().padLeft(6, '0');
  return '$timestamp$randomPart';
}

class Treatment {
  final String id;
  final Medicine medicine;
  final TreatmentPlan treatmentPlan;
  final String notes;

  Treatment({
    String? id,
    required this.medicine,
    required this.treatmentPlan,
    this.notes = '',
  }) : id = id ?? generateUniqueId();

  /// Format the treatment's scheduled time in a readable format (e.g., "10:00 AM")
  String formattedTimeOfDay() {
    final time = treatmentPlan.timeOfDay;
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicine': {
        'name': medicine.name,
        'type': medicine.type,
        'color': medicine.color,
        'specification': {
          'dosage': medicine.specs.dosage,
          'unit': medicine.specs.unit,
          'useCase': medicine.specs.useCase,
        },
      },
      'treatmentPlan': {
        'startDate': treatmentPlan.startDate.toIso8601String(),
        'endDate': treatmentPlan.endDate.toIso8601String(),
        'timeOfDay': treatmentPlan.timeOfDay.toIso8601String(),
        'mealOption': treatmentPlan.mealOption,
        'instructions': treatmentPlan.instructions,
        'frequency': treatmentPlan.frequency.inDays,
      },
      'notes': notes,
    };
  }

  static Treatment fromJson(Map<String, dynamic> json) {
    try {
      final medicineJson = json['medicine'] as Map<String, dynamic>;
      final treatmentPlanJson = json['treatmentPlan'] as Map<String, dynamic>;
      final specJson = medicineJson['specification'] as Map<String, dynamic>;

      final medicine = Medicine(
        name: medicineJson['name'] as String,
        type: medicineJson['type'] as String,
        color: medicineJson['color'] as String,
      );

      medicine.addSpecification(
        Specification(
          dosage: (specJson['dosage'] is int)
              ? (specJson['dosage'] as int).toDouble()
              : specJson['dosage'] as double,
          unit: specJson['unit'] as String,
          useCase: specJson['useCase'] as String,
        ),
      );

      final treatmentPlan = TreatmentPlan(
        startDate: DateTime.parse(treatmentPlanJson['startDate'] as String),
        endDate: DateTime.parse(treatmentPlanJson['endDate'] as String),
        timeOfDay: DateTime.parse(treatmentPlanJson['timeOfDay'] as String),
        mealOption: treatmentPlanJson['mealOption'] as String,
        instructions: treatmentPlanJson['instructions'] as String,
        frequency: Duration(days: treatmentPlanJson['frequency'] as int),
      );

      // Handle id more safely
      String? id;
      try {
        id = json['id'] as String?;
      } catch (e) {
        id = null; // If any issue accessing or casting, set to null
      }

      return Treatment(
        id: id, // Will generate a new ID if null
        medicine: medicine,
        treatmentPlan: treatmentPlan,
        notes: json['notes'] as String,
      );
    } catch (e) {
      devPrint('Error parsing treatment JSON: $e');
      // If parsing fails, create a minimal valid treatment
      final defaultMedicine = Medicine(name: 'Error Treatment', type: 'pill', color: 'red');
      defaultMedicine.addSpecification(Specification(dosage: 1.0, unit: 'mg', useCase: ''));
      
      final defaultPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        timeOfDay: DateTime(2023, 1, 1, 12, 0),
      );
      
      return Treatment(medicine: defaultMedicine, treatmentPlan: defaultPlan);
    }
  }

  static Treatment newTreatment({
    required String name,
    required String type,
    required String color,
    required double dose,
    required String unit,
    String? useCase,
    DateTime? startDate,
    DateTime? endDate,
    String? mealOption,
    String? instructions,
    Duration? frequency,
    String? id,
  }) {
    final specs = Specification(
      dosage: dose,
      unit: unit,
      useCase: useCase ?? '',
    );

    // Set default values if not provided
    final now = DateTime.now();
    startDate ??= now;
    endDate ??= now.add(const Duration(days: 7));
    mealOption ??= 'No preference';
    instructions ??= '';
    frequency ??= const Duration(days: 1);

    // Create medicine and add specification
    final medicine = Medicine(
      name: name,
      type: type,
      color: color,
    )..addSpecification(specs);

    // Create treatment plan
    final plan = TreatmentPlan(
      startDate: startDate,
      endDate: endDate,
      timeOfDay: DateTime(2023, 1, 1, 11, 0),
      mealOption: mealOption,
      instructions: instructions,
      frequency: frequency,
    );

    // Generate a unique ID if none provided
    final treatmentId = id ?? generateUniqueId();
    
    // Create and return the treatment with explicit ID
    return Treatment(
      id: treatmentId,
      medicine: medicine,
      treatmentPlan: plan,
    );
  }

  static List<Treatment> getSample() {
    List<Treatment> treatments = [];
/*

    Medicine medicine;
    TreatmentPlan treatmentPlan;
    Treatment newTreatment;

    medicine = Medicine(name: 'Paracetamol', type: 'pill');
    medicine.addSpecification(Specification(dosage: 20, unit: 'mg'));

    treatmentPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 2)),
        mealOption: 'After dinner',
        instructions: 'Take 1 tablet every night before bed',
        timeOfDay: DateTime(2023, 1, 1, 11, 0));
    newTreatment = Treatment(medicine: medicine, treatmentPlan: treatmentPlan);

    treatments.add(newTreatment);

    medicine = Medicine(name: 'Levocetirizine', type: 'pill');
    medicine.addSpecification(Specification(dosage: 20, unit: 'mg'));

    treatmentPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 1)),
        timeOfDay: DateTime(2023, 1, 1, 12, 0));
    newTreatment = Treatment(medicine: medicine, treatmentPlan: treatmentPlan);

    treatments.add(newTreatment);

    medicine = Medicine(name: 'Aspirin', type: 'tablet');
    medicine.addSpecification(Specification(dosage: 20, unit: 'mg'));

    treatmentPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 3)),
        timeOfDay: DateTime(2023, 1, 1, 23, 0));
    newTreatment = Treatment(medicine: medicine, treatmentPlan: treatmentPlan);

    treatments.add(newTreatment);
*/

    return treatments;
  }

  static List<Treatment> getSampleForPillBox() {
    List<Treatment> treatments = [];

    Medicine medicine;
    TreatmentPlan treatmentPlan;
    Treatment newTreatment;

    medicine = Medicine(name: 'Paracetamol', type: 'pill');
    medicine.addSpecification(Specification(dosage: 20, unit: 'mg'));

    treatmentPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 2)),
        mealOption: 'After dinner',
        instructions: 'Take 1 tablet every night before bed',
        timeOfDay: DateTime(2023, 1, 1, 11, 0));
    newTreatment = Treatment(medicine: medicine, treatmentPlan: treatmentPlan);

    treatments.add(newTreatment);

    medicine = Medicine(name: 'Levocetirizine', type: 'pill');
    medicine.addSpecification(Specification(dosage: 20, unit: 'mg'));

    treatmentPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 1)),
        timeOfDay: DateTime(2023, 1, 1, 12, 0));
    newTreatment = Treatment(medicine: medicine, treatmentPlan: treatmentPlan);

    treatments.add(newTreatment);

    medicine = Medicine(name: 'Aspirin', type: 'tablet');
    medicine.addSpecification(Specification(dosage: 20, unit: 'mg'));

    treatmentPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 3)),
        timeOfDay: DateTime(2023, 1, 1, 23, 0));
    newTreatment = Treatment(medicine: medicine, treatmentPlan: treatmentPlan);

    treatments.add(newTreatment);

    return treatments;
  }

  static TreatmentPlan getTreatmentPlanByMedicineName(String medicineName) {
    return Treatment.getSample()
        .firstWhere((t) => t.medicine.name == medicineName)
        .treatmentPlan;
  }
}

class TreatmentManager {
  final List<Treatment> _treatments = [];

  List<Treatment> get treatments => _treatments;

  /// Load treatments data from Hive
  Future<void> loadTreatments() async {
    try {
      final storedTreatments = await HiveService.getTreatments();
      _treatments.clear();
      
      for (final treatmentMap in storedTreatments) {
        try {
          // Sanitize the map to ensure it has string keys
          final sanitizedMap = _sanitizeMap(treatmentMap);
          
          // Create the treatment from the sanitized map
          final treatment = Treatment.fromJson(sanitizedMap);
          
          // CRITICAL FIX: Generate an ID for any treatment missing one
          if (treatment.id.isEmpty) {
            devPrint('Generated new ID for existing treatment: ${treatment.medicine.name}');
            _treatments.add(Treatment(
              id: generateUniqueId(),
              medicine: treatment.medicine,
              treatmentPlan: treatment.treatmentPlan,
              notes: treatment.notes,
            ));
          } else {
            _treatments.add(treatment);
          }
        } catch (e) {
          devPrint('Error parsing treatment: $e');
          // Skip this treatment and continue
        }
      }
    } catch (e) {
      devPrint('Error loading treatments: $e');
      _treatments.clear(); // Reset to empty list on error
    }
  }

  Future<void> saveTreatment(Treatment treatment) async {
    final json = _sanitizeMap(treatment.toJson());
    await HiveService.saveTreatment(json);
    _treatments.add(treatment);
  }

  /// Update an existing treatment
  Future<void> updateTreatment(Treatment oldTreatment, Treatment updatedTreatment) async {
    try {
      // Ensure in-memory list is up-to-date
      await loadTreatments();
      
      // Log the treatment we're looking for
      devPrint('Looking for treatment to update with ID: ${oldTreatment.id}');
      
      // Convert to maps with only string keys at every level
      final oldJson = _sanitizeMap(oldTreatment.toJson());
      final updatedJson = _sanitizeMap(updatedTreatment.toJson());
      
      // First try to find by ID
      final index = _treatments.indexWhere((t) => t.id == oldTreatment.id);
      
      if (index != -1) {
        devPrint('Found treatment by ID at index: $index');
        _treatments[index] = updatedTreatment;
        
        // Persist update
        await HiveService.updateTreatment(oldJson, updatedJson);
        devPrint('Treatment updated successfully in memory and storage');
      } else {
        // Fallback to find by name (for backward compatibility)
        devPrint('Treatment not found by ID, trying name match');
        final nameIndex = _treatments.indexWhere((t) => 
          t.medicine.name.toLowerCase() == oldTreatment.medicine.name.toLowerCase()
        );
        
        if (nameIndex != -1) {
          devPrint('Found treatment by name at index: $nameIndex');
          _treatments[nameIndex] = updatedTreatment;
          await HiveService.updateTreatment(oldJson, updatedJson);
        } else {
          // If we couldn't find it by either method, we'll need to use a more direct approach
          devPrint('Treatment not found by ID or name, attempting direct update in storage');
          await HiveService.updateTreatment(oldJson, updatedJson);
        }
      }
    } catch (e) {
      devPrint('Error in updateTreatment: $e');
      rethrow; // Ensure errors propagate up for UI handling
    }
  }

  Future<void> deleteTreatment(Treatment treatment) async {
    final json = _sanitizeMap(treatment.toJson());
    await HiveService.deleteTreatment(json);
    _treatments.removeWhere((t) => t.medicine.name == treatment.medicine.name);
  }

  /// Deep sanitize a map to ensure all keys are strings
  /// This recursively processes all nested maps and lists
  Map<String, dynamic> _sanitizeMap(Map<dynamic, dynamic> input) {
    final result = <String, dynamic>{};
    
    input.forEach((key, value) {
      // Convert key to string
      final stringKey = key.toString();
      
      if (value is Map) {
        // Recursively sanitize nested maps
        result[stringKey] = _sanitizeMap(value);
      } else if (value is List) {
        // Process lists, which might contain maps
        result[stringKey] = _sanitizeList(value);
      } else {
        // Direct assignment for primitive values
        result[stringKey] = value;
      }
    });
    
    return result;
  }
  
  /// Sanitize a list, handling any maps inside it
  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _sanitizeMap(item); // Sanitize maps inside the list
      } else if (item is List) {
        return _sanitizeList(item); // Recursively sanitize nested lists
      } else {
        return item; // Return primitive values as-is
      }
    }).toList();
  }
}
