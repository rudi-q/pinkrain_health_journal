import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillow/features/pillbox/data/pillbox_model.dart';
import 'package:pillow/features/pillbox/presentation/pillbox_notifier.dart';
import 'package:pillow/features/treatment/data/treatment.dart';
import 'package:pillow/features/treatment/domain/treatment_manager.dart';

import '../../../core/models/medicine_model.dart';
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

  void _showAddMedicineDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController unitController = TextEditingController();
    final TextEditingController useCaseController = TextEditingController();

    // Define initial values
    String initialMedicationType = 'Tablet';
    String initialColor = 'White';

    // Define validation error messages
    String? nameError;
    String? quantityError;
    String? unitError;
    String? useCaseError;

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
        // These variables will be properly tracked in the StatefulBuilder
        String selectedMedicationType = initialMedicationType;
        String selectedColor = initialColor;
        
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            // Validation functions
            void validateName() {
              setState(() {
                if (nameController.text.isEmpty) {
                  nameError = 'Medicine name is required';
                } else if (nameController.text.trim().isEmpty) {
                  nameError = 'Medicine name cannot be only whitespace';
                } else if (nameController.text.length < 2) {
                  nameError = 'Medicine name must be at least 2 characters';
                } else {
                  nameError = null;
                }
              });
            }

            void validateQuantity() {
              setState(() {
                if (quantityController.text.isEmpty) {
                  quantityError = 'Quantity is required';
                } else {
                  final quantity = int.tryParse(quantityController.text);
                  if (quantity == null) {
                    quantityError = 'Quantity must be a valid number';
                  } else if (quantity <= 0) {
                    quantityError = 'Quantity must be greater than zero';
                  } else if (quantity > 1000) {
                    quantityError = 'Quantity cannot exceed 1000';
                  } else {
                    quantityError = null;
                  }
                }
              });
            }

            void validateUnit() {
              setState(() {
                if (unitController.text.isNotEmpty && unitController.text.trim().isEmpty) {
                  unitError = 'Unit cannot be only whitespace';
                } else if (unitController.text.length > 10) {
                  unitError = 'Unit should be 10 characters or less';
                } else {
                  unitError = null;
                }
              });
            }

            void validateUseCase() {
              setState(() {
                if (useCaseController.text.isNotEmpty && useCaseController.text.trim().isEmpty) {
                  useCaseError = 'Use case cannot be only whitespace';
                } else if (useCaseController.text.length > 100) {
                  useCaseError = 'Use case should be 100 characters or less';
                } else {
                  useCaseError = null;
                }
              });
            }

            // Function to validate all fields
            bool validateAllFields() {
              validateName();
              validateQuantity();
              validateUnit();
              validateUseCase();
              
              return nameError == null && 
                     quantityError == null && 
                     unitError == null && 
                     useCaseError == null;
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 10),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        'Add New Medication',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.pink[400],
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Medication Name
                      TextField(
                        controller: nameController,
                        cursorColor: Colors.pink[400],
                        decoration: InputDecoration(
                          hintText: 'Medication Name',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(15),
                          errorText: nameError,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (_) => validateName(),
                      ),
                      const SizedBox(height: 20),

                      // Medication Type Label
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Medication Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.pink[400],
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Medication Type Selection
                      SizedBox(
                        height: 100,
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
                            final bool isSelected = selectedMedicationType == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedMedicationType = type;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Colors.pink[100]
                                            : Colors.grey[100],
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.pink.withValues(alpha: 77),
                                                  spreadRadius: 1,
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: futureBuildSvg(type, selectedColor, 40),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Outfit',
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.pink[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Color Label
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.pink[400],
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Color Selection
                      SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: colorMap.keys.map((color) {
                            final bool isSelected = selectedColor == color;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colorMap[color],
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.pink.withValues(alpha: 51),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            )
                                          ]
                                        : null,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.pink[300]!
                                          : Colors.grey[300]!,
                                      width: isSelected ? 1.5 : 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    color,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Outfit',
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.pink[400]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Quantity, Unit, Use Case fields
                      TextField(
                        controller: quantityController,
                        cursorColor: Colors.pink[400],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Quantity',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(15),
                          errorText: quantityError,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (_) => validateQuantity(),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: unitController,
                        cursorColor: Colors.pink[400],
                        decoration: InputDecoration(
                          hintText: 'Unit (e.g., mg, ml)',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(15),
                          errorText: unitError,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (_) => validateUnit(),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: useCaseController,
                        cursorColor: Colors.pink[400],
                        decoration: InputDecoration(
                          hintText: 'What is this medication for?',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(15),
                          errorText: useCaseError,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (_) => validateUseCase(),
                      ),
                      const SizedBox(height: 30),
                      
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink[100],
                              foregroundColor: Colors.pink[700],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              if (validateAllFields()) {
                                final newMedicine = Medicine(
                                  name: nameController.text.trim(),
                                  type: selectedMedicationType,
                                  color: selectedColor,
                                );
                                final quantity = int.parse(quantityController.text);

                                final specification = Specification(
                                  unit: unitController.text.isNotEmpty
                                      ? unitController.text.trim()
                                      : 'mg',
                                  useCase: useCaseController.text.trim(),
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
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    SnackBar(
                                      content: Text('Error adding medication: ${e.toString()}'),
                                      duration: const Duration(seconds: 3),
                                      backgroundColor: Colors.red[300],
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Add Medication',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
