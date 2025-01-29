import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFBFBFB),
          //title:;
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Selector Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (index) {
                      return Padding(
                        padding: const EdgeInsets.all(18),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: index == 5
                              ? const Color(0xFF2D2D2D)
                              : const Color(0xFFFBFBFB),
                          child: Text(
                            (7 + index).toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: index == 5 ? const Color(0xFFFBFBFB) : const Color(0xFF2D2D2D),
                              fontSize: 15,
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w400,
                              height: 0.10,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              // 'Today' Heading
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  "Today",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    height: 0,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
              // Morning Section
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: ListTile(
                  leading: Icon(Icons.wb_sunny_outlined),
                  title: Text(
                    'Morning',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2D2D2D),
                      height: 0,
                    ),
                  ),
                ),
              ),
              _buildPillCard('Ritalin', '20 mg', '10:00'),
              _buildPillCard('Levocetirizine', '2 pills', '11:00'),
              // Evening Section
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: ListTile(
                  leading: Icon(Icons.nights_stay_outlined),
                  title: Text(
                    'Evening',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2D2D2D),
                      height: 0,
                    ),
                  ),
                ),
              ),
              _buildPillCard('Valdoxan', '20 mg', '22:30'),
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
                _buildBottomNavItem(
                    Icons.book_outlined,
                    'Journal',
                    true
                ),
                _buildBottomNavItem(Icons.lock_outline, 'Pillbox', false),
                _buildBottomNavItem(Icons.person_outline, 'Profile', false),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0x66FFD0FF),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFFFD0FF)),
            borderRadius: BorderRadius.circular(360),
          ),
          onPressed: () {
            _showAddPopup(context);
          },
          child: const Icon(Icons.add, color: Colors.black),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // Function to show the custom popup dialog
  void _showAddPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'What do you want to add?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                // Option 1: New Treatment
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.medical_services_outlined, size: 24),
                  ),
                  title: const Text(
                    'New treatment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    // Handle 'New Treatment' logic here
                  },
                ),
                const Divider(),
                // Option 2: One-time Take
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.medical_services_outlined, size: 24),
                  ),
                  title: const Text(
                    'One-time take',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    // Handle 'One-time Take' logic here
                  },
                ),
                const Divider(),
                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // Helper function to create a card for each pill entry
  Widget _buildPillCard(String name, String dosage, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.medical_services_outlined),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D2D2D)
                    ),
                  ),
                  Text(
                    dosage,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0x662D2D2D),
                        fontWeight: FontWeight.w400
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(time, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  // Helper function to create bottom nav items
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
