import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../navigation/app_navigator.dart';
import '../../services/helper/temp_file_upload_service.dart';
import '../../services/ApiFreeUse/video_generation_service.dart';
import 'video_generation_loading_screen.dart';
import '../../widgets/primary_generate_button.dart';
import '../../ads/app_state.dart';
import '../premium/pro_screen.dart';

class VideoGenerationScreen extends StatefulWidget {
  final String? initialImageUrl;
  final String? initialCategory;

  const VideoGenerationScreen({
    super.key,
    this.initialImageUrl,
    this.initialCategory,
  });

  @override
  State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  String? _selectedCategory;
  int _selectedDuration = 8;
  File? _selectedFile;
  String? _imageUrl;
  bool _isGenerating = false;
  bool _isPickingImage = false;
  final TextEditingController _promptController = TextEditingController();

  final List<String> _categories = ['Interior', 'Exterior', 'Custom'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _imageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _imageUrl = null;
        });
      }
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  Future<void> _handleGenerate() async {
    if (_isGenerating) return;

    // 1. Premium & Credit Check
    if (!AppState.isPremiumUser) {
      final success = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProScreen(from: 'video_generation', isFromInsufficientCoins: true)),
      );
      if (success != true) return;
    }

    // 2. Validation
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_selectedFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or upload an image')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      String? finalImageUrl = _imageUrl;

      // 3. Upload Image if it's a local file (Cloudinary with Fallback)
      if (finalImageUrl == null && _selectedFile != null) {
        debugPrint('📤 Uploading local image to Cloudinary...');
        finalImageUrl = await TempFileUploadService.uploadImage(_selectedFile!);
      }

      if (finalImageUrl == null) {
        throw Exception('Failed to upload image. Please check your connection.');
      }

      // 4. Submit Video Request
      final requestId = await VideoGenerationService.submitVideoRequest(
        imageUrl: finalImageUrl,
        category: _selectedCategory!,
        duration: _selectedDuration,
        userPrompt: _selectedCategory == 'Custom' ? _promptController.text : null,
      );

      if (requestId != null && mounted) {
        // 5. Navigate to Loading Screen
        AppNavigator.pushReplacement(
          context,
          VideoGenerationLoadingScreen(
            requestId: requestId,
            category: _selectedCategory!,
            duration: _selectedDuration,
            originalImageUrl: finalImageUrl,
          ),
        );
      } else if (mounted) {
        throw Exception('Failed to submit video request.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Generation',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Select Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: _isGenerating ? null : (selected) {
                    setState(() {
                      _selectedCategory = selected ? cat : null;
                    });
                  },
                  selectedColor: Colors.indigo.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.indigo : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const Text(
              '2. Select Duration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _DurationChip(
                  label: '8s',
                  isSelected: _selectedDuration == 8,
                  onTap: () => setState(() => _selectedDuration = 8),
                ),
                const SizedBox(width: 12),
                _DurationChip(
                  label: '15s',
                  isSelected: _selectedDuration == 15,
                  onTap: () => setState(() => _selectedDuration = 15),
                ),
                const SizedBox(width: 12),
                _DurationChip(
                  label: '30s',
                  isSelected: _selectedDuration == 30,
                  onTap: () => setState(() => _selectedDuration = 30),
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              '3. Input Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _isGenerating ? null : _pickImage,
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: _selectedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_selectedFile!, fit: BoxFit.cover),
                      )
                    : (_imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(_imageUrl!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text('Tap to upload image', style: TextStyle(color: Colors.grey[600])),
                            ],
                          )),
              ),
            ),
            const SizedBox(height: 32),

            if (_selectedCategory == 'Custom') ...[
              const Text(
                '4. Custom Prompt',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                maxLines: 3,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Enter your custom video prompt...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.indigo, width: 2),
                  ),
                  fillColor: Colors.grey[50],
                  filled: true,
                ),
              ),
            ],
            const SizedBox(height: 40),

            PrimaryGenerateButton(
              title: 'Generate Video',
              isGenerating: _isGenerating,
              onTap: _isGenerating ? null : _handleGenerate,
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'AI will create a $_selectedDuration-second cinematic animation',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}