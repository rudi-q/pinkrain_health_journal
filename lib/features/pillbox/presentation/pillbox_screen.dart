import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillow/features/pillbox/data/pillbox_model.dart';
import 'package:pillow/features/pillbox/presentation/pillbox_notifier.dart';

import '../../../core/models/medicine_model.dart';
import '../../../core/theme/icons.dart';
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
      appBar: buildAppBar('Pill Box', actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              _showAddMedicineDialog(context, ref);
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add meds',
              style: TextStyle(color: Colors.white),
            ),
          ),
        )
      ]),
      body: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                cursorColor: Colors.grey,
                decoration: InputDecoration(
                  hintText: 'Find medication',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.pink.withValues(alpha: 0.05),
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
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: buildBottomNavigationBar(context: context, currentRoute: 'pillbox'),
    );
  }

  // Build Medication Cards
  List<Widget> _buildMedicationCards(WidgetRef ref, BuildContext context) {
    final IPillBox pillBox = ref.watch(pillBoxProvider);
  
    return pillBox.pillStock.map((medicineInventory) {
      Medicine med = medicineInventory.medicine;
      return GestureDetector(
        onTap: () {
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
                appImage('medicine', size: 40),
                const SizedBox(height: 10),
                Text(
                  med.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(med.type,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const Spacer(),
                Text(
                  '${medicineInventory.quantity} pills left',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
void _showAddMedicineDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final typeController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();
  final useCaseController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add New Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Medication Name'),
              ),
              TextField(
                controller: typeController,
                decoration: InputDecoration(labelText: 'Medication Type'),
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration: InputDecoration(labelText: 'Unit'),
              ),
              TextField(
                controller: useCaseController,
                decoration: InputDecoration(labelText: 'Use Case'),
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  typeController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty) {
                final newMedicine = Medicine(
                  name: nameController.text,
                  type: typeController.text,
                );
                final quantity = int.tryParse(quantityController.text) ?? 0;

                if(unitController.text.isNotEmpty &&
                 useCaseController.text.isNotEmpty
                ) {
                  final specification = Specification(unit: unitController.text, useCase: useCaseController.text);
                  newMedicine.addSpecification(specification);
                }
                
                PillBoxManager.addMedicine(
                  medicine: newMedicine,
                  quantity: quantity,
                );

                
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}
}
