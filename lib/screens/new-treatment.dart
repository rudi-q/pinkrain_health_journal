import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NewTreatmentScreen(),
    );
  }
}

class NewTreatmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'New treatment',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Treatment Type Options (Tablets, Capsule, etc.)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildPillTypeIcons(),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.pink[100], thickness: 3),
            const SizedBox(height: 20),
            // Color Options
            const Text(
              'Color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildColorOptions(),
            ),
            const SizedBox(height: 20),
            // Name TextField
            const Text(
              'Name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Paracetamol 500mg',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Dose and Unit Dropdown
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '0.5',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    underline: Container(),
                    items: ['mg', 'g', 'ml']
                        .map((unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    ))
                        .toList(),
                    onChanged: (value) {},
                    hint: const Text('mg'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Meal Option Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildMealOptions(),
            ),
            const SizedBox(height: 20),
            // Comment TextField
            TextField(
              decoration: InputDecoration(
                hintText: 'Write your comment here',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
            const Spacer(),
            // Continue Button
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[100],
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Pill Type Icons (Tablets, Capsule, etc.)
  List<Widget> _buildPillTypeIcons() {
    List<String> pillTypes = ['Tablets', 'Capsule', 'Drops', 'Cream', 'Spray'];
    return pillTypes.map((type) {
      return Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.pink[100],
            child: const Icon(Icons.medical_services_outlined),
          ),
          const SizedBox(height: 5),
          Text(type, style: const TextStyle(fontSize: 14)),
        ],
      );
    }).toList();
  }

  // Color Options
  List<Widget> _buildColorOptions() {
    List<Color> colors = [
      Colors.white,
      Colors.yellow,
      Colors.pink,
      Colors.blue,
      Colors.red,
      Colors.green,
    ];
    return colors.map((color) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: color,
      );
    }).toList();
  }

  // Meal Option Icons (Before meal, After meal, etc.)
  List<Widget> _buildMealOptions() {
    List<String> mealOptions = ['Before meal', 'After meal', 'With food', 'Nevermind'];
    return mealOptions.map((option) {
      return Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.pink[100],
            child: const Icon(Icons.medical_services_outlined),
          ),
          const SizedBox(height: 5),
          Text(option, style: const TextStyle(fontSize: 14)),
        ],
      );
    }).toList();
  }
}
