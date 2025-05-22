import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillow/features/pillbox/data/pillbox_model.dart';
import 'package:pillow/features/pillbox/presentation/pillbox_notifier.dart';
import 'package:pillow/features/treatment/data/treatment.dart';
import 'package:pillow/features/treatment/domain/treatment_manager.dart';

import '../../../core/models/medicine_model.dart';
import '../../../core/theme/icons.dart';
import '../../../core/util/helpers.dart';
import '../../../core/widgets/appbar.dart';
import '../../../core/widgets/bottom_navigation.dart';

class PillboxScreen extends ConsumerWidget {
  const PillboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PillBoxManager.init(ref);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildAppBar('Pill Box'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicineDialog(context, ref),
        backgroundColor: Colors.pink[300],
        tooltip: 'Add medication',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Bar
            // todo: Implement search functionality
            TextField(
              cursorColor: Colors.grey,
              decoration: InputDecoration(
                hintText: 'Find medication',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.pink.withAlpha(13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Medication Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: _buildMedicationCards(ref, context),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
      buildBottomNavigationBar(context: context, currentRoute: 'pillbox'),
    );
  }

  // Build Medication Cards
  List<Widget> _buildMedicationCards(WidgetRef ref, BuildContext context) {
    final IPillBox pillBox = ref.watch(pillBoxProvider);
    final List<Treatment> sampleTreatments = Treatment.getSampleForPillBox();

    return pillBox.pillStock.map((medicineInventory) {
      Medicine med = medicineInventory.medicine;
      return GestureDetector(
        onTap: () {
          // Find treatment plan for this medicine
          sampleTreatments.firstWhere(
                (t) => t.medicine.name == med.name,
            orElse: () => Treatment(
              medicine: med,
              treatmentPlan: TreatmentPlan(
                startDate: DateTime.now(),
                endDate: DateTime.now().add(const Duration(days: 30)),
                timeOfDay: DateTime(2023, 1, 1, 12, 0),
                mealOption: 'Take as needed',
                instructions: 'Consult your doctor for specific instructions',
                frequency: const Duration(days: 1),
              ),
            ),
          );
          context.push('/medicine_detail/${medicineInventory.quantity}', extra: medicineInventory);
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                futureBuildSvg(med.type, med.color, 60),
                const SizedBox(height: 10),
                Text(
                  med.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  med.type,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const Spacer(),
                Text(
                  '${medicineInventory.quantity} pills left',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // todo: Improve medication form with more detailed information and validation
  void _showAddMedicineDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final useCaseController = TextEditingController();

    String selectedMedicationType = 'Tablet';
    String selectedColor = 'White';

    // Helper method to get icon for medication type
    IconData getMedicationTypeIcon(String type) {
      switch (type.toLowerCase()) {
        case 'tablet':
          return Icons.crop_square_rounded;
        case 'capsule':
          return Icons.panorama_fish_eye;
        case 'drops':
          return Icons.opacity;
        case 'cream':
          return Icons.spa;
        case 'spray':
          return Icons.shower;
        case 'injection':
          return Icons.vaccines;
        default:
          return Icons.medication;
      }
    }

    final Map<String, Color> colorMap = {
      'White': Colors.white,
      'Yellow': const Color(0xFFFFF3C4),
      'Pink': const Color(0xFFFFE4E8),
      'Blue': const Color(0xFFE3F2FD),
      'Red': const Color(0xFFFFE5E5),
    };

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(
                'Add New Medication',
                style: TextStyle(
                    color: Colors.pink[700], fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.pink[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.pink[200]!, width: 1.5),
              ),

              // ----------- FIX: give dialog a finite width -------------
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        cursorColor: Colors.pink[400],
                        decoration: _inputDecoration(
                            label: 'Medication Name', context: context),
                      ),
                      const SizedBox(height: 15),

                      // Medication Type Selection
                      _sectionLabel('Medication Type', context),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            'Tablet',
                            'Capsule',
                            'Drops',
                            'Cream',
                            'Spray',
                            'Injection'
                          ].map((type) {
                            final bool isSelected =
                                selectedMedicationType == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => selectedMedicationType = type);
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Colors.pink[50]
                                            : Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.pink[200]!
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        getMedicationTypeIcon(type),
                                        color: isSelected
                                            ? Colors.pink[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.pink[400]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Color Selection
                      _sectionLabel('Color', context),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: colorMap.keys.map((color) {
                            final bool isSelected = selectedColor == color;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedColor = color),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colorMap[color],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.pink[300]!
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    color,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: quantityController,
                        cursorColor: Colors.pink[400],
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                            label: 'Quantity', context: context),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: unitController,
                        cursorColor: Colors.pink[400],
                        decoration:
                        _inputDecoration(label: 'Unit', context: context),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: useCaseController,
                        cursorColor: Colors.pink[400],
                        decoration: _inputDecoration(
                            label: 'Use Case', context: context),
                      ),
                    ],
                  ),
                ),
              ),
              // ----------- end FIX -------------------------------------

              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.pink[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        quantityController.text.isNotEmpty) {
                      final newMedicine = Medicine(
                        name: nameController.text,
                        type: selectedMedicationType,
                        color: selectedColor,
                      );
                      final quantity =
                          int.tryParse(quantityController.text) ?? 0;

                      final specification = Specification(
                        unit: unitController.text.isNotEmpty
                            ? unitController.text
                            : 'mg',
                        useCase: useCaseController.text,
                      );
                      newMedicine.addSpecification(specification);

                      try {
                        final notifier = ref.read(pillBoxProvider.notifier);
                        notifier.addMedicine(newMedicine, quantity);
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${newMedicine.name} added to pillbox'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.pink[300],
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content:
                            Text('Error adding medication: ${e.toString()}'),
                            duration: const Duration(seconds: 3),
                            backgroundColor: Colors.red[300],
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- helpers -------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required BuildContext context,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.pink[400]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.pink[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.pink[400]!),
      ),
    );
  }

  Widget _sectionLabel(String text, BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.pink[400],
    ),
  );
}
