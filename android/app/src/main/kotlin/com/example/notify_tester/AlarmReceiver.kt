package com.example.notify_tester

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmReceiver", "Alarm received!")
        
        val title = intent.getStringExtra("title") ?: "Alarm"
        val body = intent.getStringExtra("body") ?: "Time to wake up!"
        
        Log.d("AlarmReceiver", "Title: $title, Body: $body")
        
        // Start foreground service to handle the alarm
        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
        }
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d("AlarmReceiver", "AlarmService started")
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "Error starting AlarmService", e)
        }
    }
}
