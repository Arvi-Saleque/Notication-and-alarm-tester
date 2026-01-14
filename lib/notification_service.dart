import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static const platform = MethodChannel('com.example.notify_tester/alarm');

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification clicked: ${response.payload}');
        if (response.payload != null && response.payload!.startsWith('alarm|')) {
          final parts = response.payload!.split('|');
          if (parts.length >= 3) {
            _launchAlarmActivity(parts[1], parts[2]);
          }
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'scheduled_notifications',
      'Scheduled Notifications',
      description: 'Notifications scheduled by the user',
      importance: Importance.high,
    );

    const alarmChannel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarms',
      description: 'Alarm notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'scheduled_notifications',
      'Scheduled Notifications',
      channelDescription: 'Notifications scheduled by the user',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> scheduleNotification({
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'scheduled_notifications',
      'Scheduled Notifications',
      channelDescription: 'Notifications scheduled by the user',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleAlarm({
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    // Use method channel to schedule alarm with native Android AlarmManager
    try {
      print('Scheduling alarm for: $scheduledDate');
      print('Title: $title, Body: $body');
      print('Timestamp: ${scheduledDate.millisecondsSinceEpoch}');
      
      final result = await platform.invokeMethod('scheduleAlarm', {
        'timestamp': scheduledDate.millisecondsSinceEpoch,
        'title': title,
        'body': body,
      });
      
      print('Alarm scheduled successfully: $result');
    } catch (e) {
      print('Error scheduling alarm: $e');
      rethrow;
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> _launchAlarmActivity(String title, String body) async {
    try {
      await platform.invokeMethod('launchAlarm', {
        'title': title,
        'body': body,
      });
    } catch (e) {
      print('Error launching alarm activity: $e');
    }
  }
}
