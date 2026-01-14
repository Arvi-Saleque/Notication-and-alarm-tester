package com.example.notify_tester

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
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
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        val title = intent.getStringExtra("title") ?: "Alarm"
        val body = intent.getStringExtra("body") ?: "Time to wake up!"

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(50, 50, 50, 50)
            setBackgroundColor(Color.parseColor("#FF1744"))
        }

        val titleText = TextView(this).apply {
            text = title
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(20, 100, 20, 40)
        }

        val bodyText = TextView(this).apply {
            text = body
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(20, 20, 20, 100)
        }

        val dismissButton = Button(this).apply {
            text = "DISMISS ALARM"
            textSize = 20f
            setPadding(40, 40, 40, 40)
            setBackgroundColor(Color.WHITE)
            setTextColor(Color.parseColor("#FF1744"))
            setOnClickListener {
                stopAlarm()
                finish()
            }
        }

        layout.addView(titleText)
        layout.addView(bodyText)
        layout.addView(dismissButton)
        setContentView(layout)

        startAlarm()
    }

    private fun startAlarm() {
        try {
            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            val pattern = longArrayOf(0, 1000, 500, 1000, 500, 1000, 500)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(
                    VibrationEffect.createWaveform(pattern, 0)
                )
            } else {
                vibrator?.vibrate(pattern, 0)
            }

            val alarmUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            mediaPlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alarmUri)
                
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                
                setAudioAttributes(audioAttributes)
                isLooping = true
                setVolume(1.0f, 1.0f)
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopAlarm() {
        try {
            mediaPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            mediaPlayer = null

            vibrator?.cancel()
            vibrator = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        stopAlarm()
        super.onDestroy()
    }

    override fun onBackPressed() {
        // Prevent back button
    }
}
