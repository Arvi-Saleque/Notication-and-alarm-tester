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
