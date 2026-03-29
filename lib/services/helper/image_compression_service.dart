import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image Compression Service
///
/// Compresses images before upload to reduce file size and upload time
/// Typical compression: 5MB → 1-2MB (3x faster upload!)
class ImageCompressionService {
  /// Compress image with smart quality settings
  ///
  /// Returns compressed file or original if compression fails
  /// Skips compression if image is already under 1MB
  static Future<File> compressImage(File file) async {
    try {
      final originalSizeBytes = file.lengthSync();
      final originalSizeMB = originalSizeBytes / 1024 / 1024;

      debugPrint(
        '📦 Original image size: ${originalSizeMB.toStringAsFixed(2)} MB',
      );

      // Skip compression if image is already under 1MB
      if (originalSizeBytes < 1024 * 1024) {
        debugPrint('✅ Image is under 1MB, skipping compression');
        return file;
      }

      // Get temp directory for compressed file
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Compress image
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85, // 85% quality - visually identical, much smaller
        minWidth: 1920, // Max width for good quality
        minHeight: 1920, // Max height
        format: CompressFormat.jpeg, // JPEG is smaller than PNG
      );

      if (compressedXFile != null) {
        final compressedFile = File(compressedXFile.path);
        final compressedSize = compressedFile.lengthSync() / 1024 / 1024;

        debugPrint(
          '✅ Compressed image size: ${compressedSize.toStringAsFixed(2)} MB',
        );

        return compressedFile;
      } else {
        debugPrint('⚠️ Compression failed, using original image');
        return file;
      }
    } catch (e) {
      debugPrint('❌ Compression error: $e, using original image');
      return file;
    }
  }

  /// Get estimated upload time based on file size
  ///
  /// Assumes average upload speed of 2 Mbps (typical mobile)
  static String getEstimatedUploadTime(File file) {
    final sizeInMB = file.lengthSync() / 1024 / 1024;
    const uploadSpeedMbps = 2.0; // Average mobile upload speed
    final timeInSeconds = (sizeInMB * 8) / uploadSpeedMbps;

    if (timeInSeconds < 5) {
      return '~${timeInSeconds.toStringAsFixed(0)}s';
    } else if (timeInSeconds < 60) {
      return '~${timeInSeconds.toStringAsFixed(0)}s';
    } else {
      return '~${(timeInSeconds / 60).toStringAsFixed(1)}min';
    }
  }
}
