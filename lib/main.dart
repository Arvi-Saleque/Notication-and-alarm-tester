import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'notification_service.dart';
import 'permissions_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Tester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NotificationTestPage(),
    );
  }
}

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  final TextEditingController titleController =
      TextEditingController(text: 'Test Notification');
  final TextEditingController messageController =
      TextEditingController(text: 'This is a scheduled notification!');

  @override
  void initState() {
    super.initState();
    // Check permissions on startup
    Future.delayed(Duration.zero, () {
      _checkAndRequestInitialPermissions();
    });
  }

  Future<void> _checkAndRequestInitialPermissions() async {
    // Check if critical permissions are missing
    final notificationStatus = await Permission.notification.status;
    final batteryOptStatus = await Permission.ignoreBatteryOptimizations.status;
    
    if (!notificationStatus.isGranted || !batteryOptStatus.isGranted) {
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('Setup Required'),
              ],
            ),
            content: const Text(
              'This app needs some permissions to work properly:\n\n'
              '• Notifications\n'
              '• Schedule Exact Alarms\n'
              '• Battery Optimization (Critical!)\n\n'
              'Would you like to grant these permissions now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        );

        if (result == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PermissionsPage(),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    print('Notification permission: $notificationStatus');

    if (!notificationStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    // Check exact alarm permission for Android 12+
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    print('Exact alarm permission: $alarmStatus');

    if (!alarmStatus.isGranted) {
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'This app needs permission to schedule exact alarms. '
              'You will be taken to settings to enable this permission.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (result == true) {
          await Permission.scheduleExactAlarm.request();
          // Check again after user returns
          final newStatus = await Permission.scheduleExactAlarm.status;
          print('Exact alarm permission after settings: $newStatus');
          if (!newStatus.isGranted) {
            return false;
          }
        } else {
          return false;
        }
      }
    }

    // Check battery optimization
    final batteryOptStatus = await Permission.ignoreBatteryOptimizations.status;
    print('Battery optimization status: $batteryOptStatus');

    if (!batteryOptStatus.isGranted) {
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Battery Optimization'),
            content: const Text(
              'For reliable notifications, please disable battery optimization for this app. '
              'This ensures notifications are delivered even when the app is in the background.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Disable'),
              ),
            ],
          ),
        );

        if (result == true) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      }
    }

    return true;
  }

  Future<void> _testNotification() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions not granted'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await NotificationService().showImmediateNotification(
        title: titleController.text.isEmpty
            ? 'Test Notification'
            : titleController.text,
        body: messageController.text.isEmpty
            ? 'This is a test!'
            : messageController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scheduleAlarm() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exact alarm permission is required for alarms'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    print('Current time: ${DateTime.now()}');
    print('Scheduled alarm time: $scheduledDateTime');
    print('Difference: ${scheduledDateTime.difference(DateTime.now()).inMinutes} minutes');

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await NotificationService().scheduleAlarm(
        scheduledDate: scheduledDateTime,
        title: titleController.text.isEmpty
            ? '⏰ Alarm'
            : '⏰ ${titleController.text}',
        body: messageController.text.isEmpty
            ? 'Your alarm is ringing!'
            : messageController.text,
      );

      print('Alarm scheduled successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⏰ Alarm set for ${scheduledDateTime.toString().substring(0, 16)}\n'
              'In ${scheduledDateTime.difference(DateTime.now()).inMinutes} minutes',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error scheduling alarm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling alarm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scheduleNotification() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exact alarm permission is required for scheduling'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    print('Current time: ${DateTime.now()}');
    print('Scheduled time: $scheduledDateTime');
    print('Difference: ${scheduledDateTime.difference(DateTime.now()).inMinutes} minutes');

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await NotificationService().scheduleNotification(
        scheduledDate: scheduledDateTime,
        title: titleController.text.isEmpty
            ? 'Scheduled Notification'
            : titleController.text,
        body: messageController.text.isEmpty
            ? 'This is your scheduled notification!'
            : messageController.text,
      );

      print('Notification scheduled successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification scheduled for ${scheduledDateTime.toString().substring(0, 16)}\n'
              'In ${scheduledDateTime.difference(DateTime.now()).inMinutes} minutes',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error scheduling notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Notification Tester'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PermissionsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Notification Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Select Date'),
                      subtitle: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      onTap: () => _selectDate(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Select Time'),
                      subtitle: Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                      onTap: () => _selectTime(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _testNotification,
              icon: const Icon(Icons.notification_add),
              label: const Text('Test Notification Now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scheduleNotification,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Schedule Notification'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scheduleAlarm,
              icon: const Icon(Icons.alarm),
              label: const Text('Schedule Alarm'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                await NotificationService().cancelAll();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications cancelled'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel All Notifications'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
