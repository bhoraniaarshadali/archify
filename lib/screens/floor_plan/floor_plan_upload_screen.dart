import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptics ke liye
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/helper/image_compression_service.dart';
import '../../services/helper/temp_file_upload_service.dart';
import 'floor_plan_processing_screen.dart';
import '../../navigation/app_navigator.dart';
import '../../widgets/daily_credit_badge.dart';

class FloorPlanUploadScreen extends StatefulWidget {
  const FloorPlanUploadScreen({super.key});

  @override
  State<FloorPlanUploadScreen> createState() => _FloorPlanUploadScreenState();
}

class _FloorPlanUploadScreenState extends State<FloorPlanUploadScreen> {
  File? _selectedImage;
  bool _isPicking = false;
  String? _uploadedImageUrl;
  Future<void>? _uploadFuture;

  // Future<void> _pickImage(ImageSource source) async {
  //   if (_isPicking) return; // Multiple dialogs prevent karne ke liye
  //
  //   setState(() => _isPicking = true);
  //   try {
  //     final picker = ImagePicker();
  //     final pickedFile = await picker.pickImage(
  //       source: source,
  //       maxWidth: 1800, // Thoda optimize kiya memory ke liye
  //       maxHeight: 1800,
  //       imageQuality: 85, // Quality balance for faster upload
  //     );
  //
  //     if (pickedFile != null && mounted) {
  //       HapticFeedback.mediumImpact(); // Subtle feedback
  //       setState(() {
  //         _selectedImage = File(pickedFile.path);
  //       });
  //
  //       // Processing screen ke liye image pre-load kar rahe hain
  //       precacheImage(FileImage(_selectedImage!), context);
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error: ${e.toString()}'), behavior: SnackBarBehavior.floating),
  //       );
  //     }
  //   } finally {
  //     if (mounted) setState(() => _isPicking = false);
  //   }
  // }

  Future<void> _pickImage(ImageSource source) async {
    // Flag sirf double-tap prevent karne ke liye (Bina setState ke)
    if (_isPicking) return;

    try {
      final picker = ImagePicker();

      // 1. Loader start MAT karein yahan. Seedha gallery khulne dein.
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      // 2. Agar user ne image select kar li, tab processing dikhayein
      if (pickedFile != null && mounted) {
        setState(() {
          _isPicking = true;
          _uploadedImageUrl = null;
        }); // Processing start

        HapticFeedback.mediumImpact();
        File imageFile = File(pickedFile.path);

        // 🚀 OPTIMIZATION: Compression use karein upload fast karne ke liye
        // Aapki service file yahan kaam aayegi
        imageFile = await ImageCompressionService.compressImage(imageFile);

        // UI update karne se pehle cache karein
        await precacheImage(FileImage(imageFile), context);

        setState(() {
          _selectedImage = imageFile;
          _isPicking = false; // Processing khatam
        });

        // 🚀 STEP 4: Background Upload
        _uploadFuture = _uploadImageInBackground();
      }
    } catch (e) {
      setState(() => _isPicking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _uploadImageInBackground() async {
    if (_selectedImage == null) return;
    try {
      final url = await TempFileUploadService.uploadImage(_selectedImage!);
      if (mounted) {
        setState(() => _uploadedImageUrl = url);
      }
    } catch (e) {
      debugPrint('⚠️ Background upload error: $e');
    }
  }

  Future<void> _continue() async {
    if (_selectedImage == null) return;

    HapticFeedback.lightImpact();

    // Ensure upload is done if it was started
    if (_uploadedImageUrl == null && _uploadFuture != null) {
      setState(() => _isPicking = true);
      await _uploadFuture;
      setState(() => _isPicking = false);
    }

    if (mounted) {
      AppNavigator.push(
        context,
        FloorPlanProcessingScreen(
          floorPlanImage: _selectedImage!,
          preUploadedUrl: _uploadedImageUrl,
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
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  // --- UI Components for Cleaner Code ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        '2D to 3D Plan',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        const Center(child: DailyCreditBadge(themeColor: Color(0xFF3B82F6))),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Floor Plan',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Transform your 2D drawing into a detailed 3D view',
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildImageArea() {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showImageSourceDialog(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _selectedImage != null ? const Color(0xFF3B82F6) : Colors.grey.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: _isPicking
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _selectedImage != null
              ? _buildPreview()
              : _buildUploadPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImage!, fit: BoxFit.contain),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _showImageSourceDialog(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit_square, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, size: 60, color: const Color(0xFF3B82F6).withOpacity(0.5)),
        const SizedBox(height: 16),
        const Text('Select Floor Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('PNG, JPG or PDF works best', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFF3B82F6), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tip: Use a clear, top-down photo without any shadows for the best 3D result.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    bool isEnabled = _selectedImage != null && !_isPicking;
    return ElevatedButton(
      onPressed: isEnabled ? _continue : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        disabledBackgroundColor: Colors.grey[300],
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text('Generate 3D Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload From', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                _sourceButton(Icons.camera_alt, 'Camera', () => _pickImage(ImageSource.camera)),
                const SizedBox(width: 16),
                _sourceButton(Icons.photo_library, 'Gallery', () => _pickImage(ImageSource.gallery)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: () { Navigator.pop(context); onTap(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF3B82F6), size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}