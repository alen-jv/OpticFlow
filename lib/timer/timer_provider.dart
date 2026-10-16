import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_type.dart';

/// Default durations for the 20-20-20 rule.
const int kDefaultFocusMinutes = 20;
const int kDefaultBreakSeconds = 20;

class TimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const MethodChannel _channel =
      MethodChannel('com.example.opticflow/service');

  // ── State ──────────────────────────────────────────────────────────────────
  SessionType _session = SessionType.focus;
  int _remainingSeconds = kDefaultFocusMinutes * 60;
  bool _isRunning = false;
  bool _isScreenOn = true;
  bool _backgroundServiceEnabled = true;
  bool _overlayPermissionGranted = false;
  bool _autoLaunchedForBreak = false;
  bool _wasRunningBeforeBackground = false;
  int _breaksCompletedToday = 0;
  Timer? _ticker;
  late SharedPreferences _prefs;
  bool _initialized = false;

  // ── Custom interval settings ───────────────────────────────────────────────
  int _focusMinutes = kDefaultFocusMinutes;
  int _breakSeconds = kDefaultBreakSeconds;

  // ── Getters ────────────────────────────────────────────────────────────────
  SessionType get session => _session;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isScreenOn => _isScreenOn;
  bool get backgroundServiceEnabled => _backgroundServiceEnabled;
  bool get overlayPermissionGranted => _overlayPermissionGranted;
  bool get autoLaunchedForBreak => _autoLaunchedForBreak;
  int get breaksCompletedToday => _breaksCompletedToday;
  bool get initialized => _initialized;
  int get focusMinutes => _focusMinutes;
  int get breakSeconds => _breakSeconds;

  int get focusTotalSeconds => _focusMinutes * 60;
  int get breakTotalSeconds => _breakSeconds;

  /// Total duration of the current session in seconds.
  int get totalSeconds =>
      _session == SessionType.focus ? focusTotalSeconds : breakTotalSeconds;

  /// Progress value [0.0, 1.0] where 1.0 = full (time remaining).
  double get progress =>
      totalSeconds == 0 ? 0 : (_remainingSeconds / totalSeconds).clamp(0.0, 1.0);

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    _loadDailyCounter();

    _remainingSeconds = focusTotalSeconds;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    if (defaultTargetPlatform == TargetPlatform.android) {
      _channel.setMethodCallHandler(_handleNativeCall);
      await checkOverlayPermission();

      if (_backgroundServiceEnabled) {
        try {
          await _channel.invokeMethod('requestNotificationPermission');
          await _channel.invokeMethod('startService');
          await _syncFromNativeService();
        } catch (e) {
          debugPrint('Error starting background service: $e');
        }
      }
    }

    notifyListeners();
  }

  Future<void> checkOverlayPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final res = await _channel.invokeMethod<bool>('checkOverlayPermission');
        _overlayPermissionGranted = res ?? false;
        notifyListeners();
      } catch (e) {
        debugPrint('Error checking overlay permission: $e');
      }
    }
  }

  Future<void> requestOverlayPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod('requestOverlayPermission');
      } catch (e) {
        debugPrint('Error requesting overlay permission: $e');
      }
    }
  }

  Future<void> minimizeApp() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod('minimizeApp');
      } catch (e) {
        debugPrint('Error minimizing app: $e');
      }
    }
  }

  void _loadSettings() {
    _focusMinutes = _prefs.getInt('focus_minutes') ?? kDefaultFocusMinutes;
    _breakSeconds = _prefs.getInt('break_seconds') ?? kDefaultBreakSeconds;
    _backgroundServiceEnabled =
        _prefs.getBool('background_service_enabled') ?? true;
  }

  Future<void> _syncFromNativeService() async {
    try {
      final state = await _channel.invokeMapMethod<String, dynamic>('getState');
      if (state != null && state.isNotEmpty) {
        _applyStateFromNative(state);
      }
    } catch (e) {
      debugPrint('Error syncing state from native service: $e');
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onAutoBreakTriggered') {
      _autoLaunchedForBreak = true;
      notifyListeners();
    } else if (call.method == 'onScreenOff') {
      reset();
    } else if (call.method == 'onStateChanged') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      if (data['action'] == 'break_completed') {
        if (_autoLaunchedForBreak) {
          _autoLaunchedForBreak = false;
          minimizeApp();
        }
      }
      _applyStateFromNative(data);
    }
  }

  void _applyStateFromNative(Map<String, dynamic> data) {
    if (data.containsKey('session')) {
      _session = (data['session'] == 'break')
          ? SessionType.breakTime
          : SessionType.focus;
    }
    if (data.containsKey('remainingSeconds')) {
      _remainingSeconds = (data['remainingSeconds'] as num).toInt();
    }
    if (data.containsKey('isRunning')) {
      _isRunning = data['isRunning'] as bool;
    }
    if (data.containsKey('isScreenOn')) {
      _isScreenOn = data['isScreenOn'] as bool;
    }
    if (data.containsKey('focusMinutes')) {
      _focusMinutes = (data['focusMinutes'] as num).toInt();
    }
    if (data.containsKey('breakSeconds')) {
      _breakSeconds = (data['breakSeconds'] as num).toInt();
    }
    if (data.containsKey('breaksToday')) {
      _breaksCompletedToday = (data['breaksToday'] as num).toInt();
    }
    notifyListeners();
  }

  /// Toggle background screen-on tracking service on or off.
  Future<void> toggleBackgroundService(bool enabled) async {
    _backgroundServiceEnabled = enabled;
    await _prefs.setBool('background_service_enabled', enabled);

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        if (enabled) {
          await _channel.invokeMethod('requestNotificationPermission');
          await _channel.invokeMethod('startService');
          await _syncFromNativeService();
        } else {
          await _channel.invokeMethod('stopService');
          _pauseInternal();
        }
      } catch (e) {
        debugPrint('Error toggling background service: $e');
      }
    }
    notifyListeners();
  }

  /// Save custom intervals and reset the current session to apply them.
  Future<void> saveSettings({
    required int focusMinutes,
    required int breakSeconds,
  }) async {
    _focusMinutes = focusMinutes;
    _breakSeconds = breakSeconds;
    await _prefs.setInt('focus_minutes', focusMinutes);
    await _prefs.setInt('break_seconds', breakSeconds);

    if (_backgroundServiceEnabled &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod('updateSettings', {
          'focusMinutes': focusMinutes,
          'breakSeconds': breakSeconds,
        });
      } catch (e) {
        debugPrint('Error updating native settings: $e');
      }
    }

    // Reset so new durations take effect immediately.
    reset();
  }

  /// Loads and resets the daily counter if it's a new day.
  void _loadDailyCounter() {
    final savedDate = _prefs.getString('break_date') ?? '';
    final today = _todayKey();
    if (savedDate != today) {
      _prefs.setString('break_date', today);
      _prefs.setInt('breaks_today', 0);
      _breaksCompletedToday = 0;
    } else {
      _breaksCompletedToday = _prefs.getInt('breaks_today') ?? 0;
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ── App Lifecycle (Fallback for when background service is off) ───────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_backgroundServiceEnabled) {
      // The background service manages running state via SCREEN_ON/SCREEN_OFF events
      if (state == AppLifecycleState.resumed) {
        _syncFromNativeService();
      }
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_isRunning) {
        _wasRunningBeforeBackground = true;
        _pauseInternal();
      } else {
        _wasRunningBeforeBackground = false;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasRunningBeforeBackground) {
        _wasRunningBeforeBackground = false;
        start();
      }
    }
  }

  // ── Timer Controls ─────────────────────────────────────────────────────────

  void start() {
    if (_backgroundServiceEnabled &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        _channel.invokeMethod('resumeTimer');
      } catch (e) {
        debugPrint('Error resuming native timer: $e');
      }
      return;
    }

    if (_isRunning) return;
    _isRunning = true;
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    notifyListeners();
  }

  void pause() {
    if (_backgroundServiceEnabled &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        _channel.invokeMethod('pauseTimer');
      } catch (e) {
        debugPrint('Error pausing native timer: $e');
      }
      return;
    }

    _pauseInternal();
    notifyListeners();
  }

  void _pauseInternal() {
    _isRunning = false;
    _ticker?.cancel();
    _ticker = null;
  }

  void reset() {
    if (_backgroundServiceEnabled &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        _channel.invokeMethod('resetTimer');
      } catch (e) {
        debugPrint('Error resetting native timer: $e');
      }
    }

    _pauseInternal();
    _wasRunningBeforeBackground = false;
    _autoLaunchedForBreak = false;
    _session = SessionType.focus;
    _remainingSeconds = focusTotalSeconds;
    notifyListeners();
  }

  /// Manually dismiss an active break — skip to next focus session.
  void dismissBreak() {
    if (_session != SessionType.breakTime) return;

    if (_backgroundServiceEnabled &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        _channel.invokeMethod('skipBreak');
      } catch (e) {
        debugPrint('Error skipping break: $e');
      }
    }

    _pauseInternal();
    _session = SessionType.focus;
    _remainingSeconds = focusTotalSeconds;

    if (_autoLaunchedForBreak) {
      _autoLaunchedForBreak = false;
      minimizeApp();
    }

    notifyListeners();
  }

  void _onTick(Timer _) {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else {
      _onSessionComplete();
    }
  }

  /// Called when a session reaches zero in in-app ticker mode.
  void _onSessionComplete() {
    _pauseInternal();

    if (_session == SessionType.focus) {
      _session = SessionType.breakTime;
      _remainingSeconds = breakTotalSeconds;
    } else {
      _incrementBreakCounter();
      _session = SessionType.focus;
      _remainingSeconds = focusTotalSeconds;
    }

    notifyListeners();
  }

  void _incrementBreakCounter() {
    _breaksCompletedToday++;
    _prefs.setInt('breaks_today', _breaksCompletedToday);
    _prefs.setString('break_date', _todayKey());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }
}
