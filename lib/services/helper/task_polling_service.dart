import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../ads/remote_config_service.dart';

/// Central service for common API operations:
/// - Image Uploading (Temp storage)
/// - Task Polling (checking status)
/// - Image Downloading
class TaskPollingService {
  static const String _baseUrl = 'https://api.kie.ai/api/v1';
  static const String _apiFreeBaseUrl = 'https://api.apifree.ai/v1';

  // 🔹 TESTING MODE
  static const bool TESTING_MODE = false;

  /// Upload image to temporary storage and get URL
  static Future<String?> uploadImage(File imageFile) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('📤 Uploading image to tmpfiles.org... (Attempt $attempt/$maxRetries)');

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://tmpfiles.org/api/v1/upload'),
        );

        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

        var response = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Upload timeout');
          },
        );
        var responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(responseData);
          String url = jsonResponse['data']['url'];
          // Convert tmpfiles.org URL to direct download URL
          url = url.replaceAll('tmpfiles.org/', 'tmpfiles.org/dl/');
          debugPrint('✅ Image uploaded: $url');
          return url;
        } else {
          debugPrint('❌ Upload failed: ${response.statusCode}');
          if (attempt < maxRetries) {
            debugPrint('⏳ Retrying in 2 seconds...');
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          return null;
        }
      } catch (e) {
        debugPrint('❌ Upload error (Attempt $attempt/$maxRetries): $e');
        if (attempt < maxRetries) {
          debugPrint('⏳ Retrying in 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
        } else {
          debugPrint('❌ All upload attempts failed');
          return null;
        }
      }
    }
    return null;
  }

  /// Download image from URL to local file path
  static Future<File?> downloadImage(String url, String savePath) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final file = File(savePath);
        
        // Ensure parent directory exists
        final parentDir = file.parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }

        try {
          await file.writeAsBytes(response.bodyBytes, flush: true);
          return file;
        } on FileSystemException catch (e) {
          if (e.message.contains('No space left on device') || e.osError?.errorCode == 28) {
             debugPrint('❌ Disk full: ${e.message}');
             throw Exception('Disk full. Please free up some space.');
          } else if (e.message.contains('Permission denied') || e.osError?.errorCode == 13) {
             debugPrint('❌ Permission denied: ${e.message}');
             throw Exception('Storage permission denied.');
          }
          rethrow;
        }
      } else {
        debugPrint('❌ Download failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Download error: $e');
      if (e is Exception) rethrow;
      return null;
    }
  }

  /// Query KIE API task status
  static Future<Map<String, dynamic>?> queryKieTask(String taskId, FeatureType feature) async {
     // 🔹 MOCK FLOW
    if (TESTING_MODE && taskId.startsWith('fake_task_result_start-')) {
       debugPrint('🚧 TESTING MODE: Simulating Polling Success (KIE)...');
       final originalUrl = taskId.replaceFirst('fake_task_result_start-', '');
       await Future.delayed(const Duration(milliseconds: 500));
       return {
         'state': 'success',
         'resultJson': json.encode({
           'resultUrls': [originalUrl]
         }),
       };
    }

    try {
      final apiKey = RemoteConfigService.getKieApiKey(feature);
      final response = await http.get(
        Uri.parse('$_baseUrl/jobs/recordInfo?taskId=$taskId'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          debugPrint('🔍 Status: ${data['data']['state']}');
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error querying task: $e');
      return null;
    }
  }

  /// Query APIFree task result
  static Future<Map<String, dynamic>?> queryApiFreeTask(String requestId, FeatureType feature) async {
    // 🔹 MOCK FLOW
    if (TESTING_MODE && requestId.startsWith('fake_task_result_start-')) {
      debugPrint('🚧 TESTING MODE: Simulating Polling Success...');
      final originalUrl = requestId.replaceFirst('fake_task_result_start-', '');
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'status': 'success',
        'image_list': [originalUrl], 
      };
    }

    try {
      final apiFreeKey = RemoteConfigService.getApiFreeKey(feature);
      final response = await http.get(
        Uri.parse('$_apiFreeBaseUrl/image/$requestId/result'),
        headers: {'Authorization': 'Bearer $apiFreeKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          return data['resp_data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error querying APIFree task: $e');
      return null;
    }
  }

  /// Query Video task status and result
  static Future<Map<String, dynamic>?> queryVideoTask(String requestId, FeatureType feature) async {
    try {
      final apiFreeKey = RemoteConfigService.getApiFreeKey(feature);
      final statusResp = await http.get(
        Uri.parse('$_apiFreeBaseUrl/video/$requestId/status'),
        headers: {'Authorization': 'Bearer $apiFreeKey'},
      );

      if (statusResp.statusCode == 200) {
        final statusData = json.decode(statusResp.body);
        if (statusData['code'] == 200) {
          final status = statusData['resp_data']?['status'];
          
          if (status == 'success') {
            final resultResp = await http.get(
              Uri.parse('$_apiFreeBaseUrl/video/$requestId/result'),
              headers: {'Authorization': 'Bearer $apiFreeKey'},
            );
            
            if (resultResp.statusCode == 200) {
              final resultData = json.decode(resultResp.body);
              if (resultData['code'] == 200) {
                final videoList = resultData['resp_data']?['video_list'] as List?;
                return {
                  'status': 'success',
                  'url': (videoList != null && videoList.isNotEmpty) ? videoList[0] : null,
                };
              }
            }
          } else {
            return {
              'status': status,
            };
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error querying video task: $e');
      return null;
    }
  }
}
