import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/helper/image_compression_service.dart';
import '../../services/helper/temp_file_upload_service.dart';
import 'building_type_screen.dart';
import '../../navigation/app_navigator.dart';
import '../../widgets/daily_credit_badge.dart';

class ExteriorUploadScreen extends StatefulWidget {
  final bool isExperimental;

  const ExteriorUploadScreen({super.key, this.isExperimental = false});

  @override
  State<ExteriorUploadScreen> createState() => _ExteriorUploadScreenState();
}

class _ExteriorUploadScreenState extends State<ExteriorUploadScreen> {
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isLoading = false;
  Future<void>? _uploadFuture;

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return; // Double-tap protection

    try {
      final picker = ImagePicker();

      // 🚀 STEP 1: Snappy System Call (No loader before this)
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1800, // ✅ Standardized for memory safety
        maxHeight: 1800,
        imageQuality: 85, // ✅ High quality, smaller footprint
      );

      if (pickedFile != null && mounted) {
        // 🚀 STEP 2: Show loader only during internal processing
        setState(() => _isLoading = true);

        HapticFeedback.lightImpact();
        final imageFile = File(pickedFile.path);

        // 🚀 STEP 3: Instant preview pre-caching
        await precacheImage(FileImage(imageFile), context);

        setState(() {
          _selectedImage = imageFile;
          _uploadedImageUrl = null;
          _isLoading = false;
        });

        // 🚀 STEP 4: Background Upload (Cloudinary)
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
    try {
      final compressedImage = await ImageCompressionService.compressImage(_selectedImage!);
      final url = await TempFileUploadService.uploadImage(compressedImage);
      if (mounted) {
        setState(() => _uploadedImageUrl = url);
      }
      if (compressedImage.path != _selectedImage!.path) {
        await compressedImage.delete();
      }
    } catch (e) {
      debugPrint('⚠️ Background upload error: $e');
    }
  }

  Future<void> _continue() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first'), behavior: SnackBarBehavior.floating),
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
      AppNavigator.push(
        context,
        BuildingTypeScreen(
          uploadedImage: _selectedImage!,
          preUploadedUrl: _uploadedImageUrl,
          isExperimental: widget.isExperimental,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildImageArea(),
            const SizedBox(height: 24),
            _buildTipCard(),
            const SizedBox(height: 24),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
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
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.home_work_outlined, color: Color(0xFF6366F1), size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'Exterior Design',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        const Center(child: DailyCreditBadge(themeColor: Color(0xFF6366F1))),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Building Photo',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload a clear photo of your building for best AI results.',
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildImageArea() {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showImageSourceDialog(),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _selectedImage != null ? const Color(0xFF6366F1) : Colors.grey.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
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
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: () => _showImageSourceDialog(),
                    ),
                  ),
                ),
              ],
            ),
          )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF6366F1)),
        ),
        const SizedBox(height: 24),
        const Text('Tap to add building photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('JPEG, PNG up to 10MB', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ],
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFF6366F1)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'For best results, capture the entire facade with good daylight.',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: _selectedImage != null ? _continue : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedImage != null ? const Color(0xFF6366F1) : Colors.grey[300],
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Add Building Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildSourceBtn(Icons.camera_alt_outlined, 'Camera', ImageSource.camera),
                const SizedBox(width: 16),
                _buildSourceBtn(Icons.photo_library_outlined, 'Gallery', ImageSource.gallery),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBtn(IconData icon, String label, ImageSource source) {
    return Expanded(
      child: InkWell(
        onTap: () { Navigator.pop(context); _pickImage(source); },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF6366F1), size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
            ],
          ),
        ),
      ),
    );
  }
}