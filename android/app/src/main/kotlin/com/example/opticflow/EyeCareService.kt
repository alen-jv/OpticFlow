package com.example.opticflow

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class EyeCareService : Service() {

    companion object {
        const val CHANNEL_ID = "eye_care_channel"
        const val BREAK_CHANNEL_ID = "eye_care_break_channel"
        const val NOTIFICATION_ID = 2020
        const val PREFS_NAME = "FlutterSharedPreferences"

        var instance: EyeCareService? = null
        var listener: ((Map<String, Any>) -> Unit)? = null

        fun isRunning(): Boolean = instance != null
    }

    private val handler = Handler(Looper.getMainLooper())
    private var isScreenOn = true
    private var isTracking = true
    private var session = "focus" // "focus" or "break"
    private var focusMinutes = 20
    private var breakSeconds = 20
    private var remainingSeconds = 20 * 60
    private var breaksCompletedToday = 0

    private val tickerRunnable = object : Runnable {
        override fun run() {
            if (isTracking && isScreenOn) {
                if (remainingSeconds > 0) {
                    remainingSeconds--
                    // Update notification periodically to conserve battery
                    if (remainingSeconds % 10 == 0 || remainingSeconds <= 5 || session == "break") {
                        updateNotification()
                    }
                } else {
                    onSessionComplete()
                }
                notifyState()
            }
            handler.postDelayed(this, 1000)
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_ON, Intent.ACTION_USER_PRESENT -> {
                    if (!isScreenOn) {
                        isScreenOn = true
                        updateNotification()
                        notifyState()
                    }
                }
                Intent.ACTION_SCREEN_OFF -> {
                    isScreenOn = false
                    session = "focus"
                    remainingSeconds = focusMinutes * 60
                    updateNotification()
                    notifyState()
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        loadPreferences()

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        isScreenOn = powerManager.isInteractive

        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenReceiver, filter)

        handler.post(tickerRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        loadPreferences()
        updateNotification()
        notifyState()
        return START_STICKY
    }

    override fun onDestroy() {
        instance = null
        handler.removeCallbacks(tickerRunnable)
        try {
            unregisterReceiver(screenReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun onSessionComplete() {
        if (session == "focus") {
            session = "break"
            remainingSeconds = breakSeconds
            updateNotification(isBreak = true)
            launchBreakOverlay()
        } else {
            session = "focus"
            remainingSeconds = focusMinutes * 60
            breaksCompletedToday++
            saveDailyCounter()
            updateNotification(isBreak = false)
            listener?.invoke(mapOf("action" to "break_completed"))
        }
        notifyState()
    }

    private fun launchBreakOverlay() {
        try {
            val breakIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("auto_break_overlay", true)
            }
            startActivity(breakIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun updateSettings(newFocusMinutes: Int, newBreakSeconds: Int) {
        focusMinutes = newFocusMinutes
        breakSeconds = newBreakSeconds
        if (session == "focus" && remainingSeconds > focusMinutes * 60) {
            remainingSeconds = focusMinutes * 60
        }
        updateNotification()
        notifyState()
    }

    fun resetTimer() {
        session = "focus"
        remainingSeconds = focusMinutes * 60
        updateNotification()
        notifyState()
    }

    fun skipBreak() {
        if (session == "break") {
            session = "focus"
            remainingSeconds = focusMinutes * 60
            updateNotification()
            notifyState()
        }
    }

    fun pauseTracking() {
        isTracking = false
        updateNotification()
        notifyState()
    }

    fun resumeTracking() {
        isTracking = true
        updateNotification()
        notifyState()
    }

    fun getStateMap(): Map<String, Any> {
        return mapOf(
            "isRunning" to (isTracking && isScreenOn),
            "isTracking" to isTracking,
            "isScreenOn" to isScreenOn,
            "session" to session,
            "remainingSeconds" to remainingSeconds,
            "totalSeconds" to if (session == "focus") (focusMinutes * 60) else breakSeconds,
            "focusMinutes" to focusMinutes,
            "breakSeconds" to breakSeconds,
            "breaksToday" to breaksCompletedToday
        )
    }

    private fun notifyState() {
        val state = getStateMap()
        listener?.invoke(state)
    }

    private fun getIntSafely(prefs: SharedPreferences, key: String, defaultVal: Int): Int {
        return try {
            val v = prefs.all[key]
            when (v) {
                is Number -> v.toInt()
                is String -> v.toIntOrNull() ?: defaultVal
                else -> defaultVal
            }
        } catch (_: Exception) {
            defaultVal
        }
    }

    private fun loadPreferences() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        focusMinutes = getIntSafely(prefs, "flutter.focus_minutes", 20)
        breakSeconds = getIntSafely(prefs, "flutter.break_seconds", 20)
        if (remainingSeconds == 20 * 60) {
            remainingSeconds = focusMinutes * 60
        }

        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val savedDate = prefs.getString("flutter.break_date", "") ?: ""
        if (savedDate == today) {
            breaksCompletedToday = getIntSafely(prefs, "flutter.breaks_today", 0)
        } else {
            breaksCompletedToday = 0
            prefs.edit().putString("flutter.break_date", today).putLong("flutter.breaks_today", 0L).apply()
        }
    }

    private fun saveDailyCounter() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        prefs.edit().putString("flutter.break_date", today).putLong("flutter.breaks_today", breaksCompletedToday.toLong()).apply()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)

            val channel = NotificationChannel(
                CHANNEL_ID,
                "20-20-20 Eye Care",
                NotificationManager.IMPORTANCE_LOW // Silent notification
            ).apply {
                description = "Monitors screen-on time and notifies when it is time for an eye break"
                setSound(null, null)
                enableVibration(false)
            }
            manager.createNotificationChannel(channel)

            val breakChannel = NotificationChannel(
                BREAK_CHANNEL_ID,
                "20-20-20 Break Alert",
                NotificationManager.IMPORTANCE_HIGH // High importance for full-screen overlay
            ).apply {
                description = "Displays the full-screen 20-second break overlay over other apps"
                setSound(null, null)
                enableVibration(false)
            }
            manager.createNotificationChannel(breakChannel)
        }
    }

    private fun buildNotification(isBreak: Boolean = (session == "break")): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("auto_break_overlay", true)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val minutes = remainingSeconds / 60
        val seconds = remainingSeconds % 60
        val formattedTime = String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds)

        val title: String
        val content: String

        if (isBreak) {
            title = "Eye Break Time! Look 20 ft away"
            content = "Break in progress • ${remainingSeconds}s remaining"
        } else if (!isTracking) {
            title = "20·20·20 Eye Care (Paused)"
            content = "Tracking paused • ${formattedTime} remaining"
        } else if (!isScreenOn) {
            title = "20·20·20 Eye Care"
            content = "Screen off • Timer reset to $formattedTime"
        } else {
            title = "20·20·20 Eye Care Active"
            content = "Screen on • $formattedTime until next break"
        }

        val targetChannel = if (isBreak) BREAK_CHANNEL_ID else CHANNEL_ID

        val builder = NotificationCompat.Builder(this, targetChannel)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(applicationInfo.icon)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(if (isBreak) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_LOW)
            .setCategory(if (isBreak) NotificationCompat.CATEGORY_ALARM else NotificationCompat.CATEGORY_SERVICE)

        if (isBreak) {
            builder.setFullScreenIntent(pendingIntent, true)
        }

        return builder.build()
    }

    private fun updateNotification(isBreak: Boolean = (session == "break")) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(isBreak))
    }
}
