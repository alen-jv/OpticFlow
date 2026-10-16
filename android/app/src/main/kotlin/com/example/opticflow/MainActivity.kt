package com.example.opticflow

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.opticflow/service"
    private var methodChannel: MethodChannel? = null

    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                runOnUiThread {
                    methodChannel?.invokeMethod("onScreenOff", null)
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        startEyeCareService()
                        result.success(true)
                    }
                    "stopService" -> {
                        stopEyeCareService()
                        result.success(true)
                    }
                    "isServiceRunning" -> {
                        result.success(EyeCareService.isRunning())
                    }
                    "getState" -> {
                        result.success(EyeCareService.instance?.getStateMap() ?: emptyMap<String, Any>())
                    }
                    "updateSettings" -> {
                        val focusMinutes = call.argument<Int>("focusMinutes") ?: 20
                        val breakSeconds = call.argument<Int>("breakSeconds") ?: 20
                        EyeCareService.instance?.updateSettings(focusMinutes, breakSeconds)
                        result.success(true)
                    }
                    "resetTimer" -> {
                        EyeCareService.instance?.resetTimer()
                        result.success(true)
                    }
                    "skipBreak" -> {
                        EyeCareService.instance?.skipBreak()
                        result.success(true)
                    }
                    "pauseTimer" -> {
                        EyeCareService.instance?.pauseTracking()
                        result.success(true)
                    }
                    "resumeTimer" -> {
                        EyeCareService.instance?.resumeTracking()
                        result.success(true)
                    }
                    "requestNotificationPermission" -> {
                        requestNotificationPermissionIfNeeded()
                        result.success(true)
                    }
                    "checkOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            result.success(Settings.canDrawOverlays(this@MainActivity))
                        } else {
                            result.success(true)
                        }
                    }
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(true)
                    }
                    "minimizeApp" -> {
                        moveTaskToBack(true)
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }

        EyeCareService.listener = { stateMap ->
            runOnUiThread {
                methodChannel?.invokeMethod("onStateChanged", stateMap)
            }
        }

        if (intent?.getBooleanExtra("auto_break_overlay", false) == true) {
            methodChannel?.invokeMethod("onAutoBreakTriggered", null)
        }

        val screenFilter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        registerReceiver(screenOffReceiver, screenFilter)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra("auto_break_overlay", false)) {
            methodChannel?.invokeMethod("onAutoBreakTriggered", null)
        }
    }

    private fun startEyeCareService() {
        requestNotificationPermissionIfNeeded()
        val prefs = getSharedPreferences(EyeCareService.PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.background_service_enabled", true).apply()

        val intent = Intent(this, EyeCareService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopEyeCareService() {
        val prefs = getSharedPreferences(EyeCareService.PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.background_service_enabled", false).apply()

        val intent = Intent(this, EyeCareService::class.java)
        stopService(intent)
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    101
                )
            }
        }
    }

    override fun onDestroy() {
        EyeCareService.listener = null
        try {
            unregisterReceiver(screenOffReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
