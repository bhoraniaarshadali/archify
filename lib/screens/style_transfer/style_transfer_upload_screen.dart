import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'style_transfer_loading_screen.dart';
import '../../navigation/app_navigator.dart';
import '../../widgets/daily_credit_badge.dart';

class StyleTransferUploadScreen extends StatefulWidget {
  const StyleTransferUploadScreen({super.key});

  @override
  State<StyleTransferUploadScreen> createState() => _StyleTransferUploadScreenState();
}

class _StyleTransferUploadScreenState extends State<StyleTransferUploadScreen> {
  File? _originalImage;
  File? _referenceImage;
  bool _isLoading = false;

  // Future<void> _pickImage(ImageSource source, bool isOriginal) async {
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
  //         if (isOriginal) {
  //           _originalImage = File(pickedFile.path);
  //         } else {
  //           _referenceImage = File(pickedFile.path);
  //         }
  //       });
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: ${e.toString()}')),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _pickImage(ImageSource source, bool isOriginal) async {
    // 1. Double-tap protection (Bina UI block kiye)
    if (_isLoading) return;

    try {
      final picker = ImagePicker();

      // System UI call: Gallery ya Camera turant khulega
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1800, // Memory safety ke liye 1800px best hai
        maxHeight: 1800,
        imageQuality: 85, // Balanced quality
      );

      if (pickedFile != null && mounted) {
        // 2. Ab user ne image select kar li hai, ab "Processing" dikhayein
        setState(() => _isLoading = true);

        final imageFile = File(pickedFile.path);

        // Preview ko instant banane ke liye pre-cache
        await precacheImage(FileImage(imageFile), context);

        setState(() {
          if (isOriginal) {
            _originalImage = imageFile;
          } else {
            _referenceImage = imageFile;
          }
          _isLoading = false; // Processing complete
        });
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


  void _generate() {
    if (_originalImage == null || _referenceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both images')),
      );
      return;
    }

    AppNavigator.push(
      context,
      StyleTransferLoadingScreen(
        originalImage: _originalImage!,
        referenceImage: _referenceImage!,
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
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Reference Style Transfer',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          const Center(child: DailyCreditBadge(themeColor: Color(0xFFEC4899))),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        //padding: const EdgeInsets.all(24.0),
        padding: const EdgeInsets.fromLTRB(24, 05, 24, 80),

        child: Column(
          children: [
            const Text(
              'Copy Style & Apply',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your room and a reference image to copy its style',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Original Image Upload
            _buildUploadCard(
              title: '1. Your Room/Building',
              subtitle: 'Structure will be kept',
              image: _originalImage,
              onTap: () => _showImageSourceDialog(true),
              color: const Color(0xFFEC4899), // Pink
            ),

            const SizedBox(height: 20),

            // Arrow Down
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_downward_rounded,
                color: Color(0xFFEC4899),
              ),
            ),

            const SizedBox(height: 20),

            // Reference Image Upload
            _buildUploadCard(
              title: '2. Style Reference',
              subtitle: 'Colors & vibe will be copied',
              image: _referenceImage,
              onTap: () => _showImageSourceDialog(false),
              color: const Color(0xFF8B5CF6), // Purple
            ),

            const SizedBox(height: 40),

            // Generate Button
            ElevatedButton(
              onPressed: (_originalImage != null && _referenceImage != null)
                  ? _generate
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.auto_fix_high, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Transfer Style',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required File? image,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: image != null ? color : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(image, fit: BoxFit.cover),
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_photo_alternate_rounded,
                        size: 32, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  void _showImageSourceDialog(bool isOriginal) {
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
            const Text(
              'Select Photo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera, isOriginal);
                    },
                    child: _buildSourceOption(
                        Icons.camera_alt_outlined, 'Camera'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery, isOriginal);
                    },
                    child: _buildSourceOption(
                        Icons.photo_library_outlined, 'Gallery'),
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

  Widget _buildSourceOption(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.black87),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
