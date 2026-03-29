import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MediaDownloadService {
  /// Downloads media (image/video) from [url] and saves it to a local file.
  /// [subDir] is an optional sub-directory within documents (e.g. 'thumbnails')
  /// Returns the [File] object if successful, or null if failed.
  static Future<File?> downloadMedia(String url, {String? subDir}) async {
    try {
      debugPrint('⬇️ Downloading media from: $url');
      final uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        
        Directory targetDir = appDir;
        if (subDir != null) {
          targetDir = Directory('${appDir.path}/$subDir');
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        // Determine extension
        String extension = '.jpg';
        final contentType = response.headers['content-type'];
        if (contentType != null) {
          if (contentType.contains('video') || url.contains('.mp4')) {
            extension = '.mp4';
          } else if (contentType.contains('png') || url.contains('.png')) {
            extension = '.png';
          }
        } else {
           if (url.contains('.mp4')) {
             extension = '.mp4';
           } else if (url.contains('.png')) extension = '.png';
        }

        final fileName = 'media_$timestamp$extension';
        final file = File('${targetDir.path}/$fileName');
        
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('✅ Media saved to: ${file.path}');
        return file;
      } else {
        debugPrint('❌ Download failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error downloading media: $e');
      return null;
    }
  }

  /// Downloads both media and an optional thumbnail
  static Future<({File? mediaFile, File? thumbFile})> downloadCreationMedia({
    required String mediaUrl,
    String? thumbUrl,
  }) async {
    final mediaFile = await downloadMedia(mediaUrl);
    
    // Optimization: If thumbUrl is same as mediaUrl, don't download twice
    if (thumbUrl == mediaUrl) {
      return (mediaFile: mediaFile, thumbFile: mediaFile);
    }

    File? thumbFile;
    if (thumbUrl != null && thumbUrl.isNotEmpty) {
      thumbFile = await downloadMedia(thumbUrl, subDir: 'thumbnails');
    }

    return (mediaFile: mediaFile, thumbFile: thumbFile);
  }
}
