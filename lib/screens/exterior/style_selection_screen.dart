
import 'package:flutter/material.dart';
import 'dart:io';
import '../../constants/style_reference_images.dart';
import 'color_palette_screen.dart';

class StyleSelectionScreen extends StatefulWidget {
  final File uploadedImage;
  final String? preUploadedUrl;
  final String buildingType;
  final bool isExperimental;

  const StyleSelectionScreen({
    super.key,
    required this.uploadedImage,
    this.preUploadedUrl,
    required this.buildingType,
    this.isExperimental = false,
  });

  @override
  State<StyleSelectionScreen> createState() => _StyleSelectionScreenState();
}

class _StyleSelectionScreenState extends State<StyleSelectionScreen> {
  int? _selectedStyleIndex;

  // Added new trending architectural styles
  final List<String> _styleNames = [
    'Surprise Me',
    'Modern',
    'Victorian',
    'Industrial',
    'Minimalist',
    'Rustic',
    'Luxury',
    'Mediterranean',
    'Modern Farmhouse',
    'Scandinavian',
    'Tudor',
    'Mid-Century',
  ];

  final List<String> _styleDescriptions = [
    'AI Magic',
    'Clean & Neutral',
    'Classic Elegance',
    'Urban Raw',
    'Simple White',
    'Woody Tones',
    'Premium Finish',
    'Coastal Villa',
    'Rustic Contrast',
    'Nordic Minimal',
    'European Brick',
    'Retro Chic',
  ];

  void _continue() {
    if (_selectedStyleIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a style'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedStyle = _styleNames[_selectedStyleIndex!];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColorPaletteScreen(
          uploadedImage: widget.uploadedImage,
          preUploadedUrl: widget.preUploadedUrl,
          buildingType: widget.buildingType,
          styleName: selectedStyle,
          isExperimental: widget.isExperimental,
        ),
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
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Step 2 of 3',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.66,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.deepPurpleAccent,
                ),
                minHeight: 8,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Choose Your Style',
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
              'Styling your ${widget.buildingType.toLowerCase()} to perfection',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),

          const SizedBox(height: 20),

          // Style Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.82,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _styleNames.length,
              itemBuilder: (context, index) => _buildStyleCard(index),
            ),
          ),

          // Continue Button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
              onPressed: _selectedStyleIndex != null ? _continue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedStyleIndex != null
                    ? Colors.deepPurpleAccent
                    : Colors.grey[300],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget _buildStyleCard(int index) {
    final isSelected = _selectedStyleIndex == index;
    final isSurprise = index == 0;
    final styleName = _styleNames[index];

    return GestureDetector(
      onTap: () => setState(() => _selectedStyleIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.deepPurpleAccent.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      isSurprise
                          ? Container(
                        color: Colors.deepPurpleAccent.withOpacity(0.05),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.deepPurpleAccent,
                          size: 40,
                        ),
                      )
                          : StyleReferenceImages.getStyleImage(styleName) != null
                          ? Image.asset(
                        StyleReferenceImages.getStyleImage(styleName)!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: Icon(Icons.style_outlined, color: Colors.grey[400]),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey[500]!.withOpacity(0.1),
                        child: Icon(Icons.style_outlined, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Column(
                children: [
                  Text(
                    styleName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? Colors.deepPurpleAccent : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _styleDescriptions[index],
                    style: TextStyle(fontSize: 10, color: Colors.grey[600], letterSpacing: 0.2),
                    textAlign: TextAlign.center,
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