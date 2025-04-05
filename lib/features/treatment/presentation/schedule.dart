import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/treatment_manager.dart';

class ScheduleScreen extends StatefulWidget {
  final Treatment treatment;

  const ScheduleScreen({
    required this.treatment,
    super.key,
  });

  @override
  ScheduleScreenState createState() => ScheduleScreenState();
}

class ScheduleScreenState extends State<ScheduleScreen> {
  Map<String, String> doseTimes = {'Dose 1': '10:00'};
  String selectedReminder = 'at time of event';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Schedule'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              Text(
                'When do you want to take your medication?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: doseTimes.length,
                itemBuilder: (context, index) {
                  String doseKey = doseTimes.keys.elementAt(index);
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(doseKey),
                        Spacer(),
                        TextButton(
                          onPressed: () async {
                            TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                doseTimes[doseKey] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                          child: Text(doseTimes[doseKey]!),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    String newDose = 'Dose ${doseTimes.length + 1}';
                    doseTimes[newDose] = '10:00';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Add another dose time'),
              ),
              SizedBox(height: 40),
              Text(
                'Remind me',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedReminder,
                  items: [
                    'at time of event',
                    '5 minutes before',
                    '10 minutes before',
                    '15 minutes before',
                    '30 minutes before',
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedReminder = newValue;
                      });
                    }
                  },
                ),
              ),
              SizedBox(height: 40),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    // Parse the first dose time for the treatment plan
                    String firstDoseTime = doseTimes.values.first;
                    List<String> timeParts = firstDoseTime.split(':');
                    widget.treatment.treatmentPlan.timeOfDay = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      int.parse(timeParts[0]),
                      int.parse(timeParts[1]),
                    );
                    context.push('/duration', extra: widget.treatment);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: const Text('Continue'),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}