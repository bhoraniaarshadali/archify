import 'package:flutter/material.dart';
import 'dart:io';
import 'garden_loading_screen.dart';
import '../../core/design_mode.dart';

class GardenStyleSelectionScreen extends StatefulWidget {
  final File uploadedImage;
  final String? preUploadedUrl;

  const GardenStyleSelectionScreen({
    super.key,
    required this.uploadedImage,
    this.preUploadedUrl,
  });

  @override
  State<GardenStyleSelectionScreen> createState() =>
      _GardenStyleSelectionScreenState();
}

class _GardenStyleSelectionScreenState
    extends State<GardenStyleSelectionScreen> {
  GardenStyle? _selectedStyle;

  final List<GardenStyle> _styles = [
    GardenStyle.modern,
    GardenStyle.lushNatural,
    GardenStyle.zen,
    GardenStyle.diwali,
    GardenStyle.christmas,
  ];

  void _continue() {
    if (_selectedStyle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a garden style'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navigate directly to loading screen (skip color palette)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GardenLoadingScreen(
          uploadedImage: widget.uploadedImage,
          preUploadedUrl: widget.preUploadedUrl,
          gardenStyle: _selectedStyle!,
          colorPalette: null, // No color palette selection
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
          'Step 2 of 2',
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
                value: 1.0,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF10B981), // Green
                ),
                minHeight: 8,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Choose Garden Style',
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
              'Swipe to explore styles for your garden',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ),

          const SizedBox(height: 20),

          // Style List (Single Column for 3 Styles)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _styles.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildStyleCard(_styles[index]),
              ),
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
                    ? const Color(0xFF10B981)
                    : Colors.grey[300],
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
                  Icon(Icons.auto_awesome, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Generate Garden',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(GardenStyle style) {
    final isSelected = _selectedStyle == style;

    return GestureDetector(
      onTap: () => setState(() => _selectedStyle = style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _getStyleColor(style).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getStyleIcon(style),
                size: 36,
                color: _getStyleColor(style),
              ),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Selection Indicator
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getStyleIcon(GardenStyle style) {
    switch (style) {
      case GardenStyle.modern:
        return Icons.crop_square_outlined;
      case GardenStyle.lushNatural:
        return Icons.forest_outlined;
      case GardenStyle.zen:
        return Icons.spa_outlined;
      case GardenStyle.diwali:
        return Icons.local_fire_department_outlined;
      case GardenStyle.christmas:
        return Icons.ac_unit_outlined;
    }
  }

  Color _getStyleColor(GardenStyle style) {
    switch (style) {
      case GardenStyle.modern:
        return const Color(0xFF64748B); // Slate/Industrial
      case GardenStyle.lushNatural:
        return const Color(0xFF10B981); // Green/Natural
      case GardenStyle.zen:
        return const Color(0xFF78716C); // Stone/Zen
      case GardenStyle.diwali:
        return const Color(0xFFFF8C00); // Deep Orange
      case GardenStyle.christmas:
        return const Color(0xFF1B5E20); // Deep Green
    }
  }
}
