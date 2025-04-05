import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

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

  final Map<String, Color> colorMap = {
    'White': Colors.white,
    'Yellow': Color(0xFFFFF3C4), // Soft pastel yellow
    'Pink': Color(0xFFFFE4E8),   // Soft pastel pink
    'Blue': Color(0xFFE3F2FD),   // Soft pastel blue
    'Red': Color(0xFFFFE5E5),    // Soft pastel red
  };

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('New treatment'),
        backgroundColor: Colors.transparent,
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
    List<String> types = ['Tablet', 'Capsule', 'Drops', 'Cream', 'Spray', 'Injection'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: types.map((type) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: _buildTreatmentTypeOption(type),
        )).toList(),
      ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((option) => _buildMealOption(option)).toList(),
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
            child: _futureBuildSvg(option.toLowerCase().replaceAll(' ', '-')/*, size: 30, useColorFilter: false*/),
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
            final treatment = Treatment.newTreatment(
              name: nameController.text,
              type: selectedTreatmentType,
              color: colorMap[selectedColor]?.toString() ?? Colors.white.toString(),
              dose: double.parse(doseController.text),
              doseUnit: selectedDoseUnit,
              mealOption: selectedMealOption,
              comment: commentController.text.isNotEmpty ? commentController.text : '',
            );
            context.push('/schedule', extra: treatment);
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
