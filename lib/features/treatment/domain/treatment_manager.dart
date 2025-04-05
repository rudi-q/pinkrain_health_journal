import 'package:pillow/core/models/medicine_model.dart';
import 'package:pillow/core/services/hive_service.dart';
import 'package:pillow/core/util/helpers.dart';

import '../data/treatment.dart';

class Treatment {
  final Medicine medicine;
  final TreatmentPlan treatmentPlan;
  final String notes;

  Treatment({
    required this.medicine,
    required this.treatmentPlan,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
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
    final medicineJson = json['medicine'] as Map<String, dynamic>;
    final treatmentPlanJson = json['treatmentPlan'] as Map<String, dynamic>;
    final specJson = medicineJson['specification'] as Map<String, dynamic>;

    final medicine = Medicine(
      name: medicineJson['name'] as String,
      type: medicineJson['type'] as String,
      color: medicineJson['color'] as String,
    );

    medicine.addSpecification(Specification(
      dosage: specJson['dosage'] as double,
      unit: specJson['unit'] as String,
      useCase: specJson['useCase'] as String,
    ));

    final treatmentPlan = TreatmentPlan(
      startDate: DateTime.parse(treatmentPlanJson['startDate'] as String),
      endDate: DateTime.parse(treatmentPlanJson['endDate'] as String),
      timeOfDay: DateTime.parse(treatmentPlanJson['timeOfDay'] as String),
      mealOption: treatmentPlanJson['mealOption'] as String,
      instructions: treatmentPlanJson['instructions'] as String,
      frequency: Duration(days: treatmentPlanJson['frequency'] as int),
    );

    return Treatment(
      medicine: medicine,
      treatmentPlan: treatmentPlan,
      notes: json['notes'] as String,
    );
  }

  static Treatment newTreatment({
    required name,
    required String type,
    required String color,
    required double dose,
    required String doseUnit,
    required String mealOption,
    required String? comment,
  }) {
    var medicine = Medicine(name: name, type: type, color: color);

    var specification =
        Specification(dosage: dose, unit: doseUnit, useCase: '');

    medicine.addSpecification(specification);

    var treatmentPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 7)),
        mealOption: mealOption,
        timeOfDay: DateTime(2023, 1, 1, 11, 0));

    return Treatment(
      medicine: medicine,
      treatmentPlan: treatmentPlan,
      notes: comment ?? '',
    );
  }

  static List<Treatment> getSample() {
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

  static TreatmentPlan getPlanByMedicineName(String medicineName) {
    return Treatment.getSample()
        .firstWhere((t) => t.medicine.name == medicineName)
        .treatmentPlan;
  }

  String timeOfDay() {
    return '${treatmentPlan.timeOfDay.hour.toString().padLeft(2, '0')}'
        ' : '
        '${treatmentPlan.timeOfDay.minute.toString().padLeft(2, '0')}';
  }
}

class TreatmentManager {
  final List<Treatment> _treatments = [];

  List<Treatment> get treatments => _treatments;

  Future<void> loadTreatments() async {
    final treatmentsJson = await HiveService.getTreatments();
    _treatments.clear();
    _treatments.addAll(treatmentsJson.map((t) => Treatment.fromJson(t)));
  }

  Future<void> saveTreatment(Treatment treatment) async {
    _treatments.add(treatment);
    await HiveService.saveTreatment(treatment.toJson());

    // Create medication logs for each day in the treatment period
    final startDate = treatment.treatmentPlan.startDate.normalize();
    final endDate = treatment.treatmentPlan.endDate.normalize();
    final daysInTreatment = endDate.difference(startDate).inDays + 1;

    for (var i = 0; i < daysInTreatment; i++) {
      final date = startDate.add(Duration(days: i));
      final logs = await HiveService.getMedicationLogsForDate(date) ?? [];
      
      logs.add({
        'medicine_name': treatment.medicine.name,
        'medicine_type': treatment.medicine.type,
        'medicine_color': treatment.medicine.color,
        'dosage': treatment.medicine.specs.dosage,
        'unit': treatment.medicine.specs.unit,
        'is_taken': false,
      });

      await HiveService.saveMedicationLogsForDate(date, logs);
    }
  }
}
