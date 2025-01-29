import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PillboxScreen(),
    );
  }
}

class PillboxScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pillbox',
          style: TextStyle(color: Colors.black, fontSize: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add meds',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Find medication',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
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
                children: _buildMedicationCards(),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavItem(Icons.book_outlined, 'Journal', false),
              _buildBottomNavItem(Icons.lock_outline, 'Pillbox', true),
              _buildBottomNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  // Build Medication Cards
  List<Widget> _buildMedicationCards() {
    List<Map<String, String>> medications = [
      {'name': 'Ritalin', 'type': 'ADHD medication', 'pills': '180'},
      {'name': 'Levocetirizine', 'type': 'Antihistamine', 'pills': '63'},
      {'name': 'Valdoxan', 'type': 'Depression, GAD', 'pills': '42'},
    ];

    return medications.map((med) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.medical_services_outlined, size: 30),
              ),
              const SizedBox(height: 10),
              Text(
                med['name']!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(med['type']!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const Spacer(),
              Text(
                '${med['pills']} pills left',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // Bottom Navigation Item
  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.pink[100] : Colors.black,
        ),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.pink[100] : Colors.black,
          ),
        ),
      ],
    );
  }
}
