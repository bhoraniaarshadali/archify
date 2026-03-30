import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:project_home_decor/services/helper/task_polling_service.dart';
import 'package:workmanager/workmanager.dart';
import '../../navigation/app_navigator.dart';
import '../../screens/creations/my_creations_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../../ads/remote_config_service.dart';
import 'media_download_service.dart';
import 'my_creations_service.dart';
import 'background_task_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Native background task started: $task");
    
    // Initialize Firebase and RemoteConfig for background isolate
    bool initSuccess = false;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Background Firebase initialized");
      await RemoteConfigService.init();
      debugPrint("✅ Background RemoteConfig initialized");
      initSuccess = true;
    } catch (e) {
      debugPrint("❌ Background Firebase/RemoteConfig init error: $e");
    }

    if (!initSuccess) {
       debugPrint("⚠️ Background task cannot proceed without Firebase. Retrying in next cycle.");
       return Future.value(false);
    }

    final taskId = inputData?['taskId'] as String?;
    final typeStr = inputData?['type'] as String?;
    final categoryStr = inputData?['category'] as String?;

    if (taskId == null) return Future.value(true);

    final type = CreationType.values.byName(typeStr ?? 'image');
    final category = CreationCategory.values.byName(categoryStr ?? 'interior');

    try {
      final manager = BackgroundGenerationManager.instance;
      
      bool isDone = false;
      int attempts = 0;
      const maxAttempts = 12; // 12 * 10s = 2 minutes (More conservative for background)

      while (!isDone && attempts < maxAttempts) {
        isDone = await manager.pollAndProcessTask(taskId, type, category);
        if (!isDone) {
          attempts++;
          await Future.delayed(const Duration(seconds: 10));
        }
      }
      
      // If still not done, return false to let Workmanager reschedule later
      return Future.value(isDone);
    } catch (e) {
      debugPrint("Background task error: $e");
      return Future.value(false);
    }
  });
}

class TaskUpdate {
  final String taskId;
  final GenerationStatus status;
  final String? mediaUrl;

  TaskUpdate(this.taskId, this.status, {this.mediaUrl});
}

class BackgroundGenerationManager {
  static final BackgroundGenerationManager instance = BackgroundGenerationManager._internal();
  BackgroundGenerationManager._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final Set<String> _completedTasks = {};

  final StreamController<TaskUpdate> _taskUpdatesController = StreamController<TaskUpdate>.broadcast();
  Stream<TaskUpdate> get taskUpdates => _taskUpdatesController.stream;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload == 'my_creations') {
          AppNavigator.navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const MyCreationsScreen()),
          );
        }
      },
    );

    // Bridge NEW task service updates to OLD stream for compatibility
    BackgroundTaskService.instance.taskUpdates.listen((task) {
      GenerationStatus status = GenerationStatus.processing;
      if (task.isSuccess) status = GenerationStatus.success;
      if (task.isFailed) status = GenerationStatus.failed;
      
      _taskUpdatesController.add(TaskUpdate(
        task.taskId,
        status,
        mediaUrl: task.mediaLink,
      ));
    });

    // 2. Initialize Workmanager
    try {
       await Workmanager().initialize(
        callbackDispatcher,
      );
    } catch (e) {
      debugPrint('Failed to initialize Workmanager: $e');
    }

    _initialized = true;
  }

  /// Attach a task to background processing
  Future<void> attach(String taskId, CreationType type, CreationCategory category) async {
    /* 
    // OLD POLLING LOGIC
    if (_activeTimers.containsKey(taskId)) {
      debugPrint('⚠️ Task already attached: $taskId');
      return;
    }
    await init();

    debugPrint('🚀 Attaching task $taskId to background manager ($type, $category)');

    // Start immediate polling in current process (for when app is open)
    _startPolling(taskId, type, category);

    // Also register background task (for when app is closed)
    try {
      await Workmanager().registerOneOffTask(
        taskId,
        "processGenerationTask",
        inputData: {
          'taskId': taskId,
          'type': type.name,
          'category': category.name,
        },
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      debugPrint('Workmanager registration failed: $e');
    }
    */

    // NEW LOGIC
    debugPrint('[Task Created] task_id=$taskId type=${type.name}');
    
    final task = TaskModel(
      taskId: taskId,
      taskType: type.name,
      featureType: category.featureType,
    );
    
    await BackgroundTaskService.instance.saveTask(task);
    BackgroundTaskService.instance.startPolling(taskId, type.name, category.featureType);
  }

  /*
  final Map<String, Timer> _activeTimers = {};

  void _startPolling(String taskId, CreationType type, CreationCategory category) {
    if (_activeTimers.containsKey(taskId)) return;

    debugPrint('⏱️ Starting Timer polling for $taskId');
    // Set timer before running to prevent duplicates
    _activeTimers[taskId] = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final done = await pollAndProcessTask(taskId, type, category);
      if (done) {
        timer.cancel();
        _activeTimers.remove(taskId);
      }
    });
  }

  void _stopPolling(String taskId) {
    _activeTimers[taskId]?.cancel();
    _activeTimers.remove(taskId);
    debugPrint('⏹️ Polling stopped for $taskId');
  }

  /// Resume all tasks that are currently in 'processing' state
  Future<void> resumeAllPendingTasks() async {
    final creations = await MyCreationsService.getCreations();
    final pending = creations.where((c) => c.status == GenerationStatus.processing && c.taskId != null).toList();
    
    debugPrint('🔄 Resuming ${pending.length} pending tasks...');
    for (final creation in pending) {
      _startPolling(creation.taskId!, creation.type, creation.category);
    }
  }
  */


  // Keep this for background isolate (Workmanager) compatibility
  Future<bool> pollAndProcessTask(String taskId, CreationType type, CreationCategory category) async {
    try {
      Map<String, dynamic>? result;

      if (type == CreationType.video) {
        result = await TaskPollingService.queryVideoTask(taskId, category.featureType);
      } else {
        final kieResult = await TaskPollingService.queryKieTask(taskId, category.featureType);
        final apiFreeResult = kieResult == null ? await TaskPollingService.queryApiFreeTask(taskId, category.featureType) : null;
        result = kieResult ?? apiFreeResult;
      }
      
      // If task not found but it was marked as processing, keep polling for a while
      if (result == null) return false;

      final state = result['state'] ?? result['status'];
      debugPrint('🔍 Task $taskId Status: $state');

      // 🛑 ISOLATE-SAFE CHECK: Check database status directly
      final creations = await MyCreationsService.getCreations();
      final current = creations.where((c) => c.taskId == taskId).firstOrNull;

      if (current == null) {
        debugPrint('⚠️ Task $taskId not found in database. Stopping.');
        return true;
      }

      if (current.status != GenerationStatus.processing) {
        debugPrint('⏹️ Task $taskId already processed (Status: ${current.status}). Stopping.');
        return true;
      }

      // 🔒 ATOMIC LOCK: If another isolate is already downloading
      if (current.mediaUrl == 'PENDING') {
        debugPrint('⏳ Task $taskId download already in progress by another isolate.');
        return false;
      }

      if (state == 'success' || state == 'COMPLETED' || state == 'succeeded') {
        String? mediaUrl = _extractUrl(result);

        if (mediaUrl != null) {
          // 🔒 LOCKING: Set local variable AND DB status to PENDING to prevent parallel downloads
          _completedTasks.add(taskId);
          await MyCreationsService.updateCreationStatus(taskId, GenerationStatus.processing, mediaUrl: 'PENDING');

          debugPrint('✅ Task Success! Starting single download flow for $taskId');

          final downloaded = await MediaDownloadService.downloadCreationMedia(
            mediaUrl: mediaUrl,
            thumbUrl: type == CreationType.image ? mediaUrl : null,
          );

          if (downloaded.mediaFile != null) {
            await MyCreationsService.updateCreationStatus(
              taskId,
              GenerationStatus.success,
              mediaUrl: downloaded.mediaFile!.path,
              thumbnailPath: downloaded.thumbFile?.path,
            );

            _taskUpdatesController.add(TaskUpdate(
                taskId,
                GenerationStatus.success,
                mediaUrl: downloaded.mediaFile!.path
            ));

            await _showCompletionNotification(taskId, category);
            return true;
          }
        }
      } else if (state == 'failed' || state == 'fail' || state == 'ERROR' || state == 'error') {
        await MyCreationsService.deleteByTaskId(taskId);
        _taskUpdatesController.add(TaskUpdate(taskId, GenerationStatus.failed));
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error polling background task $taskId: $e');
      return false;
    }
  }

  String? _extractUrl(Map<String, dynamic> result) {
    try {
      if (result['image_list'] != null && (result['image_list'] as List).isNotEmpty) {
        return result['image_list'][0];
      }
      
      final resultJsonStr = result['resultJson'] as String?;
      if (resultJsonStr != null && resultJsonStr.isNotEmpty) {
        final decoded = json.decode(resultJsonStr);
        if (decoded is Map) {
          if (decoded['resultUrls'] != null && (decoded['resultUrls'] as List).isNotEmpty) {
            return decoded['resultUrls'][0];
          }
        } else if (decoded is List && decoded.isNotEmpty) {
          return decoded[0];
        }
      }

      if (result['result'] != null) return result['result'];
      if (result['url'] != null) return result['url'];
      
    } catch (e) {
      debugPrint('Error extracting URL: $e');
    }
    return null;
  }

  Future<void> _showCompletionNotification(String taskId, CreationCategory category) async {
    await init();
    
    final categoryName = category.name[0].toUpperCase() + category.name.substring(1);
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'generation_completed',
      'Design Generation',
      channelDescription: 'Notifications for completed designs',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id: taskId.hashCode,
      title: 'Your $categoryName design is ready! 🎉',
      body: 'Tap to view in My Creations',
      notificationDetails: platformChannelSpecifics,
      payload: 'my_creations',
    );
  }
}


