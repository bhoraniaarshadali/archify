import 'package:flutter/material.dart';
import 'dart:io';
import 'interior_transformation_screen.dart';
import '../../core/design_mode.dart';
import '../../widgets/primary_generate_button.dart';
import '../../models/interior_style_model.dart' as exp;

class InteriorColorPaletteScreen extends StatefulWidget {
  final File uploadedImage;
  final String? preUploadedUrl;
  final RoomType roomType;
  final exp.InteriorStyle interiorStyle;

  const InteriorColorPaletteScreen({
    super.key,
    required this.uploadedImage,
    this.preUploadedUrl,
    required this.roomType,
    required this.interiorStyle,
  });

  @override
  State<InteriorColorPaletteScreen> createState() => _InteriorColorPaletteScreenState();
}

class _InteriorColorPaletteScreenState extends State<InteriorColorPaletteScreen> {
  final List<String> _selectedColors = [];

  // Get color palette for selected style (Copied from InteriorExperimentScreen)
  List<Map<String, dynamic>> _getColorPalette() {
    final styleId = widget.interiorStyle.templateId;

    // Warm & Neutral Styles
    if (styleId == 'interior0001' || styleId == 'interior0003' || styleId == 'interior0004') {
      return [
        {'name': 'Warm White (0xFFF5F1E8)', 'color': const Color(0xFFF5F1E8)},
        {'name': 'Soft Beige (0xFFD8CFC4)', 'color': const Color(0xFFD8CFC4)},
        {'name': 'Natural Oak (0xFFC8A97E)', 'color': const Color(0xFFC8A97E)},
        {'name': 'Muted Sage (0xFF9CAF88)', 'color': const Color(0xFF9CAF88)},
        {'name': 'Clay Brown (0xFFB07A5A)', 'color': const Color(0xFFB07A5A)},
      ];
    }

    // Modern & Contemporary
    if (styleId == 'interior0002' || styleId == 'interior0014' || styleId == 'interior0020') {
      return [
        {'name': 'Charcoal Gray (0xFF36454F)', 'color': const Color(0xFF36454F)},
        {'name': 'Pure White (0xFFFAFAFA)', 'color': const Color(0xFFFAFAFA)},
        {'name': 'Midnight Navy (0xFF1F2A44)', 'color': const Color(0xFF1F2A44)},
        {'name': 'Brushed Brass (0xFFB08D57)', 'color': const Color(0xFFB08D57)},
        {'name': 'Soft Greige (0xFFC9B8A8)', 'color': const Color(0xFFC9B8A8)},
      ];
    }

    // Industrial & Soft Industrial
    if (styleId == 'interior0005' || styleId == 'interior0026') {
      return [
        {'name': 'Concrete Gray (0xFF5C5C5C)', 'color': const Color(0xFF5C5C5C)},
        {'name': 'Steel Black (0xFF1C1C1C)', 'color': const Color(0xFF1C1C1C)},
        {'name': 'Deep Blue (0xFF1F3A5F)', 'color': const Color(0xFF1F3A5F)},
        {'name': 'Rust Red (0xFF8B2E2E)', 'color': const Color(0xFF8B2E2E)},
        {'name': 'Off White (0xFFEDEAE5)', 'color': const Color(0xFFEDEAE5)},
      ];
    }

    // Boho & Natural
    if (styleId == 'interior0006' || styleId == 'interior0016') {
      return [
        {'name': 'Terracotta (0xFFE2725B)', 'color': const Color(0xFFE2725B)},
        {'name': 'Sand Beige (0xFFD2B48C)', 'color': const Color(0xFFD2B48C)},
        {'name': 'Olive Green (0xFF6B8E23)', 'color': const Color(0xFF6B8E23)},
        {'name': 'Cream White (0xFFFFF5E1)', 'color': const Color(0xFFFFF5E1)},
        {'name': 'Caramel Brown (0xFFAF6E4D)', 'color': const Color(0xFFAF6E4D)},
      ];
    }

    // Coastal & Mediterranean
    if (styleId == 'interior0007' || styleId == 'interior0009' || styleId == 'interior0047') {
      return [
        {'name': 'Soft White (0xFFF8F9F5)', 'color': const Color(0xFFF8F9F5)},
        {'name': 'Seafoam Green (0xFF93E1D8)', 'color': const Color(0xFF93E1D8)},
        {'name': 'Dusty Blue (0xFF6B9AC4)', 'color': const Color(0xFF6B9AC4)},
        {'name': 'Whitewashed Oak (0xFFE8D8C3)', 'color': const Color(0xFFE8D8C3)},
        {'name': 'Coastal Sand (0xFFDCC9A6)', 'color': const Color(0xFFDCC9A6)},
      ];
    }

    // Luxury & Glam
    if (styleId == 'interior0021' || styleId == 'interior0030' || styleId == 'interior0025') {
      return [
        {'name': 'Ivory (0xFFFFF8E7)', 'color': const Color(0xFFFFF8E7)},
        {'name': 'Royal Gold (0xFFD4AF37)', 'color': const Color(0xFFD4AF37)},
        {'name': 'Deep Charcoal (0xFF2F2F2F)', 'color': const Color(0xFF2F2F2F)},
        {'name': 'Burgundy (0xFF800020)', 'color': const Color(0xFF800020)},
        {'name': 'Marble White (0xFFE5E4E2)', 'color': const Color(0xFFE5E4E2)},
      ];
    }

    // Default palette for other styles
    return [
      {'name': 'Warm White (0xFFF5F1E8)', 'color': const Color(0xFFF5F1E8)},
      {'name': 'Soft Beige (0xFFD8CFC4)', 'color': const Color(0xFFD8CFC4)},
      {'name': 'Charcoal Gray (0xFF36454F)', 'color': const Color(0xFF36454F)},
      {'name': 'Muted Sage (0xFF9CAF88)', 'color': const Color(0xFF9CAF88)},
      {'name': 'Terracotta (0xFFE2725B)', 'color': const Color(0xFFE2725B)},
    ];
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InteriorTransformationScreen(
          uploadedImage: widget.uploadedImage,
          preUploadedUrl: widget.preUploadedUrl,
          roomType: widget.roomType,
          interiorStyle: widget.interiorStyle,
          selectedColors: _selectedColors,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _getColorPalette();

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
          'Step 3 of 4',
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
          // Progress Bar (75% complete)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.75,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF0EA5E9),
                ),
                minHeight: 8,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Color Palette',
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
              'Choose colors for your ${widget.interiorStyle.styleName.toLowerCase()} style',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ),

          const SizedBox(height: 24),

          // Palette Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: palette.length,
              itemBuilder: (context, index) => _buildPaletteCard(palette[index]),
            ),
          ),

          // Next Button
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
            child: PrimaryGenerateButton(
              title: 'Continue',
              isGenerating: false,
              onTap: _continue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteCard(Map<String, dynamic> colorData) {
    final colorName = colorData['name'] as String;
    final color = colorData['color'] as Color;
    final isSelected = _selectedColors.contains(colorName);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedColors.remove(colorName);
          } else {
            _selectedColors.add(colorName);
          }
        });
      },
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Color Swatch
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: isSelected ? const Center(
                    child: Icon(Icons.check_circle, color: Colors.white, size: 28),
                  ) : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                colorName.split(' (')[0],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                  color: isSelected ? const Color(0xFF0EA5E9) : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                colorName.contains('(') ? colorName.split('(')[1].replaceAll(')', '') : '',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
