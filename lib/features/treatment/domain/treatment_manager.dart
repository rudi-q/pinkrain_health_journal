import 'package:pillow/core/models/medicine_model.dart';

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

  static Treatment newTreatment({
    required name,
    required String type,
    required String color,
    required double dose,
    required String doseUnit,
    required String mealOption,
    required String? comment,
  }) {

    var medicine = Medicine(
        name: name,
        type: type,
        color: color
    );

    var specification = Specification(
        dosage: dose,
        unit: doseUnit,
        useCase: ''
    );

    medicine.addSpecification(specification);

    var treatmentPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 7)),
        mealOption: mealOption,
        timeOfDay: DateTime(2023, 1, 1, 11, 0)
    );

    return Treatment(
      medicine: medicine,
      treatmentPlan: treatmentPlan,
      notes: comment?? '',
    );
  }

  static List<Treatment> getSample(){

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
        timeOfDay: DateTime(2023, 1, 1, 11, 0)
    );
    newTreatment = Treatment(medicine: medicine, treatmentPlan: treatmentPlan);

    treatments.add(newTreatment);

    medicine = Medicine(name: 'Levocetirizine', type: 'pill');
    medicine.addSpecification(Specification(dosage: 20, unit: 'mg'));

    treatmentPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 1)),
        timeOfDay: DateTime(2023, 1, 1, 12, 0)
    );
    newTreatment = Treatment(medicine: medicine, treatmentPlan: treatmentPlan);

    treatments.add(newTreatment);

    medicine = Medicine(name: 'Aspirin', type: 'tablet');
    medicine.addSpecification(Specification(dosage: 20, unit:'mg'));

    treatmentPlan = TreatmentPlan(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 3)),
        timeOfDay: DateTime(2023, 1, 1, 23, 0)
    );
    newTreatment = Treatment(medicine: medicine, treatmentPlan: treatmentPlan);

    treatments.add(newTreatment);

    return treatments;
  }

  static TreatmentPlan getPlanByMedicineName(String medicineName) {
    return Treatment.getSample().firstWhere((t) => t.medicine.name == medicineName).treatmentPlan;
  }

  String timeOfDay(){
    return
        '${treatmentPlan.timeOfDay.hour.toString().padLeft(2, '0')}'
        ' : '
        '${treatmentPlan.timeOfDay.minute.toString().padLeft(2, '0')}'
    ;
  }

}






class TreatmentManager {
  final List<Treatment> _treatments = [];

  List<Treatment> get treatments => _treatments;
}