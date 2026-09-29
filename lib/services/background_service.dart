import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manages persistent background connections.
/// - Android: Foreground service with persistent notification.
/// - iOS: Background audio mode keeps the audio session alive.
class BackgroundService {
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// Initialize the foreground task system (call once at app startup).
  Future<void> init() async {
    if (!Platform.isAndroid) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'walkie_active_call',
        channelName: 'Walkie Connection',
        channelDescription: 'Active walkie-talkie connection',
        // DEFAULT importance so the notification shows in the status bar.
        // Foreground service notifications are inherently non-dismissible —
        // they cannot be swiped away while the service is running.
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        playSound: false,
        enableVibration: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
  }

  /// Request notification permission (Android 13+).
  /// Must be called before starting the foreground service.
  Future<void> _ensureNotificationPermission() async {
    if (!Platform.isAndroid) return;

    final status = await Permission.notification.status;
    if (!status.isGranted) {
      debugPrint('[BackgroundService] Requesting notification permission...');
      final result = await Permission.notification.request();
      debugPrint('[BackgroundService] Notification permission: $result');
    }
  }

  /// Start the foreground service (Android) / background audio (iOS).
  /// [targetName] is shown in the notification, e.g. "Connected to John"
  Future<void> startService(String targetName) async {
    if (_isRunning) {
      // Update the notification text if already running
      await _updateNotification(targetName);
      return;
    }

    if (Platform.isAndroid) {
      // Ensure notification permission before starting foreground service
      await _ensureNotificationPermission();
      await _startAndroidForegroundService(targetName);
    }
    // iOS: LiveKit's audio session + UIBackgroundModes: audio handles it

    _isRunning = true;
    debugPrint('[BackgroundService] Started for: $targetName');
  }

  /// Stop the foreground service and clear the notification.
  Future<void> stopService() async {
    if (!_isRunning) return;

    if (Platform.isAndroid) {
      debugPrint('[BackgroundService] Stopping foreground service...');
      await FlutterForegroundTask.stopService();
      debugPrint('[BackgroundService] Foreground service stopped');
    }

    _isRunning = false;
    debugPrint('[BackgroundService] Stopped');
  }

  /// Update the notification text (e.g. when switching connections).
  Future<void> _updateNotification(String targetName) async {
    if (Platform.isAndroid) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'Walkie',
        notificationText: 'Connected to $targetName',
      );
    }
  }

  Future<void> _startAndroidForegroundService(String targetName) async {
    debugPrint('[BackgroundService] Starting foreground service...');
    try {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Walkie',
        notificationText: 'Connected to $targetName',
        serviceId: 888,
        callback: _foregroundTaskCallback,
      );
      debugPrint('[BackgroundService] Foreground service started successfully');
    } catch (e) {
      debugPrint('[BackgroundService] Failed to start foreground service: $e');
    }
  }
}

/// Top-level callback required by flutter_foreground_task.
/// We don't need to run any Dart code in the service — LiveKit's
/// native audio handles everything. This just keeps the process alive.
@pragma('vm:entry-point')
void _foregroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_WalkieTaskHandler());
}

class _WalkieTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[ForegroundTask] Started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // No-op — we don't need periodic events.
    // The service just needs to stay alive.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[ForegroundTask] Destroyed');
  }
}
