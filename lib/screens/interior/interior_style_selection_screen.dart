import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'interior_color_palette_screen.dart';
import '../../core/design_mode.dart';
import '../../models/interior_style_model.dart' as exp;
import '../../services/interior/interior_styles_repository.dart';
import '../../services/remote_config_controller.dart';

class InteriorStyleSelectionScreen extends StatefulWidget {
  final File uploadedImage;
  final String? preUploadedUrl;
  final RoomType roomType;

  const InteriorStyleSelectionScreen({
    super.key,
    required this.uploadedImage,
    this.preUploadedUrl,
    required this.roomType,
  });

  @override
  State<InteriorStyleSelectionScreen> createState() => _InteriorStyleSelectionScreenState();
}

class _InteriorStyleSelectionScreenState extends State<InteriorStyleSelectionScreen> {
  exp.InteriorStyle? _selectedStyle;
  List<exp.InteriorStyle> _styles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStyles();
  }

  Future<void> _loadStyles() async {
    try {
      final styles = await InteriorStylesRepository.loadStyles();
      if (mounted) {
        setState(() {
          _styles = styles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading styles: $e')),
        );
      }
    }
  }

  void _continue() {
    if (_selectedStyle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a style'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InteriorColorPaletteScreen(
          uploadedImage: widget.uploadedImage,
          preUploadedUrl: widget.preUploadedUrl,
          roomType: widget.roomType,
          interiorStyle: _selectedStyle!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remoteController = Get.find<RemoteConfigController>();

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
        title: const Text(
          'Step 2 of 4',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final remoteStyles = remoteController.adsVariable.value.interiorStyles;
        List<exp.InteriorStyle> currentStyles = [];
        
        if (remoteStyles.isNotEmpty) {
           currentStyles = remoteStyles
            .where((e) => e['type'] == 'interior')
            .map((e) => exp.InteriorStyle.fromJson(e))
            .toList();
        } else {
           currentStyles = _styles; // Use fallback from initState
        }

        final showLoading = _isLoading && currentStyles.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.50,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0EA5E9), // Sky Blue for Interior
                  ),
                  minHeight: 8,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Choose Interior Style',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Styling your ${widget.roomType.displayName.toLowerCase()}',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
            ),

            const SizedBox(height: 20),

            // Style Grid
            Expanded(
              child: showLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: currentStyles.length,
                      itemBuilder: (context, index) => _buildStyleCard(currentStyles[index]),
                    ),
            ),

            // Continue Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedStyle != null
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
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStyleCard(exp.InteriorStyle style) {
    final isSelected = _selectedStyle?.templateId == style.templateId;

    return GestureDetector(
      onTap: () => setState(() => _selectedStyle = style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0EA5E9).withOpacity(0.1)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    style.exampleImage,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[100],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.styleName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? const Color(0xFF0EA5E9) : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI Transformation',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
