// ignore_for_file: prefer_const_constructors, avoid_print, unnecessary_import
import 'package:flutter_test/flutter_test.dart';
import 'package:pinkrain/core/models/medicine_model.dart';
import 'package:pinkrain/features/treatment/data/treatment.dart';
import 'package:pinkrain/features/treatment/domain/treatment_manager.dart';

void main() {
  late TreatmentManager treatmentManager;

  /// Creates a test treatment with the given parameters.
  Treatment createTestTreatment({
    String name = 'Test Medicine',
    String type = 'Tablet',
    String color = 'White',
    double dosage = 10.0,
    String unit = 'mg',
    String mealOption = 'After meal',
    String notes = 'Test notes',
  }) {
    final medicine = Medicine(name: name, type: type, color: color)
      ..addSpecification(
          Specification(dosage: dosage, unit: unit, useCase: 'Test use case'));

    final treatmentPlan = TreatmentPlan(
      startDate: DateTime(2025, 4, 20),
      endDate: DateTime(2025, 4, 27),
      timeOfDay: DateTime(2025, 1, 1, 8, 0),
      mealOption: mealOption,
      instructions: 'Take once daily',
      frequency: Duration(days: 1),
    );

    return Treatment(
      medicine: medicine,
      treatmentPlan: treatmentPlan,
      notes: notes,
    );
  }

  setUp(() {
    treatmentManager = TreatmentManager();
  });

  group('TreatmentManager - Edit Treatment Tests', () {
    test('updateTreatment should update an existing treatment correctly',
        () async {
      final originalTreatment = createTestTreatment();
      final updatedTreatment = createTestTreatment(
        name: 'Updated Medicine',
        type: 'Capsule',
        color: 'Blue',
        dosage: 20.0,
        unit: 'g',
        mealOption: 'Before meal',
        notes: 'Updated notes',
      );
      expect(updatedTreatment.medicine.name, 'Updated Medicine');
      expect(updatedTreatment.medicine.type, 'Capsule');
      expect(updatedTreatment.medicine.color, 'Blue');
      expect(updatedTreatment.medicine.specs.dosage, 20.0);
      expect(updatedTreatment.medicine.specs.unit, 'g');
      expect(updatedTreatment.treatmentPlan.mealOption, 'Before meal');
      expect(updatedTreatment.notes, 'Updated notes');
      expect(updatedTreatment.treatmentPlan.startDate, DateTime(2025, 4, 20));
      expect(updatedTreatment.treatmentPlan.endDate, DateTime(2025, 4, 27));
    });

    test('Treatment object should be properly serialized to JSON', () {
      final treatment = createTestTreatment();
      final json = treatment.toJson();
      expect(json['medicine']['name'], 'Test Medicine');
      expect(json['medicine']['type'], 'Tablet');
      expect(json['medicine']['color'], 'White');
      expect(json['medicine']['specification']['dosage'], 10.0);
      expect(json['medicine']['specification']['unit'], 'mg');
      expect(json['treatmentPlan']['mealOption'], 'After meal');
      expect(json['notes'], 'Test notes');
    });

    test('Treatment should be properly reconstructed from JSON', () {
      final originalTreatment = createTestTreatment();
      final json = originalTreatment.toJson();
      final reconstructedTreatment = Treatment.fromJson(json);
      expect(reconstructedTreatment.medicine.name, 'Test Medicine');
      expect(reconstructedTreatment.medicine.type, 'Tablet');
      expect(reconstructedTreatment.medicine.color, 'White');
      expect(reconstructedTreatment.medicine.specs.dosage, 10.0);
      expect(reconstructedTreatment.medicine.specs.unit, 'mg');
      expect(reconstructedTreatment.treatmentPlan.mealOption, 'After meal');
      expect(reconstructedTreatment.notes, 'Test notes');
      expect(reconstructedTreatment.treatmentPlan.startDate,
          originalTreatment.treatmentPlan.startDate);
      expect(reconstructedTreatment.treatmentPlan.endDate,
          originalTreatment.treatmentPlan.endDate);
    });
  });
}
