import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicineForm extends StatefulWidget {

  final SupabaseClient client;

  const MedicineForm({super.key, required this.client});

 @override
  _MedicineFormState createState() => _MedicineFormState();

}

class _MedicineFormState extends State<MedicineForm> {
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  Future<void> _saveMedicine() async {
    if (_formKey.currentState?.validate() ?? false) {
      final response = await widget.client
          .from('medications')
          .insert({
        'medication_name': _medicineNameController.text,
        'dosage': _dosageController.text,
        'frequency_per_day': int.tryParse(_frequencyController.text),
        'start_date': _startDateController.text,
        'end_date': _endDateController.text,
        'created_at': DateTime.now().toIso8601String(),
          });

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add medicine: ${response.error?.message}')),
        );
      }
    }
    else{
      debugPrint("Input isn't valid");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _medicineNameController,
            decoration: const InputDecoration(labelText: 'Medicine Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter medicine name';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _dosageController,
            decoration: const InputDecoration(labelText: 'Dosage'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter dosage';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _frequencyController,
            decoration: const InputDecoration(labelText: 'Frequency per Day'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter frequency per day';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _startDateController,
            decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)'),
            keyboardType: TextInputType.datetime,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter start date';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _endDateController,
            decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)'),
            keyboardType: TextInputType.datetime,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter end date';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveMedicine,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}