package com.example.notify_tester

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmService : Service() {
    private var myWakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        Log.d("AlarmService", "Service created")
        
        // Create notification channel for alarms
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "alarm_fullscreen",
                "Alarm Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Full screen alarm notifications"
                setBypassDnd(true)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 1000, 500, 1000)
                enableLights(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
            
            Log.d("AlarmService", "Notification channel created")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("AlarmService", "Service started")
        
        val title = intent?.getStringExtra("title") ?: "Alarm"
        val body = intent?.getStringExtra("body") ?: "Time to wake up!"
        
        // Acquire FULL wake lock
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        myWakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or 
            PowerManager.ACQUIRE_CAUSES_WAKEUP or 
            PowerManager.ON_AFTER_RELEASE,
            "NotifyTester::AlarmServiceWakeLock"
        )
        myWakeLock?.acquire(60000) // 60 seconds
        
        Log.d("AlarmService", "Wake lock acquired")
        
        // Create full-screen intent for AlarmActivity
        val fullScreenIntent = Intent(this, AlarmActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION)
            putExtra("title", title)
            putExtra("body", body)
        }
        
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            System.currentTimeMillis().toInt(),
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Create notification with full screen intent
        val notificationBuilder = NotificationCompat.Builder(this, "alarm_fullscreen")
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setAutoCancel(true)
            .setOngoing(false)
            .setVibrate(longArrayOf(0, 1000, 500, 1000))
            .setSound(android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM))
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationBuilder.setChannelId("alarm_fullscreen")
        }
        
        val notification = notificationBuilder.build()
        notification.flags = notification.flags or android.app.Notification.FLAG_INSISTENT
        
        // Start as foreground first
        startForeground(9999, notification)
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Post the notification with unique ID
        val notificationId = System.currentTimeMillis().toInt()
        notificationManager.notify(notificationId, notification)
        
        Log.d("AlarmService", "Full screen notification posted with ID: $notificationId")
        
        // Also try to start activity directly
        try {
            startActivity(fullScreenIntent)
            Log.d("AlarmService", "Direct activity launch attempted")
        } catch (e: Exception) {
            Log.e("AlarmService", "Error starting activity directly", e)
        }
        
        // Keep service running as foreground
        Log.d("AlarmService", "Service running in foreground")
        
        // Stop service after delay
        android.os.Handler(mainLooper).postDelayed({
            Log.d("AlarmService", "Stopping service")
            if (myWakeLock?.isHeld == true) {
                myWakeLock?.release()
            }
            stopForeground(false) // Keep notification
            stopSelf()
        }, 10000)
        
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        Log.d("AlarmService", "Service destroyed")
        if (myWakeLock?.isHeld == true) {
            myWakeLock?.release()
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
