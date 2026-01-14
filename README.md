# Notify Tester - Flutter Notification & Alarm App

A comprehensive Flutter application demonstrating scheduled notifications and full-featured alarm implementation with continuous sound, vibration, and lock screen display.

---

## 📱 How This App Works

This app provides three main features:

1. **Test Notification** - Sends an immediate notification to verify notification system is working
2. **Schedule Notification** - Schedules a notification for a specific date and time using Flutter's notification system
3. **Schedule Alarm** - Creates a real alarm with:
   - Continuous looping alarm sound
   - Persistent vibration
   - Full-screen red display that shows on lock screen
   - Dismiss button to stop the alarm
   - Native Android AlarmManager integration for precise timing

When the alarm time arrives, the app automatically launches a full-screen activity with loud alarm sound and vibration, even if the phone is locked or the app is closed.

---

## 📚 Complete Documentation

This documentation is divided into two parts:
- **Part 1: Scheduled Notifications** (Basic notifications)
- **Part 2: Full-Featured Alarms** (Real alarm system with sound and full-screen UI)

---

# Part 1: Scheduled Notifications Implementation

## 🔐 Step 1: Permissions Required

### Permissions Overview
For scheduled notifications, you need:
- `POST_NOTIFICATIONS` (Android 13+) - To display notifications
- `SCHEDULE_EXACT_ALARM` (Android 12+) - To schedule notifications at exact times
- `RECEIVE_BOOT_COMPLETED` (Optional) - To reschedule notifications after device reboot

### Implementation Steps

#### 1.1 Add Permission Package

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  permission_handler: ^11.4.0
  flutter_local_notifications: ^17.2.4
  timezone: ^0.9.4
```

Run:
```bash
flutter pub get
```

#### 1.2 Configure Android Permissions

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>` tag (before `<application>`):

```xml
<!-- Notification permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
```

#### 1.3 Request Permissions in Code

Create a method to request permissions:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestNotificationPermissions() async {
  // Request notification permission (Android 13+)
  PermissionStatus notificationStatus = await Permission.notification.request();
  print('Notification permission: $notificationStatus');

  // Request exact alarm permission (Android 12+)
  PermissionStatus alarmStatus = await Permission.scheduleExactAlarm.request();
  print('Exact alarm permission: $alarmStatus');

  // Check if all permissions granted
  if (notificationStatus.isGranted && alarmStatus.isGranted) {
    print('All permissions granted!');
  } else {
    // Show dialog or explanation to user
    print('Permissions denied. Please enable them in settings.');
  }
}
```

Call this in your app initialization:

```dart
@override
void initState() {
  super.initState();
  requestNotificationPermissions();
}
```

---

## 📦 Step 2: Required Packages & Setup

### 2.1 Package Details

**flutter_local_notifications (v17.2.4)**
- Purpose: Handle local notifications on device
- Features: Schedule, display, and manage notifications
- Platforms: Android, iOS, macOS

**timezone (v0.9.4)**
- Purpose: Handle timezone-aware scheduling
- Required for: Scheduling notifications at specific times
- Usage: Convert DateTime to TZDateTime for scheduling

**permission_handler (v11.4.0)**
- Purpose: Request runtime permissions
- Features: Check and request various Android/iOS permissions
- Usage: Request notification and alarm permissions

### 2.2 Android Configuration

#### Update `android/app/build.gradle`:

```gradle
android {
    namespace = "com.example.notify_tester"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required for timezone support
        coreLibraryDesugaringEnabled true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "com.example.notify_tester"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }
}

dependencies {
    // Required for timezone support on older Android versions
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

#### Update `android/build.gradle`:

```gradle
buildscript {
    ext.kotlin_version = '2.1.0'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.3")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}
```

#### Update `android/gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.9-all.zip
```

### 2.3 Add Notification Receiver to AndroidManifest

Add inside `<application>` tag in `android/app/src/main/AndroidManifest.xml`:

```xml
<receiver 
    android:exported="false" 
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
```

---

## 💻 Step 3: Notification Service Implementation

### 3.1 Create NotificationService Class

Create file: `lib/notification_service.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notification service
  Future<void> initialize() async {
    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
        // Handle notification tap here
      },
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  // Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'scheduled_channel',
      'Scheduled Notifications',
      description: 'Channel for scheduled notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF2196F3),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Send test notification immediately
  Future<void> testNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Test Notification',
      'This is a test notification!',
      notificationDetails,
    );
  }

  // Schedule notification for specific date and time
  Future<void> scheduleNotification({
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Notifications',
      channelDescription: 'Channel for scheduled notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // Convert DateTime to TZDateTime
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Schedule notification
    await _notifications.zonedSchedule(
      0,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('Notification scheduled for: $scheduledDate');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
```

---

## 🚀 Step 4: Using Notifications in Your App

### 4.1 Initialize in main.dart

```dart
import 'package:flutter/material.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Demo',
      home: NotificationPage(),
    );
  }
}
```

### 4.2 Schedule Notification from UI

```dart
import 'package:flutter/material.dart';
import 'notification_service.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // Test notification
  Future<void> _testNotification() async {
    await NotificationService().testNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test notification sent!')),
    );
  }

  // Schedule notification
  Future<void> _scheduleNotification() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    // Combine date and time
    final scheduledDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    await NotificationService().scheduleNotification(
      scheduledDate: scheduledDateTime,
      title: 'Scheduled Notification',
      body: 'This notification was scheduled for ${selectedTime!.format(context)}',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification scheduled!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Test notification button
            ElevatedButton(
              onPressed: _testNotification,
              child: Text('Send Test Notification'),
            ),
            SizedBox(height: 20),
            
            // Date picker
            ListTile(
              title: Text('Select Date'),
              subtitle: Text(selectedDate?.toString() ?? 'No date selected'),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
            ),
            
            // Time picker
            ListTile(
              title: Text('Select Time'),
              subtitle: Text(selectedTime?.format(context) ?? 'No time selected'),
              trailing: Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => selectedTime = time);
                }
              },
            ),
            
            SizedBox(height: 20),
            
            // Schedule button
            ElevatedButton(
              onPressed: _scheduleNotification,
              child: Text('Schedule Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

# Part 2: Full-Featured Alarm System Implementation

## 🔐 Step 1: Additional Permissions for Alarms

Alarms require additional permissions beyond basic notifications:

### Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- All notification permissions from Part 1, plus: -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.DISABLE_KEYGUARD" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

### Request Battery Optimization Exemption (Optional but Recommended):

```dart
Future<void> requestAlarmPermissions() async {
  // All permissions from Part 1, plus:
  
  // Battery optimization exemption
  PermissionStatus batteryStatus = await Permission.ignoreBatteryOptimizations.request();
  print('Battery optimization status: $batteryStatus');
}
```

---

## 📦 Step 2: Native Android Setup

### 2.1 Create AlarmActivity (Kotlin)

Create file: `android/app/src/main/kotlin/com/example/notify_tester/AlarmActivity.kt`

```kotlin
package com.example.notify_tester

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class AlarmActivity : Activity() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Show on lock screen and turn screen on
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        // Keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Get alarm details from intent
        val title = intent.getStringExtra("title") ?: "Alarm"
        val body = intent.getStringExtra("body") ?: "Time to wake up!"

        // Create full-screen red UI
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#FF1744"))
            setPadding(50, 50, 50, 50)
        }

        // Title text
        val titleText = TextView(this).apply {
            text = title
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        // Body text
        val bodyText = TextView(this).apply {
            text = body
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 40, 0, 40)
        }

        // Dismiss button
        val dismissButton = Button(this).apply {
            text = "DISMISS ALARM"
            textSize = 20f
            setTextColor(Color.parseColor("#FF1744"))
            setBackgroundColor(Color.WHITE)
            setPadding(40, 20, 40, 20)
            setOnClickListener {
                stopAlarm()
                finish()
            }
        }

        // Add views to layout
        layout.addView(titleText)
        layout.addView(bodyText)
        layout.addView(dismissButton)

        setContentView(layout)

        // Start alarm sound and vibration
        startAlarm()
    }

    private fun startAlarm() {
        // Start alarm sound
        try {
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@AlarmActivity, alarmUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true  // CRITICAL: Loop continuously
                setVolume(1.0f, 1.0f)
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Start vibration
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        val pattern = longArrayOf(0, 1000, 500, 1000, 500, 1000, 500)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(
                VibrationEffect.createWaveform(pattern, 0) // 0 = repeat from start
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun stopAlarm() {
        // Stop sound
        mediaPlayer?.apply {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null

        // Stop vibration
        vibrator?.cancel()
        vibrator = null
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
    }

    override fun onBackPressed() {
        // Prevent back button from dismissing alarm
        // User must press dismiss button
    }
}
```

### 2.2 Create AlarmReceiver (Kotlin)

Create file: `android/app/src/main/kotlin/com/example/notify_tester/AlarmReceiver.kt`

```kotlin
package com.example.notify_tester

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: "Alarm"
        val body = intent.getStringExtra("body") ?: "Time to wake up!"
        
        val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("title", title)
            putExtra("body", body)
        }
        context.startActivity(alarmIntent)
    }
}
```

### 2.3 Update MainActivity

Modify `android/app/src/main/kotlin/com/example/notify_tester/MainActivity.kt`:

```kotlin
package com.example.notify_tester

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.notify_tester/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val timestamp = call.argument<Long>("timestamp") ?: 0L
                    val title = call.argument<String>("title") ?: "Alarm"
                    val body = call.argument<String>("body") ?: "Time to wake up!"
                    
                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    
                    val intent = Intent(this, AlarmReceiver::class.java).apply {
                        putExtra("title", title)
                        putExtra("body", body)
                    }
                    
                    val pendingIntent = PendingIntent.getBroadcast(
                        this,
                        1,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        if (alarmManager.canScheduleExactAlarms()) {
                            alarmManager.setAlarmClock(
                                AlarmManager.AlarmClockInfo(timestamp, pendingIntent),
                                pendingIntent
                            )
                        }
                    } else {
                        alarmManager.setAlarmClock(
                            AlarmManager.AlarmClockInfo(timestamp, pendingIntent),
                            pendingIntent
                        )
                    }
                    
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
```

### 2.4 Register Components in AndroidManifest

Add inside `<application>` tag in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- AlarmActivity for full-screen alarm display -->
<activity
    android:name=".AlarmActivity"
    android:excludeFromRecents="true"
    android:launchMode="singleInstance"
    android:showWhenLocked="true"
    android:turnScreenOn="true"
    android:taskAffinity=""
    android:exported="false" />

<!-- AlarmReceiver to trigger alarm at scheduled time -->
<receiver 
    android:name=".AlarmReceiver"
    android:exported="false" />
```

---

## 💻 Step 3: Flutter Alarm Service

### 3.1 Update NotificationService with Alarm Support

Update `lib/notification_service.dart` to add alarm functionality:

```dart
import 'package:flutter/services.dart';

class NotificationService {
  // ... (all previous notification code) ...

  // Add MethodChannel for native communication
  static const platform = MethodChannel('com.example.notify_tester/alarm');

  // Schedule alarm using native Android AlarmManager
  Future<void> scheduleAlarm({
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    try {
      await platform.invokeMethod('scheduleAlarm', {
        'timestamp': scheduledDate.millisecondsSinceEpoch,
        'title': title,
        'body': body,
      });
      print('Alarm scheduled successfully for: $scheduledDate');
    } catch (e) {
      print('Error scheduling alarm: $e');
    }
  }
}
```

---

## 🚀 Step 4: Using Alarms in Your App

### 4.1 Add Alarm Button to UI

```dart
class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // Schedule alarm
  Future<void> _scheduleAlarm() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    // Combine date and time
    final scheduledDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    // Check if time is in the future
    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a future time')),
      );
      return;
    }

    await NotificationService().scheduleAlarm(
      scheduledDate: scheduledDateTime,
      title: 'Alarm',
      body: 'Time to wake up!',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alarm scheduled for ${selectedTime!.format(context)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications & Alarms')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date picker
            ListTile(
              title: Text('Select Date'),
              subtitle: Text(selectedDate?.toString() ?? 'No date selected'),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
            ),
            
            // Time picker
            ListTile(
              title: Text('Select Time'),
              subtitle: Text(selectedTime?.format(context) ?? 'No time selected'),
              trailing: Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => selectedTime = time);
                }
              },
            ),
            
            SizedBox(height: 20),
            
            // Alarm button
            ElevatedButton.icon(
              onPressed: _scheduleAlarm,
              icon: Icon(Icons.alarm),
              label: Text('Schedule Alarm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎯 Key Differences: Notifications vs Alarms

| Feature | Scheduled Notification | Full Alarm |
|---------|----------------------|------------|
| **Sound** | Plays once | Loops continuously |
| **Display** | Small notification bar | Full-screen red display |
| **Lock Screen** | Shows notification | Shows full-screen activity |
| **Dismissal** | Swipe away | Must press dismiss button |
| **Vibration** | Brief vibration | Continuous vibration |
| **Priority** | Normal | Highest (ALARM) |
| **Reliability** | Good | Excellent (AlarmManager) |
| **Use Case** | Reminders, updates | Wake-up alarms, critical alerts |

---

## 🐛 Common Issues & Solutions

### Issue 1: Notifications not showing
**Solution:** Check if notification permission is granted
```dart
PermissionStatus status = await Permission.notification.status;
if (!status.isGranted) {
  await Permission.notification.request();
}
```

### Issue 2: Alarm not triggering at exact time
**Solution:** Ensure exact alarm permission is granted
```dart
PermissionStatus status = await Permission.scheduleExactAlarm.status;
if (!status.isGranted) {
  await Permission.scheduleExactAlarm.request();
}
```

### Issue 3: Alarm killed by battery optimization
**Solution:** Request battery optimization exemption
```dart
await Permission.ignoreBatteryOptimizations.request();
```

### Issue 4: Alarm not showing on lock screen
**Solution:** Verify these flags in AlarmActivity:
```kotlin
setShowWhenLocked(true)
setTurnScreenOn(true)
```

### Issue 5: Sound not looping
**Solution:** Ensure MediaPlayer has `isLooping = true`:
```kotlin
mediaPlayer?.isLooping = true
```

---

## 📋 Complete Checklist

### For Notifications:
- [ ] Add `flutter_local_notifications` package
- [ ] Add `timezone` package
- [ ] Add `permission_handler` package
- [ ] Configure Android permissions in manifest
- [ ] Enable core library desugaring
- [ ] Initialize notification service
- [ ] Create notification channels
- [ ] Request runtime permissions
- [ ] Implement schedule notification method

### For Alarms:
- [ ] Complete all notification setup steps
- [ ] Create AlarmActivity.kt
- [ ] Create AlarmReceiver.kt
- [ ] Update MainActivity.kt with MethodChannel
- [ ] Register components in AndroidManifest
- [ ] Add alarm-specific permissions
- [ ] Implement MethodChannel in Flutter
- [ ] Create scheduleAlarm method
- [ ] Test on physical device

---

## 🚀 Testing

### Test Notifications:
1. Grant all permissions when app opens
2. Select future date and time (e.g., 2 minutes from now)
3. Press "Schedule Notification"
4. Wait for scheduled time
5. Notification should appear in notification bar

### Test Alarms:
1. Grant all permissions
2. Select future time (1-2 minutes from now)
3. Press "Schedule Alarm"
4. Lock your device
5. At scheduled time:
   - Screen turns on
   - Full-screen red display appears
   - Continuous alarm sound plays
   - Device vibrates continuously
   - Press "DISMISS ALARM" to stop

---

## 📱 Platform Support

- **Android:** Fully supported (API 21+)
- **iOS:** Basic notifications supported (alarms require different approach)
- **Minimum SDK:** 21 (Android 5.0)
- **Target SDK:** 35 (Android 15)

---

## 📄 License

This documentation is provided as-is for educational purposes.

---

## 🤝 Contributing

Feel free to improve this documentation or report issues!

---

## 📞 Support

For issues or questions:
1. Check permissions are granted
2. Verify AndroidManifest configuration
3. Check Android Studio Logcat for errors
4. Ensure device is not in Do Not Disturb mode
5. Test on physical device (emulator may have limitations)

---

**Happy Coding! 🎉**
