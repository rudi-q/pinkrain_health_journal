import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/presentation/journal_medication_notifier.dart';
import 'package:pinkrain/features/treatment/services/medication_notification_service.dart';

/// A widget that wraps the Journal screen to handle medication notifications
/// This widget checks for untaken medications and shows notifications
/// without modifying the existing Journal screen code
class MedicationNotificationWidget extends ConsumerStatefulWidget {
  final Widget child;

  const MedicationNotificationWidget({
    required this.child,
    super.key,
  });

  @override
  ConsumerState<MedicationNotificationWidget> createState() =>
      _MedicationNotificationWidgetState();
}

class _MedicationNotificationWidgetState
    extends ConsumerState<MedicationNotificationWidget> {
  final _notificationService = MedicationNotificationService();
  bool _hasCheckedPermissions = false;

  @override
  void initState() {
    super.initState();

    // Initialize the notification service
    _notificationService.initialize().then((_) {
      _checkNotifications();
    });
  }

  Future<void> _checkNotifications() async {
    // Check if notifications are enabled
    if (!_hasCheckedPermissions) {
      final bool notificationsEnabled =
          await _notificationService.areNotificationsEnabled();

      if (!notificationsEnabled) {
        // Check if permission is permanently denied
        final status = await Permission.notification.status;
        
        // Only show the settings dialog if permission is permanently denied
        if (status.isPermanentlyDenied && mounted) {
          _showOpenSettingsDialog();
        } else {
          // Directly request permission without showing a custom dialog first
          await _notificationService.requestNotificationPermissions();
          
          // Check if permission was granted
          final permissionGranted = await _notificationService.areNotificationsEnabled();
          
          // If permission was denied and is now permanently denied, show settings dialog
          if (!permissionGranted) {
            final newStatus = await Permission.notification.status;
            if (newStatus.isPermanentlyDenied && mounted) {
              _showOpenSettingsDialog();
            }
          }
        }
      } else {
        devPrint('🔔 Notifications are already enabled');
      }

      _hasCheckedPermissions = true;
    }

    // Check for untaken medications
    ref
        .read(journalMedicationNotifierProvider.notifier)
        .checkUntakenMedications();
  }
  
  void _showOpenSettingsDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notifications Disabled'),
          content: const Text(
            'Notifications are required for medication reminders. '
            'Please enable notifications in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Open app settings
                await openAppSettings();
                
                // Wait a bit for the user to potentially change settings
                await Future.delayed(const Duration(seconds: 5));
                
                // Check if permissions were granted
                if (mounted) {
                  final bool permissionGranted = 
                      await _notificationService.areNotificationsEnabled();
                  
                  if (permissionGranted) {
                    devPrint('✅ Notification permission granted from settings');
                    
                    // Now check for untaken medications
                    ref
                        .read(journalMedicationNotifierProvider.notifier)
                        .checkUntakenMedications();
                  }
                }
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the medication notifier for changes
    ref.listen(journalMedicationNotifierProvider, (previous, next) {
      // When untaken medications are detected, show notifications
      if (next.untakenMedications.isNotEmpty) {
        _notificationService
            .showUntakenMedicationNotifications(next.untakenMedications);
      }
    });

    // Return the child widget unchanged
    return widget.child;
  }
}
