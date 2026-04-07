import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ads/remote_config_service.dart';
import 'media_download_service.dart';
import '../daily_credit_manager.dart';

enum CreationType { image, video }

enum GenerationStatus {
  processing,
  success,
  failed,
}

enum CreationCategory {
  interior,
  exterior,
  garden,
  textToImage,
  model3D,
  removeObject,
  replaceObject, 
  floorPlan,
  styleTransfer,
  custom,
}

extension CreationCategoryX on CreationCategory {
  FeatureType get featureType {
    switch (this) {
      case CreationCategory.interior: return FeatureType.interior;
      case CreationCategory.exterior: return FeatureType.exterior;
      case CreationCategory.garden: return FeatureType.garden;
      case CreationCategory.textToImage: return FeatureType.imageGeneration;
      case CreationCategory.model3D: return FeatureType.object2dTo3d;
      case CreationCategory.removeObject: return FeatureType.objectRemove;
      case CreationCategory.replaceObject: return FeatureType.objectReplace;
      case CreationCategory.floorPlan: return FeatureType.floorPlan;
      case CreationCategory.styleTransfer: return FeatureType.styleTransfer;
      case CreationCategory.custom: return FeatureType.videoGeneration;
    }
  }
}

class MyCreation {
  final String id;
  final CreationType type;
  final CreationCategory category;
  final String mediaUrl; // generated → prefer local path after download
  final String? originalMediaUrl; // input image → prefer local
  final String? thumbnailPath; // local path to thumbnail
  final String? thumbnailUrl; // remote url to thumbnail
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final bool isDownloaded;
  final GenerationStatus status;
  final String? taskId;
  final bool creditDeducted;
  final bool creditRefunded;
  final String? refundReason;

  MyCreation({
    required this.id,
    required this.type,
    required this.category,
    required this.mediaUrl,
    this.originalMediaUrl,
    this.thumbnailPath,
    this.thumbnailUrl,
    required this.createdAt,
    this.metadata,
    this.isDownloaded = false,
    this.status = GenerationStatus.success,
    this.taskId,
    this.creditDeducted = false,
    this.creditRefunded = false,
    this.refundReason,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'category': category.name,
    'mediaUrl': mediaUrl,
    'originalMediaUrl': originalMediaUrl,
    'thumbnailPath': thumbnailPath,
    'thumbnailUrl': thumbnailUrl,
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
    'isDownloaded': isDownloaded,
    'status': status.name,
    'taskId': taskId,
    'creditDeducted': creditDeducted,
    'creditRefunded': creditRefunded,
    'refundReason': refundReason,
  };

  factory MyCreation.fromJson(Map<String, dynamic> json) {
    return MyCreation(
      id: json['id'] as String,
      type: CreationType.values.byName(json['type'] as String),
      category: CreationCategory.values.byName(json['category'] as String),
      mediaUrl: json['mediaUrl'] as String,
      originalMediaUrl: json['originalMediaUrl'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      status: json['status'] != null 
          ? GenerationStatus.values.byName(json['status'] as String)
          : GenerationStatus.success,
      taskId: json['taskId'] as String?,
      creditDeducted: json['creditDeducted'] as bool? ?? false,
      creditRefunded: json['creditRefunded'] as bool? ?? false,
      refundReason: json['refundReason'] as String?,
    );
  }
}

class MyCreationsService {
  static const String _storageKey = 'all_my_creations_v3'; // ← bump version after big change

  static List<MyCreation>? _cachedList;
  static final ValueNotifier<int> creationsChangeNotifier = ValueNotifier<int>(0);

  static Future<MyCreation?> saveGeneratedCreation({
    required CreationType type,
    required CreationCategory category,
    required String mediaUrl,
    String? originalMediaUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('📥 Centrally saving generated creation: $category');

      // 1. Download Media & Thumbnail
      final downloaded = await MediaDownloadService.downloadCreationMedia(
        mediaUrl: mediaUrl,
        thumbUrl: thumbnailUrl ?? (type == CreationType.image ? mediaUrl : originalMediaUrl),
      );

      if (downloaded.mediaFile == null) {
        debugPrint('❌ Critical: Failed to download media. Generation treated as failed.');
        return null;
      }

      // 2. Prepare MyCreation object
      final timestamp = DateTime.now();
      final creation = MyCreation(
        id: timestamp.millisecondsSinceEpoch.toString(),
        type: type,
        category: category,
        mediaUrl: downloaded.mediaFile!.path, // Use local path
        originalMediaUrl: originalMediaUrl,
        thumbnailPath: downloaded.thumbFile?.path, // Use local thumb path
        thumbnailUrl: thumbnailUrl,
        createdAt: timestamp,
        metadata: metadata,
        isDownloaded: true,
      );

      // 3. Save to storage
      await saveCreation(creation);
      
      return creation;
    } catch (e) {
      debugPrint('❌ Error in saveGeneratedCreation: $e');
      return null;
    }
  }

  static Future<void> saveCreation(MyCreation creation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final creations = await getCreations();

      // Prevent duplicates by mediaUrl if it's already a full path, or by taskId
      final exists = creations.any((c) => 
        (c.mediaUrl == creation.mediaUrl && c.mediaUrl.isNotEmpty) || 
        (c.taskId != null && c.taskId == creation.taskId)
      );
      
      if (exists && creation.status != GenerationStatus.processing) {
        debugPrint('Updating existing creation: ${creation.taskId ?? creation.id}');
        final index = creations.indexWhere((c) => 
          (c.mediaUrl == creation.mediaUrl && c.mediaUrl.isNotEmpty) || 
          (c.taskId != null && c.taskId == creation.taskId)
        );
        if (index != -1) {
          creations[index] = creation;
        }
      } else if (!exists) {
        creations.insert(0, creation); // newest first
      }

      final jsonList = creations.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
      _cachedList = creations;
      
      debugPrint('Saved creation: ${creation.type.name} – ${creation.category.name} (Status: ${creation.status.name})');
      creationsChangeNotifier.value++;
    } catch (e) {
      debugPrint('Error saving creation: $e');
    }
  }

  static Future<MyCreation?> saveProcessingCreation({
    required CreationType type,
    required CreationCategory category,
    required String taskId,
    String? originalMediaUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final timestamp = DateTime.now();
      final creation = MyCreation(
        id: timestamp.millisecondsSinceEpoch.toString(),
        type: type,
        category: category,
        mediaUrl: '', // empty until done
        originalMediaUrl: originalMediaUrl,
        createdAt: timestamp,
        metadata: metadata,
        status: GenerationStatus.processing,
        taskId: taskId,
        isDownloaded: false,
        creditDeducted: true, // Mark as deducted when initially processing successfully
        creditRefunded: false,
      );

      await saveCreation(creation);
      return creation;
    } catch (e) {
      debugPrint('❌ Error saving processing creation: $e');
      return null;
    }
  }

  static Future<void> updateCreationStatus(String taskId, GenerationStatus status, {String? mediaUrl, String? thumbnailPath}) async {
    final creations = await getCreations();
    final index = creations.indexWhere((c) => c.taskId == taskId);
    if (index == -1) return;

    final old = creations[index];
    final updated = MyCreation(
      id: old.id,
      type: old.type,
      category: old.category,
      mediaUrl: mediaUrl ?? old.mediaUrl,
      originalMediaUrl: old.originalMediaUrl,
      thumbnailPath: thumbnailPath ?? old.thumbnailPath,
      thumbnailUrl: old.thumbnailUrl,
      createdAt: old.createdAt,
      metadata: old.metadata,
      isDownloaded: mediaUrl != null,
      status: status,
      taskId: old.taskId,
      creditDeducted: old.creditDeducted,
      creditRefunded: old.creditRefunded,
      refundReason: old.refundReason,
    );

    creations[index] = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(creations.map((c) => c.toJson()).toList()));

    _cachedList = creations;
    creationsChangeNotifier.value++;
  }

  static Future<List<MyCreation>> getCreations() async {
    if (_cachedList != null) return _cachedList!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedList = jsonList.map((json) => MyCreation.fromJson(json)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // ensure newest first

      return _cachedList!;
    } catch (e) {
      debugPrint('Error reading creations: $e');
      return [];
    }
  }

  static Future<void> deleteByTaskId(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final creations = await getCreations();
      creations.removeWhere((c) => c.taskId == taskId);

      final jsonList = creations.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));

      _cachedList = creations;
      debugPrint('Deleted creation by taskId: $taskId');
      creationsChangeNotifier.value++;
    } catch (e) {
      debugPrint('Error deleting creation by taskId: $e');
    }
  }

  static Future<void> deleteCreation(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final creations = await getCreations();
      creations.removeWhere((c) => c.id == id);

      final jsonList = creations.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));

      _cachedList = creations;
      debugPrint('Deleted creation: $id');
      creationsChangeNotifier.value++;
    } catch (e) {
      debugPrint('Error deleting creation: $e');
    }
  }

  static Future<void> markAsDownloaded(String id, String newLocalPath) async {
    final creations = await getCreations();
    final index = creations.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final old = creations[index];
    final updated = MyCreation(
      id: old.id,
      type: old.type,
      category: old.category,
      mediaUrl: newLocalPath,
      originalMediaUrl: old.originalMediaUrl,
      thumbnailPath: old.thumbnailPath,
      thumbnailUrl: old.thumbnailUrl,
      createdAt: old.createdAt,
      metadata: old.metadata,
      isDownloaded: true,
      status: old.status,
      taskId: old.taskId,
    );

    creations[index] = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(creations.map((c) => c.toJson()).toList()));

    _cachedList = creations;
    creationsChangeNotifier.value++;
  }

  static Future<void> markAsRefunded(String taskId, String reason) async {
    try {
      final creations = await getCreations();
      final index = creations.indexWhere((c) => c.taskId == taskId);
      if (index == -1) return;

      final old = creations[index];
      if (old.creditRefunded) {
        debugPrint('⚠️ Task $taskId already refunded. Skipping.');
        return;
      }

      final updated = MyCreation(
        id: old.id,
        type: old.type,
        category: old.category,
        mediaUrl: old.mediaUrl,
        originalMediaUrl: old.originalMediaUrl,
        thumbnailPath: old.thumbnailPath,
        thumbnailUrl: old.thumbnailUrl,
        createdAt: old.createdAt,
        metadata: old.metadata,
        isDownloaded: old.isDownloaded,
        status: GenerationStatus.failed,
        taskId: old.taskId,
        creditDeducted: old.creditDeducted,
        creditRefunded: true,
        refundReason: reason,
      );

      creations[index] = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(creations.map((c) => c.toJson()).toList()));
      _cachedList = creations;
      creationsChangeNotifier.value++;

      // Actually refund the credit
      await DailyCreditManager.refundCredit(1);
      debugPrint('💰 Credit Refunded for Task $taskId (Reason: $reason)');
    } catch (e) {
      debugPrint('❌ Error marking as refunded: $e');
    }
  }

  static bool isVideoProcessingSync() {
    if (_cachedList == null) return false;
    return _cachedList!.any((c) => c.type == CreationType.video && c.status == GenerationStatus.processing);
  }
}
