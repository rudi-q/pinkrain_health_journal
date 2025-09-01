import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinkrain/core/util/helpers.dart';

import '../../../core/models/medicine_model.dart';
import '../../../core/theme/icons.dart';
import '../../../features/journal/presentation/journal_notifier.dart';
import '../data/treatment.dart';
import '../domain/treatment_manager.dart';

class EditTreatmentScreen extends ConsumerStatefulWidget {
  final Treatment treatment;
  const EditTreatmentScreen({super.key, required this.treatment});

  @override
  ConsumerState<EditTreatmentScreen> createState() => EditTreatmentScreenState();
}

class EditTreatmentScreenState extends ConsumerState<EditTreatmentScreen> {
  final TreatmentManager treatmentManager = TreatmentManager();

  late TextEditingController nameController;
  late TextEditingController doseController;
  late TextEditingController commentController;
  late String selectedTreatmentType;
  late String selectedColor;
  late String selectedMealOption;
  late String selectedDoseUnit;

  final Map<String, Color> colorMap = {
    'White': Colors.white,
    'Yellow': Color(0xFFFFF3C4), // Soft pastel yellow
    'Pink': Color(0xFFFFE4E8),   // Soft pastel pink
    'Blue': Color(0xFFE3F2FD),   // Soft pastel blue
    'Red': Color(0xFFFFE5E5),    // Soft pastel red
  };

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
              _buildTreatmentTypeOptions(),
              const SizedBox(height: 30),
              _buildColorOptions(),
              const SizedBox(height: 30),
              _buildNameField(),
              const SizedBox(height: 30),
              _buildDoseField(),
              const SizedBox(height: 30),
              _buildMealOptions(),
              const SizedBox(height: 30),
              _buildCommentField(),
              const SizedBox(height: 30),
              Center(
                child: _buildSaveButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentTypeOptions() {
    List<String> types = ['Tablet', 'Capsule', 'Drops', 'Cream', 'Spray', 'Injection'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Treatment Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: types.map((type) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildTreatmentTypeOption(type),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentTypeOption(String type) {
    final isSelected = selectedTreatmentType == type;
    return GestureDetector(
      onTap: () => setState(() => selectedTreatmentType = type),
      child: Column(
        children: [
          Container(
            key: ValueKey(selectedColor),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.pink[50] : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.pink[200]! : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: _futureBuildSvg(type),
          ),
          SizedBox(height: 5),
          Text(type,
              style: TextStyle(
                color: isSelected ? Colors.pink[400] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }

  Widget _buildColorOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['White', 'Yellow', 'Pink', 'Blue', 'Red']
                .map((color) => _buildColorOption(color))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorOption(String color) {
    final isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: EdgeInsets.only(right: 10),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colorMap[color] ?? Colors.grey[300],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(color,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Enter medicine name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoseField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dose',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: doseController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDoseUnit,
                    items: ['mg', 'g', 'ml'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedDoseUnit = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealOptions() {
    List<String> options = [
      'Before meal',
      'After meal',
      'With food',
      'Never mind'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meal Option',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: options.map((option) => _buildMealOption(option)).toList(),
        ),
      ],
    );
  }

  Widget _buildMealOption(String option) {
    final isSelected = selectedMealOption == option;
    return GestureDetector(
      onTap: () => setState(() => selectedMealOption = option),
      child: Column(
        children: [
          Container(
            key: ValueKey(selectedColor),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.pink[50] : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.pink[200]! : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: _futureBuildSvg(option.toLowerCase().replaceAll(' ', '-')),
          ),
          SizedBox(height: 5),
          Text(option,
              style: TextStyle(
                color: isSelected ? Colors.pink[400] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        TextField(
          controller: commentController,
          decoration: InputDecoration(
            hintText: 'Write your comment here',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_validateInput()) {
            try {
              // Create updated medicine
              final updatedMedicine = Medicine(
                name: nameController.text,
                type: selectedTreatmentType,
                color: selectedColor, // Store the color name, not the Color object string
              )..addSpecification(
                  Specification(
                    dosage: double.tryParse(doseController.text) ?? widget.treatment.medicine.specs.dosage,
                    unit: selectedDoseUnit,
                    useCase: widget.treatment.medicine.specs.useCase,
                  ),
                );

              // Create updated treatment plan preserving original fields
              final updatedTreatmentPlan = TreatmentPlan(
                startDate: widget.treatment.treatmentPlan.startDate,
                endDate: widget.treatment.treatmentPlan.endDate,
                timeOfDay: widget.treatment.treatmentPlan.timeOfDay,
                mealOption: selectedMealOption,
                instructions: widget.treatment.treatmentPlan.instructions,
                frequency: widget.treatment.treatmentPlan.frequency,
              );

              // Create updated treatment
              final updatedTreatment = Treatment(
                id: widget.treatment.id.isEmpty ? generateUniqueId() : widget.treatment.id, // Ensure ID is never empty
                medicine: updatedMedicine,
                treatmentPlan: updatedTreatmentPlan,
                notes: commentController.text,
              );

              // Debug info
              devPrint("Updating treatment - ID: ${widget.treatment.id}, Name: ${widget.treatment.medicine.name} → ${updatedTreatment.medicine.name}");
              devPrint("Treatment ID being used: ${updatedTreatment.id}");
              devPrint("Original dose: ${widget.treatment.medicine.specs.dosage} → New dose: ${updatedTreatment.medicine.specs.dosage}");
              // Update treatment in database
              await treatmentManager.updateTreatment(widget.treatment, updatedTreatment);

              // Directly clear ALL medication data caches to ensure refresh
              if (mounted) {
                try {
                  // Get the JournalLog instance from the pillIntakeProvider
                  final journalLog = ref.read(pillIntakeProvider.notifier).journalLog;

                  // Directly clear all cached medication logs
                  journalLog.clearAllCachedMedicationLogs();

                  // Force reload of today's data
                  final today = DateTime.now().normalize();
                  await journalLog.forceReloadMedicationLogs(today);

                  // Get the currently selected date from the provider
                  final selectedDate = ref.read(selectedDateProvider);

                  // If the selected date is different from today, reload that data too
                  if (selectedDate.day != today.day || 
                      selectedDate.month != today.month || 
                      selectedDate.year != today.year) {
                    devPrint("Also reloading data for selected date: ${selectedDate.toString()}");
                    await journalLog.forceReloadMedicationLogs(selectedDate);
                    await journalLog.saveMedicationLogs(selectedDate);
                  }

                  // Save the updated medication logs to ensure they're persisted
                  await journalLog.saveMedicationLogs(today);

                  devPrint("All medication caches cleared!");

                  // Force rebuild of UI state with the refreshed data
                  await ref.read(pillIntakeProvider.notifier).forceReloadMedicationData(selectedDate);

                  // Force UI rebuild through provider invalidation
                  ref.invalidate(pillIntakeProvider);
                  ref.invalidate(selectedDateProvider);

                  devPrint("All providers invalidated for complete UI refresh");
                } catch (e) {
                  devPrint("Error during complete refresh: $e");
                }

                // Show success message and pop
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Treatment updated successfully')),
                  );

                  // Return to previous screen
                  Navigator.of(context).pop(true);
                }
              }
            } catch (e) {
              // Show error message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating treatment: $e')),
                );
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFFD0FF),
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text('Save Changes', style: TextStyle(color: Colors.black)),
      ),
    );
  }

  bool _validateInput() {
    String errorMessage = '';

    if (nameController.text.isEmpty) {
      errorMessage += 'Please enter a name for the treatment.\n';
    }

    if (doseController.text.isEmpty) {
      errorMessage += 'Please enter a dose for the treatment.\n';
    } else {
      try {
        double.parse(doseController.text);
      } catch (e) {
        errorMessage += 'Please enter a valid number for the dose.\n';
      }
    }

    if (errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    }
    return true;
  }

  FutureBuilder<SvgPicture> _futureBuildSvg(String text) {
    return FutureBuilder<SvgPicture>(
      future: appSvgDynamicImage(
        fileName: text.toLowerCase(),
        size: 30,
        color: colorMap[selectedColor],
        useColorFilter: false
      ),
      builder: (context, snapshot) {
        return snapshot.data ??
            appVectorImage(
              fileName: text.toLowerCase(),
              size: 30,
              color: colorMap[selectedColor],
              useColorFilter: false
            );
      }
    );
  }
}
