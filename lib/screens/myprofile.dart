import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isReminderEnabled = true;
  bool isFillUpPillboxEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Heading
            Text(
              "Profile",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            // Name TextField
            Text(
              'Name',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Rudi',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 30),
            // Notifications Section
            Text(
              'Notifications',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 20),
            _buildSwitchTile('Reminder', isReminderEnabled, (value) {
              setState(() {
                isReminderEnabled = value;
              });
            }),
            _buildSwitchTile('Fill-up Pillbox', isFillUpPillboxEnabled, (value) {
              setState(() {
                isFillUpPillboxEnabled = value;
              });
            }),
            SizedBox(height: 30),
            // Help Section
            Text(
              'Help',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 20),
            _buildHelpTile('Get in touch'),
            _buildHelpTile('Privacy Policy'),
            SizedBox(height: 30),
            // Delete Account Button
            Center(
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  'Delete account',
                  style: TextStyle(fontSize: 16),
                ),
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
              _buildBottomNavItem(Icons.lock_outline, 'Pillbox', false),
              _buildBottomNavItem(Icons.person_outline, 'Profile', true),
            ],
          ),
        ),
      ),
    );
  }

  // Switch Tile for Notifications
  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.pink[100],
      ),
    );
  }

  // Help Tile (Get in Touch, Privacy Policy)
  Widget _buildHelpTile(String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.chevron_right),
      onTap: () {},
    );
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
