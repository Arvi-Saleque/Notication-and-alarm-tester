# Flutter Alarm & Notification Tester

A complete Flutter app that demonstrates how to implement **reliable alarms and notifications** that work even when the app is completely closed. This implementation handles Android's background restrictions, ProGuard obfuscation, and OEM-specific battery optimizations (OnePlus, Oppo, Xiaomi, etc.).

## 🎯 Features

- ✅ Schedule exact alarms that trigger even when app is closed
- ✅ Full-screen alarm activity with sound and vibration
- ✅ Test notifications
- ✅ Works with ProGuard/R8 code shrinking enabled
- ✅ Handles Android 10+ background activity restrictions
- ✅ Comprehensive permission management UI
- ✅ OEM-specific battery optimization handling

## 📋 Table of Contents

1. [Dependencies](#dependencies)
2. [Permissions Required](#permissions-required)
3. [Complete Implementation](#complete-implementation)
4. [ProGuard Configuration](#proguard-configuration)
5. [OEM-Specific Settings](#oem-specific-settings)
6. [Building APK](#building-apk)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

---

## 📦 Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.0
  permission_handler: ^11.0.0
  android_intent_plus: ^4.0.0
```

Run: `flutter pub get`

---

## 🔐 Permissions Required

### Why Each Permission is Needed

| Permission | Purpose | Critical? |
|------------|---------|-----------|
| `POST_NOTIFICATIONS` | Display notifications on Android 13+ | ⭐ YES |
| `SCHEDULE_EXACT_ALARM` | Schedule alarms at exact time (Android 12+) | ⭐ YES |
| `USE_EXACT_ALARM` | Alternative for exact alarms | ⭐ YES |
| `RECEIVE_BOOT_COMPLETED` | Reschedule alarms after device reboot | ⭐ YES |
| `VIBRATE` | Vibrate device when alarm rings | ⭐ YES |
| `WAKE_LOCK` | Keep device awake to show alarm | ⭐ YES |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Request battery optimization exemption | ⭐ YES |
| `USE_FULL_SCREEN_INTENT` | Show full-screen alarm over lockscreen | ⭐ YES |
| `SYSTEM_ALERT_WINDOW` | Display over other apps | ⭐ YES |
| `FOREGROUND_SERVICE` | Run service in background | ⭐ YES |
| `FOREGROUND_SERVICE_SPECIAL_USE` | Special use foreground service | ⭐ YES |

---

## 🔨 Complete Implementation

### Step 1: Update `android/app/build.gradle`

```gradle
android {
    namespace = "com.example.notify_tester"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "com.example.notify_tester"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Enable code shrinking and obfuscation
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            signingConfig = signingConfigs.debug
        }
    }
}
```

---

### Step 2: Create `android/app/proguard-rules.pro`

**CRITICAL:** ProGuard will remove your alarm classes if not configured properly!

```proguard
## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Kotlin
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    static void checkParameterIsNotNull(java.lang.Object, java.lang.String);
}

## flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class com.google.firebase.** { *; }

## Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## Keep generic signature for gson
-keepattributes Signature

## Keep notification channels and other reflection-based classes
-keep class * extends java.lang.Enum { *; }

## Google Play Core (for deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

## Keep custom alarm classes (REPLACE com.example.notify_tester with YOUR package name)
-keep class com.example.notify_tester.AlarmReceiver { *; }
-keep class com.example.notify_tester.AlarmActivity { *; }
-keep class com.example.notify_tester.AlarmService { *; }
-keep class com.example.notify_tester.MainActivity { *; }

## Keep all BroadcastReceivers
-keep public class * extends android.content.BroadcastReceiver

## Keep AlarmManager related classes
-keep class android.app.AlarmManager { *; }
-keep class android.app.PendingIntent { *; }

## Keep all public methods in custom classes
-keepclassmembers class com.example.notify_tester.** {
    public *;
}

## Keep Intent extras
-keepclassmembers class * {
    public void onReceive(android.content.Context, android.content.Intent);
}

## Keep method channel handlers
-keepclassmembers class * {
    *** configureFlutterEngine(io.flutter.embedding.engine.FlutterEngine);
}
```

**⚠️ IMPORTANT:** Replace `com.example.notify_tester` with your actual package name!

---

### Step 3: Update `android/app/src/main/AndroidManifest.xml`

Add all required permissions and components:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- All required permissions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>

    <application
        android:label="Notify Tester"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Main Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- Alarm Activity - Shows full screen when alarm triggers -->
        <activity
            android:name=".AlarmActivity"
            android:exported="true"
            android:launchMode="singleInstance"
            android:showWhenLocked="true"
            android:turnScreenOn="true"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar" />

        <!-- Alarm Service - Keeps app alive to show alarm -->
        <service
            android:name=".AlarmService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="specialUse">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="Alarm trigger service" />
        </service>

        <!-- Alarm Receiver - Receives alarm broadcasts -->
        <receiver
            android:name=".AlarmReceiver"
            android:enabled="true"
            android:exported="true"
            android:directBootAware="true">
            <intent-filter>
                <action android:name="com.example.notify_tester.ALARM_ACTION" />
            </intent-filter>
        </receiver>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

---

### Step 4: Create Kotlin Files

#### 4.1: `MainActivity.kt`

Location: `android/app/src/main/kotlin/com/example/notify_tester/MainActivity.kt`

```kotlin
package com.example.notify_tester

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.notify_tester/alarm"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val timestamp = call.argument<Long>("timestamp")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    
                    Log.d(TAG, "Scheduling alarm - timestamp: $timestamp, title: $title, body: $body")
                    
                    if (timestamp != null && title != null && body != null) {
                        scheduleAlarm(timestamp, title, body)
                        result.success(true)
                    } else {
                        Log.e(TAG, "Missing parameters for alarm")
                        result.error("INVALID_ARGS", "Missing required parameters", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleAlarm(timestamp: Long, title: String, body: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Use timestamp as unique alarm ID to prevent conflicts
        val alarmId = (timestamp / 1000).toInt()
        
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.example.notify_tester.ALARM_ACTION"
            putExtra("title", title)
            putExtra("body", body)
            putExtra("alarmId", alarmId)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Create AlarmClock info for showing in system UI
        val alarmClockInfo = AlarmManager.AlarmClockInfo(
            timestamp,
            pendingIntent
        )
        
        try {
            Log.d(TAG, "Scheduling exact alarm with AlarmClock (ID: $alarmId)")
            alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            Log.d(TAG, "Alarm scheduled successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule alarm: ${e.message}", e)
        }
    }
}
```

#### 4.2: `AlarmReceiver.kt`

Location: `android/app/src/main/kotlin/com/example/notify_tester/AlarmReceiver.kt`

```kotlin
package com.example.notify_tester

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    private val TAG = "AlarmReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Alarm received!")
        
        val title = intent.getStringExtra("title") ?: "Alarm"
        val body = intent.getStringExtra("body") ?: "Time's up!"
        val alarmId = intent.getIntExtra("alarmId", 0)
        
        Log.d(TAG, "Title: $title, Body: $body")
        
        // Start foreground service to launch alarm activity
        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
            putExtra("alarmId", alarmId)
        }
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d(TAG, "AlarmService started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start AlarmService: ${e.message}", e)
        }
    }
}
```

#### 4.3: `AlarmService.kt`

Location: `android/app/src/main/kotlin/com/example/notify_tester/AlarmService.kt`

```kotlin
package com.example.notify_tester

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmService : Service() {
    private val TAG = "AlarmService"
    private val CHANNEL_ID = "alarm_service_channel"
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        
        val title = intent?.getStringExtra("title") ?: "Alarm"
        val body = intent?.getStringExtra("body") ?: "Time's up!"
        val alarmId = intent?.getIntExtra("alarmId", 0) ?: 0
        
        // Acquire wake lock to keep device awake
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or 
            PowerManager.ACQUIRE_CAUSES_WAKEUP or 
            PowerManager.ON_AFTER_RELEASE,
            "AlarmService::WakeLock"
        ).apply {
            acquire(60000) // 60 seconds
        }
        Log.d(TAG, "Wake lock acquired")
        
        // Create full-screen intent notification
        val fullScreenIntent = Intent(this, AlarmActivity::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            alarmId,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setSound(null)
            .build()
        
        startForeground(alarmId, notification)
        Log.d(TAG, "Full screen notification posted with ID: $alarmId")
        
        // Also try to launch activity directly
        try {
            startActivity(fullScreenIntent)
            Log.d(TAG, "Direct activity launch attempted")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch activity: ${e.message}", e)
        }
        
        Log.d(TAG, "Service running in foreground")
        
        // Stop service after 10 seconds
        Handler(Looper.getMainLooper()).postDelayed({
            Log.d(TAG, "Stopping service")
            stopForeground(true)
            stopSelf()
        }, 10000)
        
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        Log.d(TAG, "Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for alarm notifications"
                setBypassDnd(true)
                enableVibration(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }
}
```

#### 4.4: `AlarmActivity.kt`

Location: `android/app/src/main/kotlin/com/example/notify_tester/AlarmActivity.kt`

```kotlin
package com.example.notify_tester

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class AlarmActivity : AppCompatActivity() {
    private val TAG = "AlarmActivity"
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var vibrator: Vibrator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate called")

        // Show over lockscreen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        // Keep screen on
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        // Acquire wake lock
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or 
            PowerManager.ACQUIRE_CAUSES_WAKEUP or 
            PowerManager.ON_AFTER_RELEASE,
            "AlarmActivity::WakeLock"
        ).apply {
            acquire(10 * 60 * 1000L) // 10 minutes
        }

        // Get intent data
        val title = intent.getStringExtra("title") ?: "Alarm"
        val body = intent.getStringExtra("body") ?: "Time's up!"
        Log.d(TAG, "Title: $title, Body: $body")

        // Create simple UI
        setContentView(R.layout.activity_alarm)
        
        findViewById<TextView>(R.id.alarmTitle).text = title
        findViewById<TextView>(R.id.alarmBody).text = body
        
        findViewById<Button>(R.id.dismissButton).setOnClickListener {
            dismissAlarm()
        }

        // Start alarm sound and vibration
        playAlarmSound()
        startVibration()
    }

    private fun playAlarmSound() {
        try {
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            mediaPlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alarmUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
            Log.d(TAG, "Alarm sound started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play alarm sound: ${e.message}", e)
        }
    }

    private fun startVibration() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        val pattern = longArrayOf(0, 1000, 500, 1000, 500) // Vibrate pattern
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
        Log.d(TAG, "Vibration started")
    }

    private fun dismissAlarm() {
        Log.d(TAG, "Dismissing alarm")
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        
        vibrator?.cancel()
        
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        dismissAlarm()
        Log.d(TAG, "Activity destroyed")
    }
}
```

#### 4.5: Create Alarm Activity Layout

Location: `android/app/src/main/res/layout/activity_alarm.xml`

Create the `layout` folder if it doesn't exist, then create this file:

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center"
    android:background="#FF0000"
    android:padding="32dp">

    <TextView
        android:id="@+id/alarmTitle"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Alarm"
        android:textSize="32sp"
        android:textColor="#FFFFFF"
        android:textStyle="bold"
        android:gravity="center"
        android:layout_marginBottom="16dp"/>

    <TextView
        android:id="@+id/alarmBody"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Time's up!"
        android:textSize="20sp"
        android:textColor="#FFFFFF"
        android:gravity="center"
        android:layout_marginBottom="48dp"/>

    <Button
        android:id="@+id/dismissButton"
        android:layout_width="200dp"
        android:layout_height="wrap_content"
        android:text="DISMISS"
        android:textSize="18sp"
        android:padding="16dp"/>

</LinearLayout>
```

---

### Step 5: Flutter Code

#### 5.1: `lib/notification_service.dart`

```dart
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const platform = MethodChannel('com.example.notify_tester/alarm');

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notifications.show(0, title, body, notificationDetails);
  }

  static Future<void> scheduleNotification(
    String title,
    String body,
    Duration delay,
  ) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    const androidDetails = AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Notifications',
      channelDescription: 'Scheduled notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleAlarm(
    String title,
    String body,
    Duration delay,
  ) async {
    final scheduledTime = DateTime.now().add(delay);
    final timestamp = scheduledTime.millisecondsSinceEpoch;

    print('NotificationService: Scheduling alarm');
    print('  Timestamp: $timestamp');
    print('  Title: $title');
    print('  Body: $body');

    try {
      final result = await platform.invokeMethod('scheduleAlarm', {
        'timestamp': timestamp,
        'title': title,
        'body': body,
      });
      print('NotificationService: Alarm scheduled successfully: $result');
    } catch (e) {
      print('NotificationService: Error scheduling alarm: $e');
      rethrow;
    }
  }
}
```

#### 5.2: `lib/permissions_page.dart`

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = [
      Permission.notification,
      Permission.scheduleExactAlarm,
      Permission.ignoreBatteryOptimizations,
      Permission.systemAlertWindow,
    ];

    final statuses = await Future.wait(
      permissions.map((permission) => permission.status),
    );

    setState(() {
      _permissionStatuses = Map.fromIterables(permissions, statuses);
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    await _checkPermissions();
  }

  Future<void> _openNotificationSettings() async {
    try {
      if (Platform.isAndroid) {
        await openAppSettings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening settings: $e'),
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
        title: const Text('Permissions'),
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: _checkPermissions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Permission Status',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Note: Some permissions may show as "Granted" but not actually work. '
                      'You MUST manually verify all permissions in Settings.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.red,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.alarm, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'CRITICAL: Alarm Setup Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'For alarms to work when app is closed:\n\n'
                      '✓ Go to Settings → Apps → Notify Tester\n\n'
                      '1. Notifications → Enable "Alarms & reminders"\n'
                      '2. Battery → "Don\'t optimize" or "Unrestricted"\n'
                      '3. Battery → "Allow background activity"\n'
                      '4. Auto-launch → Enable (OnePlus/Oppo)\n'
                      '5. Display over other apps → Enable\n\n'
                      'OnePlus users: Disable "Deep Optimization" in Battery settings',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _openNotificationSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Open App Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPermissionTile(
              Permission.notification,
              'Notifications',
              'Required to show alarm notifications',
              Icons.notifications,
            ),
            _buildPermissionTile(
              Permission.scheduleExactAlarm,
              'Schedule Exact Alarms',
              'Required to trigger alarms at exact time',
              Icons.alarm,
            ),
            _buildPermissionTile(
              Permission.ignoreBatteryOptimizations,
              'Battery Optimization',
              'Prevents system from killing app',
              Icons.battery_full,
            ),
            _buildPermissionTile(
              Permission.systemAlertWindow,
              'Display Over Other Apps',
              'Shows alarm over lockscreen',
              Icons.open_in_new,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    Permission permission,
    String title,
    String description,
    IconData icon,
  ) {
    final status = _permissionStatuses[permission];
    final isGranted = status?.isGranted ?? false;

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isGranted ? Colors.green : Colors.orange,
          size: 32,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              status?.name.toUpperCase() ?? 'UNKNOWN',
              style: TextStyle(
                color: isGranted ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _requestPermission(permission),
          child: const Text('Grant'),
        ),
      ),
    );
  }
}
```

#### 5.3: `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';
import 'permissions_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notify Tester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedSeconds = 30;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notification = await Permission.notification.status;
    final alarm = await Permission.scheduleExactAlarm.status;
    
    if (!notification.isGranted || !alarm.isGranted) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app requires notification and alarm permissions to function properly.\n\n'
          'Please grant all required permissions in the Permissions page.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PermissionsPage()),
              );
            },
            child: const Text('Go to Permissions'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Notify Tester'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PermissionsPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Test Notifications & Alarms',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Delay: ', style: TextStyle(fontSize: 18)),
                  DropdownButton<int>(
                    value: _selectedSeconds,
                    items: [5, 10, 15, 30, 60, 120]
                        .map((seconds) => DropdownMenuItem(
                              value: seconds,
                              child: Text('$seconds seconds'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSeconds = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.showNotification(
                    '🔔 Test Notification',
                    'This is a test notification!',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test notification sent!')),
                    );
                  }
                },
                icon: const Icon(Icons.notifications),
                label: const Text('Test Notification'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.scheduleNotification(
                    '📅 Scheduled Notification',
                    'This notification was scheduled!',
                    Duration(seconds: _selectedSeconds),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Notification scheduled for $_selectedSeconds seconds',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.schedule),
                label: const Text('Schedule Notification'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.scheduleAlarm(
                    '⏰ Test Alarm',
                    'Alarm triggered!',
                    Duration(seconds: _selectedSeconds),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Alarm scheduled for $_selectedSeconds seconds'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.alarm),
                label: const Text('Schedule Alarm'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Close the app after scheduling to test background alarms',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🛠️ ProGuard Configuration

**Why it's needed:** Android's code shrinking (ProGuard/R8) removes "unused" classes. Without proper rules, your alarm classes will be stripped from the release APK, causing crashes.

**What to keep:**
- Flutter framework classes
- Kotlin metadata (required for Kotlin reflection)
- flutter_local_notifications plugin classes
- Your custom alarm classes (AlarmReceiver, AlarmActivity, AlarmService, MainActivity)
- BroadcastReceiver classes
- AlarmManager and PendingIntent classes

See the complete ProGuard rules in [Step 2](#step-2-create-androidappproguard-rulespro).

---

## 📱 OEM-Specific Settings

Different phone manufacturers have aggressive battery optimization that kills background apps. Users **MUST** configure these settings manually.

### OnePlus / Oppo / Realme

1. **Settings → Apps → Notify Tester → Battery**
   - Set to "Don't optimize" or "Unrestricted"
   - Enable "Allow background activity"

2. **Settings → Apps → Notify Tester → Auto-launch**
   - Enable

3. **Settings → Battery → Battery Optimization**
   - Find "Notify Tester" and disable "Deep Optimization"

4. **Settings → Apps → Notify Tester → Notifications**
   - Enable "Alarms & reminders"
   - Enable "Allow full screen intent"
   - Set priority to "Urgent"

### Xiaomi / Redmi / POCO

1. **Settings → Apps → Manage Apps → Notify Tester**
   - Battery Saver → No restrictions
   - Autostart → Enable
   - Battery usage → Unrestricted

2. **Settings → Notifications → Notify Tester**
   - Enable "Show on lock screen"
   - Enable "Override Do Not Disturb"

### Samsung

1. **Settings → Apps → Notify Tester → Battery**
   - Allow background activity

2. **Settings → Apps → Notify Tester → Notifications**
   - Allow notifications
   - Set to "Urgent"

### Huawei

1. **Settings → Apps → Notify Tester**
   - Launch → Manage manually
   - Battery → Do not optimize

---

## 🔨 Building APK

### Debug Build
```bash
flutter build apk --debug
```

### Release Build (Recommended)
```bash
flutter build apk --release --target-platform android-arm64
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### Install via USB
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Testing

### 1. Test Immediate Notification
- Open app → Tap "Test Notification"
- Should show notification immediately
- ✅ **Expected:** Notification appears in notification tray

### 2. Test Scheduled Notification
- Open app → Select delay (e.g., 30 seconds) → Tap "Schedule Notification"
- Close app completely (swipe away from recent apps)
- Wait for scheduled time
- ✅ **Expected:** Notification appears even when app is closed

### 3. Test Alarm (App in Recent Apps)
- Open app → Select delay (e.g., 30 seconds) → Tap "Schedule Alarm"
- Press home button (keep app in recent apps)
- Wait for alarm time
- ✅ **Expected:** Full-screen red alarm activity appears with sound and vibration

### 4. Test Alarm (App Closed) - **CRITICAL TEST**
- Open app → Select delay (e.g., 30 seconds) → Tap "Schedule Alarm"
- **Close app completely** (swipe away from recent apps)
- Wait for alarm time
- ✅ **Expected:** Full-screen red alarm activity appears with sound and vibration

**If step 4 fails:** Check [OEM-Specific Settings](#oem-specific-settings)

### Verify with Logs
```bash
adb logcat -s MainActivity AlarmReceiver AlarmActivity AlarmService
```

**Expected log flow:**
1. `MainActivity: Alarm scheduled successfully`
2. `AlarmReceiver: Alarm received!`
3. `AlarmService: Service created`
4. `AlarmService: Wake lock acquired`
5. `AlarmService: Full screen notification posted`
6. `AlarmActivity: onCreate called` ← **This is critical!**

**If `AlarmActivity: onCreate called` is missing when app is closed:**
- User hasn't configured OEM-specific settings
- Battery optimization is killing the service
- "Alarms & reminders" notification permission not enabled

---

## 🐛 Troubleshooting

### Problem: Alarms don't work in release APK

**Cause:** ProGuard is stripping alarm classes

**Solution:** 
1. Verify `proguard-rules.pro` exists in `android/app/`
2. Check `build.gradle` includes `proguardFiles` line
3. Ensure package name in ProGuard rules matches your actual package
4. Clean and rebuild: `flutter clean && flutter build apk --release`

### Problem: Alarm works when app is open, not when closed

**Cause:** Battery optimization or OEM restrictions

**Solution:**
1. Open Permissions page in app
2. Tap "Open App Settings"
3. Follow [OEM-Specific Settings](#oem-specific-settings) for your device
4. **Most important:** Enable "Alarms & reminders" in notification settings

### Problem: Permission shows "Granted" but alarm still doesn't work

**Cause:** `permission_handler` package can't detect all OEM-specific settings

**Solution:**
- **Always** manually verify permissions in Android Settings
- Don't trust the permission status shown in the app
- Check notification settings specifically for "Alarms & reminders"

### Problem: No sound or vibration

**Cause:** Notification channel not configured properly or Do Not Disturb is on

**Solution:**
1. Settings → Apps → Notify Tester → Notifications
2. Tap "Alarm Service" channel
3. Enable "Override Do Not Disturb"
4. Set importance to "Urgent"

### Problem: Alarm appears in notification tray instead of full-screen

**Cause:** "Use full screen intent" permission not granted (Android 12+)

**Solution:**
1. Settings → Apps → Notify Tester → Notifications
2. Enable "Allow full screen intent" or "Alarms & reminders"

### Problem: App crashes in release mode

**Cause:** ProGuard removing necessary classes or Kotlin metadata

**Solution:**
1. Check ProGuard rules include `-keep class kotlin.Metadata { *; }`
2. Add `-keep class com.yourpackage.** { *; }` for your package
3. Test with minification disabled first:
   ```gradle
   buildTypes {
       release {
           minifyEnabled false
           shrinkResources false
       }
   }
   ```
4. If it works, then ProGuard rules need fixing

### OnePlus-Specific: Service destroys before activity launches

**Cause:** OnePlus "Deep Optimization" kills service too quickly

**Solution:**
1. Settings → Battery → Battery Optimization
2. Find "Notify Tester"
3. Disable "Deep Optimization"
4. Also set battery to "Unrestricted"

---

## 📝 Key Takeaways

1. **ProGuard Rules Are Critical** - Your alarm won't work in release mode without them
2. **Foreground Service Required** - Normal background services are killed immediately on Android 10+
3. **Full-Screen Intent** - Only way to show alarm over lockscreen reliably
4. **Wake Locks** - Necessary to turn screen on and keep it on
5. **OEM Settings** - Users MUST manually configure battery optimization
6. **Permission UI** - Don't trust `permission_handler` status, always verify manually
7. **Testing** - Always test with app completely closed, not just in background

---

## 🎯 Implementation Checklist

- [ ] Add dependencies to `pubspec.yaml`
- [ ] Update `build.gradle` with minifyEnabled and ProGuard
- [ ] Create `proguard-rules.pro` with keep rules
- [ ] Update `AndroidManifest.xml` with all permissions
- [ ] Add AlarmActivity, AlarmService, AlarmReceiver components
- [ ] Create `MainActivity.kt` with scheduleAlarm method
- [ ] Create `AlarmReceiver.kt`
- [ ] Create `AlarmService.kt` with foreground service
- [ ] Create `AlarmActivity.kt` with full-screen UI
- [ ] Create `activity_alarm.xml` layout
- [ ] Create `notification_service.dart`
- [ ] Create `permissions_page.dart`
- [ ] Update `main.dart`
- [ ] Build release APK
- [ ] Test with app closed completely
- [ ] Configure OEM-specific settings
- [ ] Verify logs show AlarmActivity launching

---

## 📄 License

This is a demonstration project. Feel free to use this code in your own projects.

---

## 🙏 Credits

Implementation based on solving real-world issues with:
- Android's background activity restrictions
- ProGuard obfuscation problems
- OEM-specific battery optimization
- Full-screen intent notifications

Tested on OnePlus 9RT with Android 13.

---

**Need help?** Check the [Troubleshooting](#troubleshooting) section or review the logs with `adb logcat`.
