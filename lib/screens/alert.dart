import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popup Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _showAddPopup(context);
          },
          child: const Text('Show Popup'),
        ),
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
}
