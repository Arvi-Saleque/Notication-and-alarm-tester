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
                "launchAlarm" -> {
                    val title = call.argument<String>("title") ?: "Alarm"
                    val body = call.argument<String>("body") ?: "Time to wake up!"
                    
                    val intent = Intent(this, AlarmActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("title", title)
                        putExtra("body", body)
                    }
                    startActivity(intent)
                    result.success(null)
                }
                "scheduleAlarm" -> {
                    val timestamp = call.argument<Long>("timestamp") ?: 0L
                    val title = call.argument<String>("title") ?: "Alarm"
                    val body = call.argument<String>("body") ?: "Time to wake up!"
                    
                    android.util.Log.d("MainActivity", "Scheduling alarm - timestamp: $timestamp, title: $title, body: $body")
                    
                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    
                    // Use unique ID based on timestamp to avoid conflicts
                    val requestCode = (timestamp / 1000).toInt()
                    
                    val intent = Intent(this, AlarmReceiver::class.java).apply {
                        action = "com.example.notify_tester.ALARM_ACTION"
                        putExtra("title", title)
                        putExtra("body", body)
                        // Add timestamp to help identify the alarm
                        putExtra("timestamp", timestamp)
                    }
                    
                    val pendingIntent = PendingIntent.getBroadcast(
                        this,
                        requestCode,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (alarmManager.canScheduleExactAlarms()) {
                                android.util.Log.d("MainActivity", "Scheduling exact alarm with AlarmClock (ID: $requestCode)")
                                alarmManager.setAlarmClock(
                                    AlarmManager.AlarmClockInfo(timestamp, pendingIntent),
                                    pendingIntent
                                )
                                android.util.Log.d("MainActivity", "Alarm scheduled successfully")
                            } else {
                                android.util.Log.e("MainActivity", "Cannot schedule exact alarms - permission denied")
                                result.error("NO_PERMISSION", "Cannot schedule exact alarms", null)
                                return@setMethodCallHandler
                            }
                        } else {
                            android.util.Log.d("MainActivity", "Scheduling alarm for Android < 12 (ID: $requestCode)")
                            alarmManager.setAlarmClock(
                                AlarmManager.AlarmClockInfo(timestamp, pendingIntent),
                                pendingIntent
                            )
                            android.util.Log.d("MainActivity", "Alarm scheduled successfully")
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Error scheduling alarm", e)
                        result.error("ALARM_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
