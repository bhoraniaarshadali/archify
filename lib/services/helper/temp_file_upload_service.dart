import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cloudinary File Upload Service
///
/// Handles uploading images to Cloudinary
/// - Reliable cloud storage
/// - Fast CDN delivery
/// - No expiry (permanent storage)
class TempFileUploadService {
  static const String _cloudName = 'dzwrgzete';
  static const String _uploadPreset = 'app_unsigned_upload';

  /// Upload image to Cloudinary and get URL
  ///
  /// Returns the secure HTTPS URL if successful, null otherwise
  /// Includes retry mechanism (2 attempts) for better reliability
  static Future<String?> uploadImage(File imageFile) async {
    const maxRetries = 2;

    // Log file info
    final fileSize = await imageFile.length();
    debugPrint('📦 File to upload: ${imageFile.path}');
    debugPrint(
      '📦 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
          '☁️ [Cloudinary] Uploading image... (Attempt $attempt/$maxRetries)',
        );

        // Verify file exists
        if (!await imageFile.exists()) {
          throw Exception('File does not exist: ${imageFile.path}');
        }

        final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        );

        final request = http.MultipartRequest('POST', uri);

        // Add upload preset (required for unsigned upload)
        request.fields['upload_preset'] = _uploadPreset;

        // Add file
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        );

        request.files.add(multipartFile);

        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('❌ Request timed out after 30 seconds');
            throw Exception('Upload timeout');
          },
        );

        final responseBody = await streamedResponse.stream.bytesToString();

        debugPrint('📊 Cloudinary status: ${streamedResponse.statusCode}');

        if (streamedResponse.statusCode == 200) {
          try {
            final jsonResponse = json.decode(responseBody);

            if (jsonResponse['secure_url'] != null) {
              final String imageUrl = jsonResponse['secure_url'];
              debugPrint('✅ Upload success: $imageUrl');
              return imageUrl;
            } else {
              debugPrint('❌ [Cloudinary] No secure_url in response');
              debugPrint('Response: $jsonResponse');
            }
          } catch (e) {
            debugPrint('❌ [Cloudinary] JSON parse error: $e');
          }
        } else {
          debugPrint(
            '❌ [Cloudinary] Upload failed with status: ${streamedResponse.statusCode}',
          );
          debugPrint('❌ [Cloudinary] Response body: $responseBody');
        }

        if (attempt < maxRetries) {
          debugPrint('⏳ Retrying Cloudinary in 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
      } catch (e, stackTrace) {
        debugPrint(
          '❌ [Cloudinary] Upload error (Attempt $attempt/$maxRetries): $e',
        );
        debugPrint('❌ [Cloudinary] Stack trace: $stackTrace');

        if (attempt < maxRetries) {
          debugPrint('⏳ Retrying Cloudinary in 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
        } else {
          debugPrint('❌ [Cloudinary] All upload attempts failed');
        }
      }
    }

    // fallback to tmpfiles.org
    debugPrint('⚠️ Falling back to tmpfiles.org...');
    return await _uploadToTmpFiles(imageFile);
  }

  /// Internal fallback method for uploading to tmpfiles.org
  static Future<String?> _uploadToTmpFiles(File imageFile) async {
    const String uploadUrl = 'https://tmpfiles.org/api/v1/upload';
    try {
      debugPrint('📤 [TmpFiles] Falling back to tmpfiles.org...');
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('[TmpFiles] Upload timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // tmpfiles.org returns http:// URL
          // Convert to https:// for compatibility
          String url = data['data']['url'];
          url = url.replaceFirst('http://', 'https://');
          // Add /dl/ after domain to get direct download link (raw file access)
          if (url.contains('tmpfiles.org/')) {
            url = url.replaceFirst('tmpfiles.org/', 'tmpfiles.org/dl/');
          }
           debugPrint('✅ [TmpFiles] Fallback upload success: $url');
          return url;
        }
        debugPrint('❌ [TmpFiles] Upload failed: ${data['status']}');
      } else {
        debugPrint('❌ [TmpFiles] HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [TmpFiles] Fallback upload error: $e');
    }
    return null;
  }
}
