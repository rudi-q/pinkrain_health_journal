// ignore_for_file: prefer_const_constructors, avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:pillow/core/models/medicine_model.dart';
import 'package:pillow/core/services/hive_service.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/treatment/data/treatment.dart';
import 'package:pillow/features/treatment/domain/treatment_manager.dart';
import 'package:pillow/features/journal/data/journal_log.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  late TreatmentManager treatmentManager;
  late JournalLog journalLog;
  
  // Helper function to create a test treatment
  Treatment createTestTreatment({
    String? id,
    String name = 'Test Medicine',
    String type = 'Tablet',
    String color = 'White',
    double dosage = 10.0,
    String unit = 'mg',
    String mealOption = 'After meal',
    String notes = 'Test notes',
  }) {
    final medicine = Medicine(name: name, type: type, color: color)
      ..addSpecification(Specification(dosage: dosage, unit: unit, useCase: 'Test use case'));

    final treatmentPlan = TreatmentPlan(
      startDate: DateTime(2025, 4, 20),
      endDate: DateTime(2025, 4, 27),
      timeOfDay: DateTime(2025, 1, 1, 8, 0),
      mealOption: mealOption,
      instructions: 'Take once daily',
      frequency: Duration(days: 1),
    );

    return Treatment(
      id: id,
      medicine: medicine,
      treatmentPlan: treatmentPlan,
      notes: notes,
    );
  }

  // Setup mock Hive for testing
  setUpAll(() async {
    // Create a temporary directory for Hive
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    
    // Register any adapters if needed
    // Hive.registerAdapter(YourAdapter());
  });

  setUp(() async {
    // Initialize a fresh TreatmentManager and JournalLog for each test
    treatmentManager = TreatmentManager();
    journalLog = JournalLog();
    
    // Clear any existing data
    await HiveService.init();
  });

  tearDown(() async {
    // Clean up after each test
    await Hive.deleteFromDisk();
  });

  group('Edit Treatment Functionality Tests', () {
    test('Edit treatment dosage should update correctly', () async {
      // Arrange: Create and save a treatment
      final originalTreatment = createTestTreatment();
      await treatmentManager.saveTreatment(originalTreatment);
      
      // Act: Update the treatment with a new dosage
      final updatedTreatment = createTestTreatment(
        id: originalTreatment.id,
        dosage: 20.0,
      );
      
      await treatmentManager.updateTreatment(originalTreatment, updatedTreatment);
      
      // Reload treatments to verify persistence
      await treatmentManager.loadTreatments();
      
      // Assert: Verify the dosage was updated
      final savedTreatment = treatmentManager.treatments.firstWhere(
        (t) => t.id == originalTreatment.id,
        orElse: () => throw Exception('Treatment not found'),
      );
      
      expect(savedTreatment.medicine.specs.dosage, 20.0);
      expect(savedTreatment.id, originalTreatment.id);
      expect(savedTreatment.medicine.name, originalTreatment.medicine.name);
    });

    test('Edit treatment color should update correctly', () async {
      // Arrange: Create and save a treatment
      final originalTreatment = createTestTreatment();
      await treatmentManager.saveTreatment(originalTreatment);
      
      // Act: Update the treatment with a new color
      final updatedTreatment = createTestTreatment(
        id: originalTreatment.id,
        color: 'Blue',
      );
      
      await treatmentManager.updateTreatment(originalTreatment, updatedTreatment);
      
      // Reload treatments to verify persistence
      await treatmentManager.loadTreatments();
      
      // Assert: Verify the color was updated
      final savedTreatment = treatmentManager.treatments.firstWhere(
        (t) => t.id == originalTreatment.id,
        orElse: () => throw Exception('Treatment not found'),
      );
      
      expect(savedTreatment.medicine.color, 'Blue');
      expect(savedTreatment.id, originalTreatment.id);
    });

    test('Edit meal preference should update correctly', () async {
      // Arrange: Create and save a treatment
      final originalTreatment = createTestTreatment();
      await treatmentManager.saveTreatment(originalTreatment);
      
      // Act: Update the treatment with a new meal preference
      final updatedTreatment = createTestTreatment(
        id: originalTreatment.id,
        mealOption: 'Before meal',
      );
      
      await treatmentManager.updateTreatment(originalTreatment, updatedTreatment);
      
      // Reload treatments to verify persistence
      await treatmentManager.loadTreatments();
      
      // Assert: Verify the meal preference was updated
      final savedTreatment = treatmentManager.treatments.firstWhere(
        (t) => t.id == originalTreatment.id,
        orElse: () => throw Exception('Treatment not found'),
      );
      
      expect(savedTreatment.treatmentPlan.mealOption, 'Before meal');
      expect(savedTreatment.id, originalTreatment.id);
    });

    test('Edit treatment name should update correctly', () async {
      // Arrange: Create and save a treatment
      final originalTreatment = createTestTreatment();
      await treatmentManager.saveTreatment(originalTreatment);
      
      // Act: Update the treatment with a new name
      final updatedTreatment = createTestTreatment(
        id: originalTreatment.id,
        name: 'Updated Medicine Name',
      );
      
      await treatmentManager.updateTreatment(originalTreatment, updatedTreatment);
      
      // Reload treatments to verify persistence
      await treatmentManager.loadTreatments();
      
      // Assert: Verify the name was updated
      final savedTreatment = treatmentManager.treatments.firstWhere(
        (t) => t.id == originalTreatment.id,
        orElse: () => throw Exception('Treatment not found'),
      );
      
      expect(savedTreatment.medicine.name, 'Updated Medicine Name');
      expect(savedTreatment.id, originalTreatment.id);
    });

    test('Edit treatment type should update correctly', () async {
      // Arrange: Create and save a treatment
      final originalTreatment = createTestTreatment();
      await treatmentManager.saveTreatment(originalTreatment);
      
      // Act: Update the treatment with a new type
      final updatedTreatment = createTestTreatment(
        id: originalTreatment.id,
        type: 'Capsule',
      );
      
      await treatmentManager.updateTreatment(originalTreatment, updatedTreatment);
      
      // Reload treatments to verify persistence
      await treatmentManager.loadTreatments();
      
      // Assert: Verify the type was updated
      final savedTreatment = treatmentManager.treatments.firstWhere(
        (t) => t.id == originalTreatment.id,
        orElse: () => throw Exception('Treatment not found'),
      );
      
      expect(savedTreatment.medicine.type, 'Capsule');
      expect(savedTreatment.id, originalTreatment.id);
    });

    test('Updated treatment should be reflected in journal logs', () async {
      // Arrange: Create and save a treatment
      final originalTreatment = createTestTreatment();
      await treatmentManager.saveTreatment(originalTreatment);
      
      // Create a journal log entry for today with this treatment
      final today = DateTime.now().normalize();
      final intakeLog = IntakeLog(originalTreatment);
      
      // Save the log to the journal
      journalLog.medicationLogs[today] = [intakeLog];
      await journalLog.saveMedicationLogs(today);
      
      // Act: Update the treatment with new values
      final updatedTreatment = createTestTreatment(
        id: originalTreatment.id,
        name: 'Updated Medicine Name',
        dosage: 20.0,
        color: 'Blue',
        mealOption: 'Before meal',
      );
      
      await treatmentManager.updateTreatment(originalTreatment, updatedTreatment);
      
      // Force reload the journal logs to get the updated treatment
      await journalLog.forceReloadMedicationLogs(today);
      
      // Assert: Verify the journal log reflects the updated treatment
      final updatedLogs = journalLog.medicationLogs[today];
      expect(updatedLogs, isNotNull);
      expect(updatedLogs!.isNotEmpty, true);
      
      final updatedLog = updatedLogs.firstWhere(
        (log) => log.treatment.id == originalTreatment.id,
        orElse: () => throw Exception('Treatment log not found'),
      );
      
      expect(updatedLog.treatment.medicine.name, 'Updated Medicine Name');
      expect(updatedLog.treatment.medicine.specs.dosage, 20.0);
      expect(updatedLog.treatment.medicine.color, 'Blue');
      expect(updatedLog.treatment.treatmentPlan.mealOption, 'Before meal');
    });

    test('Multiple edits to the same treatment should all be reflected', () async {
      // Arrange: Create and save a treatment
      final originalTreatment = createTestTreatment();
      await treatmentManager.saveTreatment(originalTreatment);
      
      // First edit: Update dosage
      var updatedTreatment = createTestTreatment(
        id: originalTreatment.id,
        dosage: 15.0,
      );
      
      await treatmentManager.updateTreatment(originalTreatment, updatedTreatment);
      
      // Second edit: Update color
      updatedTreatment = createTestTreatment(
        id: originalTreatment.id,
        dosage: 15.0, // Keep the previously updated dosage
        color: 'Yellow',
      );
      
      await treatmentManager.updateTreatment(
        treatmentManager.treatments.firstWhere((t) => t.id == originalTreatment.id),
        updatedTreatment
      );
      
      // Third edit: Update meal preference
      updatedTreatment = createTestTreatment(
        id: originalTreatment.id,
        dosage: 15.0, // Keep the previously updated dosage
        color: 'Yellow', // Keep the previously updated color
        mealOption: 'With food',
      );
      
      await treatmentManager.updateTreatment(
        treatmentManager.treatments.firstWhere((t) => t.id == originalTreatment.id),
        updatedTreatment
      );
      
      // Reload treatments to verify persistence
      await treatmentManager.loadTreatments();
      
      // Assert: Verify all changes were applied
      final savedTreatment = treatmentManager.treatments.firstWhere(
        (t) => t.id == originalTreatment.id,
        orElse: () => throw Exception('Treatment not found'),
      );
      
      expect(savedTreatment.medicine.specs.dosage, 15.0);
      expect(savedTreatment.medicine.color, 'Yellow');
      expect(savedTreatment.treatmentPlan.mealOption, 'With food');
    });

    test('Treatment ID should be preserved when editing', () async {
      // Arrange: Create and save a treatment with a specific ID
      final String specificId = 'test-id-123';
      final originalTreatment = createTestTreatment(id: specificId);
      await treatmentManager.saveTreatment(originalTreatment);
      
      // Act: Update the treatment
      final updatedTreatment = createTestTreatment(
        id: specificId,
        name: 'Updated Name',
      );
      
      await treatmentManager.updateTreatment(originalTreatment, updatedTreatment);
      
      // Reload treatments to verify persistence
      await treatmentManager.loadTreatments();
      
      // Assert: Verify the ID was preserved
      final savedTreatment = treatmentManager.treatments.firstWhere(
        (t) => t.medicine.name == 'Updated Name',
        orElse: () => throw Exception('Treatment not found'),
      );
      
      expect(savedTreatment.id, specificId);
    });
  });
}