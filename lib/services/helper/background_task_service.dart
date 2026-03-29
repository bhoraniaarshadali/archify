import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_polling_service.dart';
import 'media_download_service.dart';
import 'my_creations_service.dart';

class TaskModel {
  final String taskId;
  final String taskType; // "video" or "image"
  bool isSuccess;
  bool isProcessing;
  bool isFailed;
  String? mediaLink;
  String? thumbnailLink;
  int retryCount;

  TaskModel({
    required this.taskId,
    required this.taskType,
    this.isSuccess = false,
    this.isProcessing = true,
    this.isFailed = false,
    this.mediaLink,
    this.thumbnailLink,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'task_type': taskType,
        'is_success': isSuccess,
        'is_processing': isProcessing,
        'is_failed': isFailed,
        'media_link': mediaLink,
        'thumbnail_link': thumbnailLink,
        'retry_count': retryCount,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['task_id'],
      taskType: json['task_type'],
      isSuccess: json['is_success'] ?? false,
      isProcessing: json['is_processing'] ?? false,
      isFailed: json['is_failed'] ?? false,
      mediaLink: json['media_link'],
      thumbnailLink: json['thumbnail_link'],
      retryCount: json['retry_count'] ?? 0,
    );
  }
}

class BackgroundTaskService {
  static const String _storageKey = 'background_tasks_list';
  static final BackgroundTaskService instance = BackgroundTaskService._internal();
  BackgroundTaskService._internal();

  final Map<String, Timer> _activeTimers = {};
  final Set<String> _currentlyProcessing = {};
  final Map<String, int> _nullResultCount = {};
  final Map<String, int> _pollCount = {};
  
  // Stream for UI updates
  final StreamController<TaskModel> _taskUpdateController = StreamController<TaskModel>.broadcast();
  Stream<TaskModel> get taskUpdates => _taskUpdateController.stream;

  /// 📥 SAVE TASK
  Future<void> saveTask(TaskModel task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await getTasks();

    // Check if exists
    final index = tasks.indexWhere((t) => t.taskId == task.taskId);
    if (index != -1) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }

    await prefs.setString(_storageKey, json.encode(tasks.map((t) => t.toJson()).toList()));
    debugPrint('[State Saved] task_id=${task.taskId}');
    
    // Notify listeners
    _taskUpdateController.add(task);
  }


  /// 📤 GET ALL TASKS
  Future<List<TaskModel>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((j) => TaskModel.fromJson(j)).toList();
  }

  /// 🚀 START POLLING
  void startPolling(String taskId, String type) async {
    if (_activeTimers.containsKey(taskId)) {
      debugPrint('⚠️ Polling already active for $taskId');
      return;
    }

    debugPrint('[Polling Started] task_id=$taskId');

    _activeTimers[taskId] = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _pollTask(taskId, type, timer);
    });
  }

  /// 🔄 RESUME ALL PENDING TASKS
  Future<void> resumeTasks() async {
    final tasks = await getTasks();
    final pending = tasks.where((t) => t.isProcessing).toList();

    debugPrint('🔄 Resuming ${pending.length} background tasks...');
    for (final task in pending) {
      startPolling(task.taskId, task.taskType);
    }
  }

  /// 🔍 INTERNAL POLLING LOGIC
  Future<void> _pollTask(String taskId, String type, Timer timer) async {
    // 🛡️ Lock: Prevent concurrent polling for the same task
    if (_currentlyProcessing.contains(taskId)) return;
    _currentlyProcessing.add(taskId);

    try {
      final tasks = await getTasks();
      final taskIndex = tasks.indexWhere((t) => t.taskId == taskId);
      if (taskIndex == -1) {
        timer.cancel();
        _activeTimers.remove(taskId);
        _pollCount.remove(taskId);
        _nullResultCount.remove(taskId);
        return;
      }

      final task = tasks[taskIndex];

      // If already done, stop polling
      if (!task.isProcessing) {
        timer.cancel();
        _activeTimers.remove(taskId);
        _pollCount.remove(taskId);
        _nullResultCount.remove(taskId);
        return;
      }

      // Max Poll Timeout check (~10 mins at 3s interval)
      _pollCount[taskId] = (_pollCount[taskId] ?? 0) + 1;
      if ((_pollCount[taskId] ?? 0) >= 200) {
        debugPrint('[Task Timeout] task_id=$taskId');
        task.isProcessing = false;
        task.isSuccess = false;
        task.isFailed = true;
        await saveTask(task);
        await MyCreationsService.deleteByTaskId(taskId);
        timer.cancel();
        _activeTimers.remove(taskId);
        _pollCount.remove(taskId);
        _nullResultCount.remove(taskId);
        return;
      }

      Map<String, dynamic>? result;
      if (type == 'video') {
        result = await TaskPollingService.queryVideoTask(taskId);
      } else {
        // Try KIE first, then APIFree
        final kieResult = await TaskPollingService.queryKieTask(taskId);
        final apiFreeResult = kieResult == null ? await TaskPollingService.queryApiFreeTask(taskId) : null;
        result = kieResult ?? apiFreeResult;
      }

      if (result == null) {
        _nullResultCount[taskId] = (_nullResultCount[taskId] ?? 0) + 1;
        debugPrint('[Polling] task_id=$taskId null_count=${_nullResultCount[taskId]}');
        if ((_nullResultCount[taskId] ?? 0) >= 10) {
          debugPrint('[Task Failed] task_id=$taskId reason=10 consecutive null responses');
          task.isProcessing = false;
          task.isSuccess = false;
          task.isFailed = true;
          await saveTask(task);
          await MyCreationsService.deleteByTaskId(taskId);
          timer.cancel();
          _activeTimers.remove(taskId);
          _nullResultCount.remove(taskId);
          _pollCount.remove(taskId);
        }
        return;
      }
      
      // Reset null count on valid response
      _nullResultCount.remove(taskId);

      final state = result['state'] ?? result['status'];
      debugPrint('🔍 Task $taskId Status: $state');

      if (state == 'success' || state == 'COMPLETED' || state == 'succeeded') {
        String? mediaUrl = _extractUrl(result);

        if (mediaUrl != null) {
          debugPrint('[Task Success] task_id=$taskId media_link=$mediaUrl');
          
          task.isProcessing = false;
          task.isSuccess = true;
          task.isFailed = false;
          task.mediaLink = mediaUrl;
          
          // Silently download
          final downloaded = await MediaDownloadService.downloadCreationMedia(
            mediaUrl: mediaUrl,
            thumbUrl: type == 'image' ? mediaUrl : null,
          );

          if (downloaded.mediaFile != null) {
            task.mediaLink = downloaded.mediaFile!.path;
            task.thumbnailLink = downloaded.thumbFile?.path;
            
            await saveTask(task);

            // Sync with MyCreations
            await MyCreationsService.updateCreationStatus(
              taskId,
              GenerationStatus.success,
              mediaUrl: downloaded.mediaFile!.path,
              thumbnailPath: downloaded.thumbFile?.path,
            );
          } else {
            // Even if download fails, we save the latest task state
            await saveTask(task);
          }

          timer.cancel();
          _activeTimers.remove(taskId);
          _nullResultCount.remove(taskId);
          _pollCount.remove(taskId);
        }
      } else if (state == 'failed' || state == 'fail' || state == 'ERROR' || state == 'error') {
        debugPrint('[Task Failed] task_id=$taskId reason=$state');
        task.isProcessing = false;
        task.isSuccess = false;
        task.isFailed = true;
        await saveTask(task);

        // Remove from MyCreations if failed
        await MyCreationsService.deleteByTaskId(taskId);

        timer.cancel();
        _activeTimers.remove(taskId);
        _nullResultCount.remove(taskId);
        _pollCount.remove(taskId);
      } else {
        // Still processing - reset retry count if we got a valid response
        if (task.retryCount > 0) {
          task.retryCount = 0;
          await saveTask(task);
        }
      }
    } catch (e) {
      debugPrint('❌ Polling error for $taskId: $e');
    } finally {
      _currentlyProcessing.remove(taskId);
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
}
