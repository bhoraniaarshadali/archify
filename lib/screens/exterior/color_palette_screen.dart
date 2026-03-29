// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'loading_screen.dart';
// import 'experimental_loading_screen';
// import '../../widgets/primary_generate_button.dart';
//
//
// class ColorPaletteScreen extends StatefulWidget {
//   final File uploadedImage;
//   final String? preUploadedUrl;
//   final String buildingType;
//   final String styleName;
//   final bool isExperimental;
//
//   const ColorPaletteScreen({
//     super.key,
//     required this.uploadedImage,
//     this.preUploadedUrl,
//     required this.buildingType,
//     required this.styleName,
//     this.isExperimental = false,
//   });
//
//   @override
//   State<ColorPaletteScreen> createState() => _ColorPaletteScreenState();
// }
//
// class _ColorPaletteScreenState extends State<ColorPaletteScreen> {
//   int? _selectedPaletteIndex;
//
//   final List<String> _paletteNames = [
//     'Surprise Me',
//     'Sandstone Serenity',
//     'Serene Bloom',
//     'Bold',
//     'Monochrome',
//     'Milk Tea Alliance',
//   ];
//
//   final List<List<Color>> _paletteColors = [
//     // Surprise Me: Off-white, Black, Metallic (matching backend: #F5F1E8, #1A1A1A)
//     [const Color(0xFFF5F1E8), const Color(0xFF9E9E9E), const Color(0xFF1A1A1A)],
//
//     // Warm: Beige, Cream, Soft Brown (matching backend: #E8D5C4, #F5F0E8, #A67C52)
//     [const Color(0xFFE8D5C4), const Color(0xFFF5F0E8), const Color(0xFFA67C52)],
//
//     // Cool: Light Gray, White, Blue-Gray (matching backend: #D3D8DC, #F8F9FA, #B8C5D0)
//     [const Color(0xFFD3D8DC), const Color(0xFFF8F9FA), const Color(0xFFB8C5D0)],
//
//     // Bold: Burgundy, Navy, Forest Green (matching backend: #7A2E2E, #1A3A52, #2C5530)
//     [const Color(0xFF7A2E2E), const Color(0xFF1A3A52), const Color(0xFF2C5530)],
//
//     // Neutral: White, Gray, Black (matching backend: #FFFFFF, #808080, #1A1A1A)
//     [const Color(0xFFFFFFFF), const Color(0xFF808080), const Color(0xFF1A1A1A)],
//
//     // Natural: Sandstone, Terracotta, Wood Brown (matching backend: #D4C5B0, #C87855, #8B4513)
//     [const Color(0xFFD4C5B0), const Color(0xFFC87855), const Color(0xFF8B4513)],
//   ];
//
//   void _continue() {
//     if (_selectedPaletteIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a color palette'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }
//
//     String? selectedPalette = _selectedPaletteIndex == 0
//         ? null
//         : _paletteNames[_selectedPaletteIndex!];
//
//     // Reverted: Removed Model Choice Dialog, defaulting to Flux-Pro
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => widget.isExperimental
//             ? ExperimentalLoadingScreen(
//                 uploadedImage: widget.uploadedImage,
//                 preUploadedUrl: widget.preUploadedUrl,
//                 buildingType: widget.buildingType,
//                 styleName: widget.styleName,
//                 colorPalette: selectedPalette,
//               )
//             : LoadingScreen(
//                 uploadedImage: widget.uploadedImage,
//                 preUploadedUrl: widget.preUploadedUrl,
//                 buildingType: widget.buildingType,
//                 styleName: widget.styleName,
//                 colorPalette: selectedPalette,
//               ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_ios_new,
//             color: Colors.black,
//             size: 20,
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Step 3 of 3',
//           style: TextStyle(
//             color: Colors.grey,
//             fontSize: 13,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//             child: Text(
//               'Color Palette',
//               style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//             ),
//           ),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 24),
//             child: Text(
//               'Tap a palette to instantly preview the mood.',
//               style: TextStyle(color: Colors.grey, fontSize: 14),
//             ),
//           ),
//           const SizedBox(height: 20),
//
//           Expanded(
//             child: GridView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 15,
//                 mainAxisSpacing: 15,
//                 childAspectRatio:
//                     0.85, // Fixed: Thoda stretch kiya taaki text collapse na ho
//               ),
//               itemCount: _paletteNames.length,
//               itemBuilder: (context, index) => _buildGridCard(index),
//             ),
//           ),
//
//           Container(
//             padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(30),
//                 topRight: Radius.circular(30),
//               ),
//               boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
//             ),
//             child: PrimaryGenerateButton(
//               title: 'Generate Design',
//               isGenerating: false,
//               onTap: _selectedPaletteIndex != null ? _continue : null,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGridCard(int index) {
//     final isSelected = _selectedPaletteIndex == index;
//     final isSurprise = index == 0;
//
//     return GestureDetector(
//       onTap: () => setState(() => _selectedPaletteIndex = index),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(
//             color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
//             width: 2,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               flex: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(10.0), // Padding thoda badhaya
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(15),
//                   child: isSurprise
//                       ? Container(
//                           width: double.infinity,
//                           color: Colors.deepPurpleAccent.withOpacity(0.05),
//                           child: const Center(
//                             // Fixed: Center widget icon ko stretch hone se rokega
//                             child: Icon(
//                               Icons.auto_awesome_rounded,
//                               color: Colors.deepPurpleAccent,
//                               size: 36,
//                             ),
//                           ),
//                         )
//                       : Row(
//                           children: _paletteColors[index]
//                               .map((c) => Expanded(child: Container(color: c)))
//                               .toList(),
//                         ),
//                 ),
//               ),
//             ),
//             Expanded(
//               flex: 1,
//               child: Container(
//                 // Fixed: Alignment ensure karne ke liye
//                 alignment: Alignment.center,
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Text(
//                   _paletteNames[index],
//                   style: TextStyle(
//                     fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
//                     fontSize: 15,
//                     color: isSelected
//                         ? Colors.deepPurpleAccent
//                         : Colors.black87,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ----------------------------

import 'package:flutter/material.dart';
import 'dart:io';
import 'loading_screen.dart'; 
import '../../widgets/primary_generate_button.dart';

class ColorPaletteScreen extends StatefulWidget {
  final File uploadedImage;
  final String? preUploadedUrl;
  final String buildingType;
  final String styleName;
  final bool isExperimental;

  const ColorPaletteScreen({
    super.key,
    required this.uploadedImage,
    this.preUploadedUrl,
    required this.buildingType,
    required this.styleName,
    this.isExperimental = false,
  });

  @override
  State<ColorPaletteScreen> createState() => _ColorPaletteScreenState();
}

class _ColorPaletteScreenState extends State<ColorPaletteScreen> {
  int? _selectedPaletteIndex;

  // Added more palettes to match the new styles
  final List<String> _paletteNames = [
    'Surprise Me',
    'Sandstone Serenity',
    'Serene Bloom',
    'Bold & Noble',
    'Monochrome',
    'Milk Tea Alliance',
    'Mediterranean Sun',
    'Farmhouse Contrast',
    'Nordic Minimal',
    'Vintage Tudor',
    'Retro Mid-Century',
  ];

  final List<List<Color>> _paletteColors = [
    // Surprise Me: Off-white, Silver, Dark Gray
    [const Color(0xFFF5F1E8), const Color(0xFF9E9E9E), const Color(0xFF1A1A1A)],

    // Sandstone Serenity (Warm): Beige, Cream, Soft Brown
    [const Color(0xFFE8D5C4), const Color(0xFFF5F0E8), const Color(0xFFA67C52)],

    // Serene Bloom (Cool): Light Gray, White, Blue-Gray
    [const Color(0xFFD3D8DC), const Color(0xFFF8F9FA), const Color(0xFFB8C5D0)],

    // Bold & Noble: Burgundy, Navy, Forest Green
    [const Color(0xFF7A2E2E), const Color(0xFF1A3A52), const Color(0xFF2C5530)],

    // Monochrome: White, Gray, Black
    [const Color(0xFFFFFFFF), const Color(0xFF808080), const Color(0xFF1A1A1A)],

    // Milk Tea Alliance: Sandstone, Taupe, Wood Brown
    [const Color(0xFFD4C5B0), const Color(0xFFA89F91), const Color(0xFF8B4513)],

    // Mediterranean Sun: Stucco White, Terracotta, Royal Blue
    [const Color(0xFFFEF9F3), const Color(0xFFC06044), const Color(0xFF00539C)],

    // Farmhouse Contrast: Pure White, Matte Black, Oak Wood
    [const Color(0xFFF2F2F2), const Color(0xFF282828), const Color(0xFFC19A6B)],

    // Nordic Minimal: Arctic White, Ash Gray, Pale Pine
    [const Color(0xFFFFFFFF), const Color(0xFFE5E5E5), const Color(0xFFD2B48C)],

    // Vintage Tudor: Deep Brick, Dark Oak, Stone Gray
    [const Color(0xFF843B2B), const Color(0xFF3D2B1F), const Color(0xFFA9A9A9)],

    // Retro Mid-Century: Teal Blue, Mustard, Walnut
    [const Color(0xFF006D77), const Color(0xFFE9C46A), const Color(0xFF6F4E37)],
  ];

  void _continue() {
    if (_selectedPaletteIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a color palette'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String? selectedPalette = _selectedPaletteIndex == 0
        ? null
        : _paletteNames[_selectedPaletteIndex!];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(
          uploadedImage: widget.uploadedImage,
          preUploadedUrl: widget.preUploadedUrl,
          buildingType: widget.buildingType,
          styleName: widget.styleName,
          colorPalette: selectedPalette,
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Step 3 of 3',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              'Color Palette',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Tap a palette to instantly preview the mood.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.9, // Balanced ratio for name and colors
              ),
              itemCount: _paletteNames.length,
              itemBuilder: (context, index) => _buildGridCard(index),
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: PrimaryGenerateButton(
              title: 'Generate Design',
              isGenerating: false,
              onTap: _selectedPaletteIndex != null ? _continue : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(int index) {
    final isSelected = _selectedPaletteIndex == index;
    final isSurprise = index == 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaletteIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: isSurprise
                      ? Container(
                    width: double.infinity,
                    color: Colors.deepPurpleAccent.withOpacity(0.05),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.deepPurpleAccent,
                        size: 36,
                      ),
                    ),
                  )
                      : Row(
                    children: _paletteColors[index]
                        .map((c) => Expanded(child: Container(color: c)))
                        .toList(),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _paletteNames[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: isSelected
                        ? Colors.deepPurpleAccent
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
