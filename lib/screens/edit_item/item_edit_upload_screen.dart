import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'item_replace_screen.dart';
import '../../navigation/app_navigator.dart';
import '../../widgets/daily_credit_badge.dart';
import '../../services/helper/image_compression_service.dart';
import '../../services/helper/temp_file_upload_service.dart';
import 'dart:async';

class ItemEditUploadScreen extends StatefulWidget {
  final String mode; // 'replace' or 'remove' (cleanup)

  const ItemEditUploadScreen({
    super.key,
    required this.mode,
  });

  @override
  State<ItemEditUploadScreen> createState() => _ItemEditUploadScreenState();
}

class _ItemEditUploadScreenState extends State<ItemEditUploadScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  String? _uploadedImageUrl;
  Future<void>? _uploadFuture;

  Future<void> _pickImage(ImageSource source) async {
    // 1. Double-tap protection (Bina UI block kiye)
    if (_isLoading) return;

    try {
      final picker = ImagePicker();

      // 🚀 STEP 1: System call ko pehle hone dein (No loader yet)
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1800, // ✅ Optimized for masking tools memory consumption
        maxHeight: 1800,
        imageQuality: 85, // ✅ High quality, smaller footprint
      );

      if (pickedFile != null && mounted) {
        // 🚀 STEP 2: Ab user ne image select kar li hai, ab loader dikhayein
        setState(() => _isLoading = true);

        HapticFeedback.lightImpact(); // Professional haptic feedback
        final imageFile = File(pickedFile.path);

        // Instant preview ke liye image ko pre-cache karein
        await precacheImage(FileImage(imageFile), context);

        setState(() {
          _selectedImage = imageFile;
          _isLoading = false; // Processing done
          _uploadedImageUrl = null; // Reset for new image
          _uploadFuture = _uploadImageInBackground();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadImageInBackground() async {
    if (_selectedImage == null) return;
    try {
      final compressedImage = await ImageCompressionService.compressImage(_selectedImage!);
      final url = await TempFileUploadService.uploadImage(compressedImage);
      if (mounted) {
        setState(() {
          _uploadedImageUrl = url;
        });
      }
    } catch (e) {
      debugPrint('Background upload error: $e');
    }
  }

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
  //       setState(() {
  //         _selectedImage = File(pickedFile.path);
  //       });
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

  void _continue() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_uploadedImageUrl == null && _uploadFuture != null) {
      setState(() => _isLoading = true);
      await _uploadFuture;
      setState(() => _isLoading = false);
    }

    // Navigate to ItemReplaceScreen (Masking Tool)
    // Since we are starting fresh, original and generated are the same image
    if (mounted) {
      AppNavigator.push(
        context,
        ItemReplaceScreen(
          originalImage: _selectedImage!,
          generatedImage: _selectedImage!,
          mode: widget.mode,
          preUploadedUrl: _uploadedImageUrl,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRemove = widget.mode == 'remove';
    Color themeColor = isRemove ? const Color(0xFFEC4899) : const Color(0xFFF59E0B);
    String title = isRemove ? 'Cleanup Tool' : 'Replace Item';
    IconData icon = isRemove ? Icons.cleaning_services_outlined : Icons.swap_horiz_rounded;

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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: themeColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Center(child: DailyCreditBadge(themeColor: themeColor)),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Photo clean up',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRemove 
                  ? 'Identify objects to remove from the scene' 
                  : 'Select an item to replace with something new',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),

            const SizedBox(height: 32),

            // Image Preview Area
            Expanded(
              child: GestureDetector(
                onTap: () => _showImageSourceDialog(themeColor),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _selectedImage != null
                          ? themeColor
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
                                  Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
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
                                        onPressed: () => _showImageSourceDialog(themeColor),
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
                                    color: themeColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 48,
                                    color: themeColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Tap to add photo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
                color: themeColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeColor.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: themeColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For best results, ensure the object is clearly visible',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
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
                    ? themeColor
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

  void _showImageSourceDialog(Color color) {
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
              'Add Photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    color: color,
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
                    color: color,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
