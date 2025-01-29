import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DurationScreen(),
    );
  }
}

class DurationScreen extends StatefulWidget {
  @override
  _DurationScreenState createState() => _DurationScreenState();
}

class _DurationScreenState extends State<DurationScreen> {
  String selectedStart = 'tomorrow';
  String selectedDurationUnit = 'days';
  int selectedDuration = 5;

  List<bool> selectedDays = [true, true, true, true, true, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () {},
        ),
        title: Text(
          'Duration',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Center(
              child: Container(
                width: 100,
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.pink[100],
                        thickness: 3,
                      ),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Divider(
                        color: Colors.pink[100],
                        thickness: 3,
                      ),
                    ),
                    SizedBox(width: 5),
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
            SizedBox(height: 30),
            // Days Taken
            Text(
              'Days taken',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildDayButtons(),
            ),
            SizedBox(height: 30),
            // Start Field
            DropdownButtonFormField<String>(
              value: selectedStart,
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
                  selectedStart = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
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
                        selectedDuration = int.parse(value);
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDurationUnit,
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
                      setState(() {
                        selectedDurationUnit = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            Spacer(),
            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Previous',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.pink[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
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

  // Function to create day buttons (M, T, W, etc.)
  List<Widget> _buildDayButtons() {
    List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return List.generate(days.length, (index) {
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedDays[index] = !selectedDays[index];
          });
        },
        child: CircleAvatar(
          radius: 20,
          backgroundColor:
          selectedDays[index] ? Colors.grey[800] : Colors.grey[300],
          child: Text(
            days[index],
            style: TextStyle(
              color: selectedDays[index] ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    });
  }
}
