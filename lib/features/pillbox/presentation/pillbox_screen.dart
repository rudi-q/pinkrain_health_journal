import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillow/core/theme/colors.dart';
import 'package:pillow/features/pillbox/data/pillbox_model.dart';
import 'package:pillow/features/pillbox/presentation/pillbox_notifier.dart';
import 'package:pillow/features/treatment/data/treatment.dart';
import 'package:pillow/features/treatment/domain/treatment_manager.dart';

import '../../../core/models/medicine_model.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/helpers.dart';
import '../../../core/widgets/appbar.dart';
import '../../../core/widgets/bottom_navigation.dart';

class PillboxScreen extends ConsumerWidget {
  const PillboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PillBoxManager.init(ref);

    return Scaffold(
      //backgroundColor: AppTokens.bgMuted,
      backgroundColor: Colors.white,
      appBar: buildAppBar('Pill Box'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicineDialog(context, ref),
        backgroundColor: AppTokens.bgPrimary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Bar
            // todo: Implement search functionality
            TextField(
              cursorColor: AppTokens.cursor,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTokens.borderLight, // stroke color
                    width: 1, // stroke width
                  ),
                  borderRadius: BorderRadius.circular(12), // rounded corners
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTokens.borderLight, // stroke when focused
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Find medication',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: AppTokens.bgMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Medication Cards - Using GridView with custom aspect ratio
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: _calculateCardAspectRatio(context),
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

  // Calculate aspect ratio based on content requirements
  double _calculateCardAspectRatio(BuildContext context) {
    // Base this on your content requirements:
    // - SVG icon: 60px
    // - Spacing: 10px
    // - Medicine name: ~24px (font size 18 + line height)
    // - Medicine type: ~20px (font size 16 + line height)
    // - Spacing from Spacer: variable
    // - Quantity: ~25px (font size 20 + line height)
    // - "pills left": ~20px (font size 16 + line height)
    // - Padding: 32px (16px top + 16px bottom)

    // Estimated content height: 60 + 10 + 24 + 20 + 25 + 20 + 32 = ~191px
    // Add some buffer for spacing: ~210px

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 50) / 2; // Account for padding and spacing
    final desiredCardHeight = 230.0;

    return cardWidth / desiredCardHeight;
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
          color: AppTokens.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: AppTokens.borderLight, // stroke color
              width: 1,),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                futureBuildSvg(med.type, med.color, 60),
                const SizedBox(height: 10),
                Text(
                  med.name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTokens.textPrimary),
                ),
                Text(
                  med.type,
                  style: const TextStyle(
                      fontSize: 16,
                      color: AppTokens.textSecondary),
                ),
                const Spacer(), // Back to spacer to push content to bottom
                Text(
                  '${medicineInventory.quantity}',
                  style: const TextStyle(
                      fontSize: 20,
                      color: AppTokens.textPrimary),
                ),
                Text(
                  'pills left',
                  style: const TextStyle(
                      fontSize: 16,
                      color: AppTokens.textSecondary),
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
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController unitController = TextEditingController();
    final TextEditingController useCaseController = TextEditingController();

    // Define initial values
    String initialMedicationType = 'Tablet';
    String initialColor = 'White';

    /* IconData getMedicationTypeIcon(String type) {
      switch (type.toLowerCase()) {
        case 'tablet':
          return Icons.local_pharmacy;
        case 'capsule':
          return Icons.medication;
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
    }*/

    final Map<String, Color> colorMap = {
      'White': Colors.white,
      'Yellow': AppColors.pastelYellow,
      'Pink': AppColors.pink100,
      'Blue': AppColors.pastelBlue,
      'Red': AppColors.pastelRed,
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
                          fontWeight: FontWeight.w800,
                          color: AppTokens.textPrimary,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Medication Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTokens.textPrimary,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Medication Name
                      TextField(
                        controller: nameController,
                        cursorColor: AppTokens.cursor,
                        decoration: InputDecoration(
                          hintText: 'Paracetamol',
                          hintStyle: TextStyle(
                              color: AppTokens.textPlaceholder
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(15),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Medication Type Label
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Medication Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTokens.textPrimary,
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
                                            ? AppTokens.buttonPrimaryBg
                                            : AppTokens.buttonSecondaryBg,
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
                                            ? AppTokens.textPrimary
                                            : AppTokens.textSecondary,
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
                            fontWeight: FontWeight.bold,
                            color: AppTokens.textPrimary,
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
                                      horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorMap[color],
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTokens.borderStrong!
                                          : AppTokens.borderLight!,
                                    ),
                                  ),
                                child: Center(
                                  child: Text(
                                    color,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Outfit',
                                    ),
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
                        ),
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
                        ),
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
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppTokens.textSecondary,
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTokens.buttonPrimaryBg,
                                foregroundColor: AppTokens.textPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                if (nameController.text.isNotEmpty &&
                                    quantityController.text.isNotEmpty) {
                                  final newMedicine = Medicine(
                                    name: nameController.text,
                                    type: selectedMedicationType,
                                    color: selectedColor,
                                  );
                                  final quantity = int.tryParse(quantityController.text) ?? 0;

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