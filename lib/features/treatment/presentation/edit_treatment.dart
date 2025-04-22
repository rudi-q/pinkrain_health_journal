import 'package:flutter/material.dart';
import '../../../core/models/medicine_model.dart';
import '../domain/treatment_manager.dart';
import '../data/treatment.dart'; // Import for TreatmentPlan

class EditTreatmentScreen extends StatefulWidget {
  final Treatment treatment;
  const EditTreatmentScreen({super.key, required this.treatment});

  @override
  EditTreatmentScreenState createState() => EditTreatmentScreenState();
}

class EditTreatmentScreenState extends State<EditTreatmentScreen> {
  final TreatmentManager treatmentManager = TreatmentManager();

  late TextEditingController nameController;
  late TextEditingController doseController;
  late TextEditingController commentController;
  late String selectedTreatmentType;
  late String selectedColor;
  late String selectedMealOption;
  late String selectedDoseUnit;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.treatment.medicine.name);
    doseController = TextEditingController(text: widget.treatment.medicine.specs.dosage.toString());
    commentController = TextEditingController(text: widget.treatment.notes);
    selectedTreatmentType = widget.treatment.medicine.type;
    selectedColor = widget.treatment.medicine.color;
    selectedMealOption = widget.treatment.treatmentPlan.mealOption;
    selectedDoseUnit = widget.treatment.medicine.specs.unit;
  }

  @override
  void dispose() {
    nameController.dispose();
    doseController.dispose();
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Treatment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: doseController,
                decoration: const InputDecoration(labelText: 'Dosage'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'Comments'),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    // Preserve original fields and update only the edited ones
                    final updatedMedicine = Medicine(
                      name: nameController.text, // Updated
                      type: selectedTreatmentType, // Updated from state
                      color: selectedColor,       // Updated from state
                    )..addSpecification(
                        Specification(
                          dosage: double.tryParse(doseController.text) ?? widget.treatment.medicine.specs.dosage, // Updated or keep original
                          unit: selectedDoseUnit, // Updated from state
                          useCase: widget.treatment.medicine.specs.useCase, // Preserve original
                        ),
                      );

                    // Rebuild TreatmentPlan preserving original non-editable fields
                    final updatedTreatmentPlan = TreatmentPlan(
                      startDate: widget.treatment.treatmentPlan.startDate, // Preserve original
                      endDate: widget.treatment.treatmentPlan.endDate,     // Preserve original
                      timeOfDay: widget.treatment.treatmentPlan.timeOfDay, // Preserve original
                      mealOption: selectedMealOption, // Updated from state
                      instructions: widget.treatment.treatmentPlan.instructions, // Preserve original
                      frequency: widget.treatment.treatmentPlan.frequency,     // Preserve original
                    );

                    final updatedTreatment = Treatment(
                      medicine: updatedMedicine,
                      treatmentPlan: updatedTreatmentPlan,
                      notes: commentController.text, // Updated
                    );

                    await treatmentManager.updateTreatment(widget.treatment, updatedTreatment);
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
