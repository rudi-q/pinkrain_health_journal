import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/appbar.dart';
import '../../../features/journal/presentation/journal_notifier.dart';
import '../domain/treatment_manager.dart';

class DurationScreen extends ConsumerStatefulWidget {
  final Treatment treatment;

  const DurationScreen({
    super.key,
    required this.treatment,
  });

  @override
  ConsumerState<DurationScreen> createState() => DurationScreenState();
}

class DurationScreenState extends ConsumerState<DurationScreen> {
  final List<bool> selectedDays = List.generate(7, (index) => false);
  int selectedDuration = 5;
  DateTime startDate = DateTime.now().add(const Duration(days: 1));
  final TreatmentManager treatmentManager = TreatmentManager();

  List<Widget> _buildDayButtons() {
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return List.generate(7, (index) {
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedDays[index] = !selectedDays[index];
          });
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selectedDays[index] ? Colors.pink[100] : Colors.grey[200],
          ),
          child: Center(
            child: Text(
              days[index],
              style: TextStyle(
                color: selectedDays[index] ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Treatment Duration'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Center(
              child: SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.pink[100],
                        thickness: 3,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Divider(
                        color: Colors.pink[100],
                        thickness: 3,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Divider(
                        color: Colors.pink[100],
                        thickness: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Days Taken
            const Text(
              'Days taken',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildDayButtons(),
            ),
            const SizedBox(height: 30),
            // Start Field
            DropdownButtonFormField<String>(
              value: 'tomorrow',
              decoration: InputDecoration(
                labelText: 'Start',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                'today',
                'tomorrow',
                'next Monday',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  startDate = newValue == 'tomorrow'
                      ? DateTime.now().add(const Duration(days: 1))
                      : DateTime.now();
                });
              },
            ),
            const SizedBox(height: 20),
            // Duration Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      hintText: selectedDuration.toString(),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        selectedDuration =
                            int.tryParse(value) ?? selectedDuration;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'days',
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      'days',
                      'weeks',
                      'months',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      // No action needed
                    },
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Previous',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      widget.treatment.treatmentPlan.startDate = startDate;
                      widget.treatment.treatmentPlan.endDate =
                          startDate.add(Duration(days: selectedDuration));

                      await treatmentManager.saveTreatment(widget.treatment);

                      if (mounted) {
                        // Refresh the journal data for the current date
                        final selectedDate = ref.read(selectedDateProvider);
                        final pillIntakeNotifier = ref.read(pillIntakeProvider.notifier);
                        await pillIntakeNotifier.populateJournal(selectedDate);
                        
                        context.go('/journal');
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.pink[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
