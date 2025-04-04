import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pillow/core/models/medicine_model.dart';
import 'package:pillow/features/treatment/data/treatment.dart';
import 'package:pillow/features/treatment/domain/treatment_manager.dart';

class OneTimeTakeScreen extends StatefulWidget {
  const OneTimeTakeScreen({super.key});

  @override
  State<OneTimeTakeScreen> createState() => _OneTimeTakeScreenState();
}

class _OneTimeTakeScreenState extends State<OneTimeTakeScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  String selectedType = 'Tablets';
  String selectedColor = 'White';
  String selectedUnit = 'mg';

  final Map<String, Color> colorMap = {
    'White': Colors.white,
    'Yellow': const Color(0xFFFFF3C4),
    'Pink': const Color(0xFFFFE4E8),
    'Blue': const Color(0xFFE3F2FD),
    'Red': const Color(0xFFFFE5E5),
  };

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    super.dispose();
  }

  Future<void> _saveOneTimeMedication() async {
    if (nameController.text.isEmpty || dosageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final medicine = Medicine(
      name: nameController.text,
      type: selectedType,
      color: selectedColor,
    );

    final dosage = double.tryParse(dosageController.text) ?? 1.0;
    medicine.addSpecification(
      Specification(
        dosage: dosage,
        unit: selectedUnit,
      ),
    );

    // Create a treatment plan for today only
    final now = DateTime.now();
    final treatmentPlan = TreatmentPlan(
      startDate: now,
      endDate: now,
      timeOfDay: now,
      frequency: const Duration(days: 1),
    );

    final treatment = Treatment(
      medicine: medicine,
      treatmentPlan: treatmentPlan,
    );

    // Save the one-time treatment
    final treatmentManager = TreatmentManager();
    await treatmentManager.saveTreatment(treatment);

    if (mounted) {
      context.pop(); // Go back to journal screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('One-time Medication'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dosageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: selectedUnit,
                    items: ['mg', 'ml', 'g']
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedUnit = value);
                      }
                    },
                    underline: const SizedBox(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Type', style: TextStyle(fontSize: 16)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Tablets', 'Capsules', 'Liquid', 'Injection']
                    .map((type) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: selectedType == type,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => selectedType = type);
                              }
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Color', style: TextStyle(fontSize: 16)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: colorMap.keys
                    .map((color) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(color),
                            selected: selectedColor == color,
                            backgroundColor: colorMap[color],
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => selectedColor = color);
                              }
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveOneTimeMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Add Medication'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
