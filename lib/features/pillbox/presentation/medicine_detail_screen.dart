import 'package:flutter/material.dart';
import 'package:pillow/core/models/medicine_model.dart';
import 'package:pillow/features/treatment/data/treatment.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/icons.dart';
import '../../treatment/domain/treatment_manager.dart';

class MedicineDetailScreen extends StatefulWidget {
  final MedicineInventory inventory;

  const MedicineDetailScreen({
    super.key,
    required this.inventory
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {

  late Medicine medicine;
  late TreatmentPlan medicinePlan;

  @override
  void initState() {
    medicine = widget.inventory.medicine;
    medicinePlan = Treatment.getPlanByMedicineName(medicine.name);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicine.name,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${medicine.type} • ${medicine.specs.dosage}',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  appImage('medicine', size: 40),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicinePlan.mealOption,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        medicinePlan.instructions,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  appImage('medicine', size: 40),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.inventory.quantity}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'pills left',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      _showFillUpDialog(context);
                    },
                    child: Text(
                      'fill-up >',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reduces stomach acid and treats conditions like GERD, ulcers, and acid reflux.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        // Launch Wikipedia page for the medicine
                        final url = Uri.parse('https://en.wikipedia.org/wiki/${medicine.name}');
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      child: Text(
                        'Wikipedia >',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      medicinePlan.isOnGoing() ? 'Ongoing treatment' : 'No ongoing treatment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                        '${medicinePlan.intakeFrequency()}'
                        ' - 1 pill (20 mg)\n'
                        '${medicinePlan.pillStatus(widget.inventory.quantity)}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    //Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Implement remove from Pillbox functionality
                  },
                  child: Text(
                    'Remove from Pillbox',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

void _showFillUpDialog(BuildContext context) {
  int pillsToAdd = 0;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Fill Up Pills'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many pills would you like to add?'),
            SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                pillsToAdd = int.tryParse(value) ?? 0;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter number of pills',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              if (pillsToAdd > 0) {

                final pillsLeft = widget.inventory.quantity;
                final newPillCount = pillsLeft + pillsToAdd;
                setState(() {
                  widget.inventory.updateQuantity(newPillCount);
                });

                // Close the dialog
                Navigator.of(context).pop();

                // Show a confirmation snack bar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added $pillsToAdd pills. New total: $newPillCount'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
}