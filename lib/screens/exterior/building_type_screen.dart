// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'style_selection_screen.dart';
//
// class BuildingTypeScreen extends StatefulWidget {
//   final File uploadedImage;
//   final String? preUploadedUrl;
//   final bool isExperimental;
//
//   const BuildingTypeScreen({
//     super.key,
//     required this.uploadedImage,
//     this.preUploadedUrl,
//     this.isExperimental = false,
//   });
//
//   @override
//   State<BuildingTypeScreen> createState() => _BuildingTypeScreenState();
// }
//
// class _BuildingTypeScreenState extends State<BuildingTypeScreen> {
//   int? _selectedTypeIndex;
//
//   final List<String> _buildingTypes = [
//     'House',
//     'Villa',
//     'Apartment',
//     'Bungalow',
//     'Office',
//     'Other',
//   ];
//
//   final List<String> _buildingDescriptions = [
//     'Single/multi-story',
//     'Luxury home',
//     'Multi-unit',
//     'Spacious home',
//     'Commercial',
//     'Other types',
//   ];
//
//   final List<String> _buildingImages = [
//     'assets/images/building_types/house.jpg',
//     'assets/images/building_types/villa.jpg',
//     'assets/images/building_types/apartment.jpg',
//     'assets/images/building_types/bungalow.jpg',
//     'assets/images/building_types/office.jpg',
//     'assets/images/building_types/house.jpg', // Fallback for 'Other'
//   ];
//
//   void _continue() {
//     if (_selectedTypeIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a building type'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }
//
//     final selectedType = _buildingTypes[_selectedTypeIndex!];
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => StyleSelectionScreen(
//           uploadedImage: widget.uploadedImage,
//           preUploadedUrl: widget.preUploadedUrl,
//           buildingType: selectedType,
//           isExperimental: widget.isExperimental,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA), // Soft grey background
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: Container(
//           margin: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
//             ],
//           ),
//           child: IconButton(
//             icon: const Icon(
//               Icons.arrow_back_ios_new,
//               color: Colors.black,
//               size: 18,
//             ),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         title: const Text(
//           'Step 1 of 3',
//           style: TextStyle(
//             color: Colors.grey,
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Custom Progress Bar
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: LinearProgressIndicator(
//                 value: 0.33,
//                 backgroundColor: Colors.grey[200],
//                 valueColor: const AlwaysStoppedAnimation<Color>(
//                   Colors.deepPurpleAccent,
//                 ),
//                 minHeight: 8,
//               ),
//             ),
//           ),
//
//           const Padding(
//             padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
//             child: Text(
//               'Select Building Type',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: -0.5,
//               ),
//             ),
//           ),
//
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 24.0),
//             child: Text(
//               'Which category best describes your property?',
//               style: TextStyle(color: Colors.grey, fontSize: 15),
//             ),
//           ),
//
//           const SizedBox(height: 20),
//
//           // Building Type Grid
//           Expanded(
//             child: GridView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 childAspectRatio: 0.85,
//                 crossAxisSpacing: 15,
//                 mainAxisSpacing: 15,
//               ),
//               itemCount: _buildingTypes.length,
//               itemBuilder: (context, index) => _buildTypeCard(index),
//             ),
//           ),
//
//           // Action Button
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 20,
//                   offset: const Offset(0, -5),
//                 ),
//               ],
//             ),
//             child: ElevatedButton(
//               onPressed: _continue,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _selectedTypeIndex != null
//                     ? Colors.deepPurpleAccent
//                     : Colors.grey[300],
//                 foregroundColor: Colors.white,
//                 minimumSize: const Size(double.infinity, 56),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 elevation: 0,
//               ),
//               child: const Text(
//                 'Continue',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTypeCard(int index) {
//     final isSelected = _selectedTypeIndex == index;
//
//     return GestureDetector(
//       onTap: () => setState(() => _selectedTypeIndex = index),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
//             width: 2,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: isSelected
//                   ? Colors.deepPurpleAccent.withOpacity(0.1)
//                   : Colors.black.withOpacity(0.03),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(15),
//                   child: Stack(
//                     fit: StackFit.expand,
//                     children: [
//                       Image.asset(
//                         _buildingImages[index],
//                         fit: BoxFit.cover,
//                         errorBuilder: (c, e, s) => Container(
//                           color: Colors.grey[100],
//                           child: Icon(
//                             Icons.home_work_outlined,
//                             color: Colors.grey[400],
//                             size: 40,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     _buildingTypes[index],
//                     style: TextStyle(
//                       fontWeight: isSelected
//                           ? FontWeight.bold
//                           : FontWeight.w600,
//                       fontSize: 16,
//                       color: isSelected
//                           ? Colors.deepPurpleAccent
//                           : Colors.black87,
//                     ),
//                   ),
//                   Text(
//                     _buildingDescriptions[index],
//                     style: TextStyle(fontSize: 11, color: Colors.grey[500]),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//-------------------------------

import 'package:flutter/material.dart';
import 'dart:io';
import 'style_selection_screen.dart';

class BuildingTypeScreen extends StatefulWidget {
  final File uploadedImage;
  final String? preUploadedUrl;
  final bool isExperimental;

  const BuildingTypeScreen({
    super.key,
    required this.uploadedImage,
    this.preUploadedUrl,
    this.isExperimental = false,
  });

  @override
  State<BuildingTypeScreen> createState() => _BuildingTypeScreenState();
}

class _BuildingTypeScreenState extends State<BuildingTypeScreen> {
  int? _selectedTypeIndex;

  // Expanded list to match the new styles added in previous steps
  final List<String> _buildingTypes = [
    'House',
    'Villa',
    'Apartment',
    'Farmhouse',
    'Bungalow',
    'Mansion',
    'Office',
    'Cabin',
    'Storefront',
    'Other',
  ];

  final List<String> _buildingDescriptions = [
    'Single/multi-story home',
    'Luxury retreat',
    'Urban multi-unit',
    'Modern rustic living',
    'Spacious classic home',
    'Grand elite estate',
    'Corporate workspace',
    'Woodsy cozy getaway',
    'Retail & Commercial',
    'Custom structure',
  ];

  final List<String> _buildingImages = [
    'assets/images/building_types/house.jpg',
    'assets/images/building_types/villa.jpg',
    'assets/images/building_types/apartment.jpg',
    'assets/images/building_types/house.jpg',
    'assets/images/building_types/bungalow.jpg',
    'assets/images/building_types/villa.jpg',
    'assets/images/building_types/office.jpg',
    'assets/images/building_types/bungalow.jpg',
    'assets/images/building_types/office.jpg',
    'assets/images/building_types/house.jpg',
  ];

  void _continue() {
    if (_selectedTypeIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a building type'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedType = _buildingTypes[_selectedTypeIndex!];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StyleSelectionScreen(
          uploadedImage: widget.uploadedImage,
          preUploadedUrl: widget.preUploadedUrl,
          buildingType: selectedType,
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
          'Step 1 of 3',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.33,
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
              'Select Building Type',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Which category best describes your property?',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.82, // Optimized for better content fit
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _buildingTypes.length,
              itemBuilder: (context, index) => _buildTypeCard(index),
            ),
          ),

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
              onPressed: _selectedTypeIndex != null ? _continue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTypeIndex != null
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

  Widget _buildTypeCard(int index) {
    final isSelected = _selectedTypeIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTypeIndex = index),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    _buildingImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.deepPurpleAccent.withOpacity(0.03),
                      child: Icon(
                        Icons.home_work_rounded,
                        color: Colors.deepPurpleAccent.withOpacity(0.2),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _buildingTypes[index],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                      fontSize: 15,
                      color: isSelected ? Colors.deepPurpleAccent : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildingDescriptions[index],
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey[600],
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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