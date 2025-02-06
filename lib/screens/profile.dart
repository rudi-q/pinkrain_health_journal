import 'package:flutter/material.dart';
import 'package:pillow/core/widgets/bottom_navigation.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool isReminderEnabled = true;
  bool isFillUpPillboxEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
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
            _buildHelpTile('Delete Account and All Data'),
            Spacer()
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: buildBottomNavigationBar(context: context, currentRoute: 'profile'),
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
    final bool isDelete = title=='Delete Account and All Data';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: TextStyle(
            fontSize: 16,
            color: isDelete? Colors.red : null,
          )
      ),
      trailing: isDelete ? null: Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
