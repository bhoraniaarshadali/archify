import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/helper/image_compression_service.dart';
import '../../services/helper/temp_file_upload_service.dart';
import 'garden_style_selection_screen.dart';
import '../../navigation/app_navigator.dart';
import '../../widgets/daily_credit_badge.dart';

class GardenUploadScreen extends StatefulWidget {
  const GardenUploadScreen({super.key});

  @override
  State<GardenUploadScreen> createState() => _GardenUploadScreenState();
}

class _GardenUploadScreenState extends State<GardenUploadScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _uploadedImageUrl;
  Future<void>? _uploadFuture;
  String _uploadStatus = '';

  // Future<void> _pickImage(ImageSource source) async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final picker = ImagePicker();
  //     final pickedFile = await picker.pickImage(
  //       source: source,
  //       maxWidth: 2048,
  //       maxHeight: 2048,
  //       imageQuality: 90,
  //     );
  //
  //     if (pickedFile != null) {
  //       // Clear previous upload data when new image is selected
  //       _uploadedImageUrl = null;
  //       _uploadStatus = '';
  //
  //       setState(() {
  //         _selectedImage = File(pickedFile.path);
  //       });
  //
  //       // Start background upload immediately
  //       _uploadImageInBackground();
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error: ${e.toString()}'),
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _pickImage(ImageSource source) async {
    // 1. Loader start MAT karein yahan. System gallery ko turant aane dein.
    if (_isLoading) return;

    try {
      final picker = ImagePicker();

      // System UI call (Non-blocking for your app's UI)
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1800, // 1800px is sweet spot for memory vs quality
        maxHeight: 1800,
        imageQuality: 85, // 85 is enough when followed by our compression service
      );

      if (pickedFile != null && mounted) {
        // 2. Ab user ne image select kar li hai, ab "Processing" start karein
        setState(() => _isLoading = true);

        // Clear old data
        _uploadedImageUrl = null;
        _uploadStatus = '';

        final imageFile = File(pickedFile.path);

        // 🚀 Optimization: Pre-cache image for instant preview rendering
        await precacheImage(FileImage(imageFile), context);

        setState(() {
          _selectedImage = imageFile;
          _isLoading = false; // Picker processing done
        });

        // 3. Start background upload separately
        _uploadFuture = _uploadImageInBackground();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _uploadImageInBackground() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading...';
    });

    try {
      debugPrint('🚀 Starting background image upload...');

      // Compress image
      final compressedImage = await ImageCompressionService.compressImage(
        _selectedImage!,
      );

      if (!mounted) return;

      // Upload to temp service
      final uploadedUrl = await TempFileUploadService.uploadImage(
        compressedImage,
      );

      // Clean up compressed file if different from original
      try {
        if (compressedImage.path != _selectedImage!.path) {
          await compressedImage.delete();
        }
      } catch (e) {
        debugPrint('⚠️ Error deleting compressed file: $e');
      }

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        if (mounted) {
          setState(() {
            _uploadedImageUrl = uploadedUrl;
            _uploadStatus = 'Ready ✓';
            _isUploading = false;
          });
          // debugPrint('✅ Background upload successful: $uploadedUrl');
        }
      } else {
        throw Exception('Upload returned empty URL');
      }
    } catch (e) {
      debugPrint('❌ Background upload failed: $e');
      if (mounted) {
        setState(() {
          _uploadedImageUrl = null; // Clear URL on failure
          _uploadStatus = 'Will upload later';
          _isUploading = false;
        });

        // Show reassuring message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image will be uploaded when you generate'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _continue() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Ensure upload is done if it was started
    if (_uploadedImageUrl == null && _uploadFuture != null) {
      setState(() => _isLoading = true);
      await _uploadFuture;
      setState(() => _isLoading = false);
    }

    if (mounted) {
      // Navigate to style selection with uploaded URL (if available)
      AppNavigator.push(
        context,
        GardenStyleSelectionScreen(
          uploadedImage: _selectedImage!,
          preUploadedUrl: _uploadedImageUrl, // Pass URL if already uploaded
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1), // Green tint
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.yard_outlined,
                color: Color(0xFF10B981), // Green
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Garden Design',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          const Center(child: DailyCreditBadge(themeColor: Color(0xFF10B981))),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Garden Photo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo of your garden or outdoor space',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),

            const SizedBox(height: 32),

            // Image Preview Area
            Expanded(
              child: GestureDetector(
                onTap: () => _showImageSourceDialog(),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _selectedImage != null
                          ? const Color(0xFF10B981) // Green
                          : Colors.grey.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              // Upload Status Overlay
                              if (_uploadStatus.isNotEmpty)
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _uploadedImageUrl != null
                                          ? Colors.green.withOpacity(0.9)
                                          : _isUploading
                                          ? Colors.blue.withOpacity(0.9)
                                          : Colors.orange.withOpacity(
                                              0.9,
                                            ), // Orange instead of red
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isUploading)
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        else
                                          Icon(
                                            _uploadedImageUrl != null
                                                ? Icons.check_circle
                                                : Icons
                                                      .schedule, // Schedule icon instead of error
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _uploadStatus,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Change Image Button
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _showImageSourceDialog(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                size: 48,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Tap to add garden photo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Backyard, front yard, patio, or balcony',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For best results, capture the area in daylight with a clear view',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Continue Button
            ElevatedButton(
              onPressed: _selectedImage != null ? _continue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedImage != null
                    ? const Color(0xFF10B981) // Green
                    : Colors.grey[300],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add Garden Photo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
