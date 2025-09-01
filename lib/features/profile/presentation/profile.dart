import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinkrain/core/widgets/bottom_navigation.dart';
import 'package:pinkrain/core/widgets/components.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';


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
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/wellness'),
        ),
      ),
      body: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name TextField
              Text(
                'Name',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
             /* SizedBox(height: 10),*/

              nameField(),

             /* SizedBox(height: 30),*/
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
           /*   _buildSwitchTile('Fill-up Pillbox', isFillUpPillboxEnabled, (value) {
                setState(() {
                  isFillUpPillboxEnabled = value;
                });
              }),

              // Notification Sound Selection
              if (isReminderEnabled) ...[
                SizedBox(height: 20),
                Text(
                  'Notification Sound',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: _notificationSounds.map((sound) {
                      final isSelected = _selectedSound?.name == sound.name;
                      return ListTile(
                        title: Text(sound.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Preview button
                            if (sound.assetPath.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.play_circle_outline),
                                onPressed: () => _playSound(sound),
                              ),
                            // Selection indicator
                            Radio<String>(
                              value: sound.name,
                              groupValue: _selectedSound?.name,
                              onChanged: (value) {
                                _saveSelectedSound(sound);
                              },
                              activeColor: Colors.pink[300],
                            ),
                          ],
                        ),
                        onTap: () {
                          _saveSelectedSound(sound);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],*/
              SizedBox(height: 30),
              // Help Section
              Text(
                'Help',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Get in touch', style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.help_outline_rounded),
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'reach@rudi.engineer',
                    query: 'subject=PinkRain%20App%20Support',
                  );

                  try {
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not launch email client')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error launching email: $e')),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  const inviteUri = 'https://tally.so/r/3EYA6l';
                  try {
                    await SharePlus.instance.share(ShareParams(
                        previewThumbnail: XFile('assets/images/splash-icon.png', name: 'PinkRain'),
                        text: "I've been using PinkRain to track my wellness and journaling."
                            "\nIt's actually really helpful! Check it out! \n$inviteUri\n"
                            "\nBtw no worries, it's privacy first so all data is stored locally on your device and never leaves your phone.",
                        subject: 'You gotta check out PinkRain',
                    ));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sending invite: $e')),
                    );
                  }
                },
                title: Text('Invite a Friend or Family Member', style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.share_outlined),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  final Uri privacyUri = Uri.parse('https://doubl.one/pinkrain/privacy.html');
                  try {
                    if (await canLaunchUrl(privacyUri)) {
                      await launchUrl(privacyUri, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not launch privacy policy')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error launching privacy policy: $e')),
                    );
                  }
                },
                title: Text('Privacy Policy', style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.privacy_tip_outlined),
              ),
              _buildHelpTile('Delete Account and All Data'),
              Spacer(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "🔒 Your privacy is important to us; all your data remains securely stored on your device, never sent to our servers. 🕊️",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: Colors.black87
                    ),
                  ),
                ),
              ),
              Spacer()
            ],
          ),
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
        activeThumbColor: Colors.pink[100],
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
