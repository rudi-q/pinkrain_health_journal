import 'package:flutter/material.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/treatment/data/treatment.dart';
import 'package:pillow/features/treatment/presentation/schedule.dart';

import '../../../core/navigation/router.dart';
import '../../../core/theme/icons.dart';
import '../domain/treatment_manager.dart';

class NewTreatmentScreen extends StatefulWidget {
  const NewTreatmentScreen({super.key});

  @override
  NewTreatmentScreenState createState() => NewTreatmentScreenState();
}

class NewTreatmentScreenState extends State<NewTreatmentScreen> {
  final TreatmentManager treatmentManager = TreatmentManager();
  
  String selectedTreatmentType = 'Tablets';
  String selectedColor = 'White';
  String selectedMealOption = 'Before meal';
  String selectedDoseUnit = 'mg';
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    doseController.dispose();
    commentController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('New treatment'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressBar(),
                SizedBox(height: 20),
                _buildTreatmentTypeOptions(),
                SizedBox(height: 30),
                _buildColorOptions(),
                SizedBox(height: 30),
                _buildNameField(),
                SizedBox(height: 30),
                _buildDoseField(),
                SizedBox(height: 30),
                _buildMealOptions(),
                SizedBox(height: 30),
                _buildCommentField(),
                SizedBox(height: 30),
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        Expanded(child: Container(height: 4, color: Colors.pink[100])),
        Expanded(child: Container(height: 4, color: Colors.grey[300])),
        Expanded(child: Container(height: 4, color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildTreatmentTypeOptions() {
    List<String> types = ['Tablets', 'Capsule', 'Drops', 'Cream', 'Spray'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: types.map((type) => _buildTreatmentTypeOption(type)).toList(),
    );
  }

  Widget _buildTreatmentTypeOption(String type) {
    return GestureDetector(
      onTap: () => setState(() => selectedTreatmentType = type),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: appImage('medicine', size: 30),
          ),
          SizedBox(height: 5),
          Text(type, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildColorOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'White', 'Yellow', 'Pink', 'Blue', 'Red'
            ].map((color) => _buildColorOption(color)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorOption(String color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: EdgeInsets.only(right: 10),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: _getColor(color),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
        ),
        child: Text(color),
      ),
    );
  }

  Color _getColor(String color) {
    switch (color) {
      case 'White': return Colors.white;
      case 'Yellow': return Colors.yellow[200]!;
      case 'Pink': return Colors.pink[100]!;
      case 'Blue': return Colors.blue[200]!;
      case 'Red': return Colors.red[300]!;
      default: return Colors.grey;
    }
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        Text('Dose', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    List<String> options = ['Before meal', 'After meal', 'With food', 'Never mind'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((option) => _buildMealOption(option)).toList(),
    );
  }

  Widget _buildMealOption(String option) {
    return GestureDetector(
      onTap: () => setState(() => selectedMealOption = option),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: appImage('medicine', size: 30),
          ),
          SizedBox(height: 5),
          Text(option, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCommentField() {
    return TextField(
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
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_validateInput()) {
            Treatment newTreatment = Treatment(
              name: nameController.text,
              type: selectedTreatmentType,
              color: selectedColor,
              dose: double.parse(doseController.text),
              doseUnit: selectedDoseUnit,
              mealOption: selectedMealOption,
              comment: commentController.text.isNotEmpty ? commentController.text : null,
            );
            
            // Navigate to the ScheduleScreen using GoRouter
            try {
              navigatorKey.currentState?.push(
                  MaterialPageRoute(builder: (context) => ScheduleScreen())
              );
            } on Exception catch (e) {
              'Error: Failed to navigate to ScheduleScreen: $e'.log();
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
        child: Text('Continue', style: TextStyle(color: Colors.black)),
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
        SnackBar(
          content: Text(errorMessage),
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
  
    return true;
  }
}
