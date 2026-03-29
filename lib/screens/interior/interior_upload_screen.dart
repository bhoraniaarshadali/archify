  import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import 'dart:io';
  import 'room_type_selection_screen.dart';
  import '../../navigation/app_navigator.dart';
  import '../../widgets/daily_credit_badge.dart';

  class InteriorUploadScreen extends StatefulWidget {
    const InteriorUploadScreen({super.key});

    @override
    State<InteriorUploadScreen> createState() => _InteriorUploadScreenState();
  }

  class _InteriorUploadScreenState extends State<InteriorUploadScreen> {
    File? _selectedImage;
    bool _isLoading = false;

    Future<void> _pickImage(ImageSource source) async {
      // 1. Double-tap protection (Bina UI block kiye)
      if (_isLoading) return;

      try {
        final picker = ImagePicker();

        // 🚀 STEP 1: System call ko pehle hone dein (No loader yet)
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1800, // ✅ Standardized for memory safety
          maxHeight: 1800,
          imageQuality: 85, // ✅ High quality, smaller footprint
        );

        if (pickedFile != null && mounted) {
          // 🚀 STEP 2: Ab user ne image select kar li hai, ab loader dikhayein
          setState(() => _isLoading = true);

          final imageFile = File(pickedFile.path);

          // Instant preview ke liye image ko pre-cache karein
          await precacheImage(FileImage(imageFile), context);

          setState(() {
            _selectedImage = imageFile;
            _isLoading = false; // Processing done
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

    void _continue() {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image first'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      AppNavigator.push(
        context,
        RoomTypeSelectionScreen(
          uploadedImage: _selectedImage!,
        ),
      );
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
                  color: const Color(0xFF0EA5E9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chair_alt_outlined,
                  color: Color(0xFF0EA5E9),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Interior Design',
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
            const Center(child: DailyCreditBadge(themeColor: Color(0xFF0EA5E9))),
            const SizedBox(width: 16),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Room Photo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a photo of your room or choose from gallery',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),

              const SizedBox(height: 32),

              // Image Preview Area
              Expanded(
                child: GestureDetector(
                  onTap: () => _showImageSourceDialog(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _selectedImage != null
                            ? const Color(0xFF0EA5E9)
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
                                      color: const Color(0xFF0EA5E9).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: Color(0xFF0EA5E9),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Tap to add room photo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Living room, bedroom, kitchen, or bathroom',
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
                  color: const Color(0xFF0EA5E9).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'For best results, capture the entire room with good lighting',
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
                      ? const Color(0xFF0EA5E9)
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
                'Add Room Photo',
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
            color: const Color(0xFF0EA5E9).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0EA5E9).withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF0EA5E9), size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
