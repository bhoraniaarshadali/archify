import 'package:flutter/material.dart';
import 'dart:io';
import 'interior_style_selection_screen.dart';
import '../../core/design_mode.dart';

class RoomTypeSelectionScreen extends StatefulWidget {
  final File uploadedImage;
  final String? preUploadedUrl;

  const RoomTypeSelectionScreen({
    super.key,
    required this.uploadedImage,
    this.preUploadedUrl,
  });

  @override
  State<RoomTypeSelectionScreen> createState() => _RoomTypeSelectionScreenState();
}

class _RoomTypeSelectionScreenState extends State<RoomTypeSelectionScreen> {
  RoomType? _selectedRoomType;

  final List<RoomType> _roomTypes = [
    RoomType.livingRoom,
    RoomType.bedroom,
    RoomType.kitchen,
    RoomType.bathroom,
    RoomType.diningRoom,
    RoomType.office,
  ];

  final Map<RoomType, IconData> _roomIcons = {
    RoomType.livingRoom: Icons.weekend_outlined,
    RoomType.bedroom: Icons.bed_outlined,
    RoomType.kitchen: Icons.kitchen_outlined,
    RoomType.bathroom: Icons.bathtub_outlined,
    RoomType.diningRoom: Icons.dining_outlined,
    RoomType.office: Icons.computer_outlined,
  };

  void _continue() {
    if (_selectedRoomType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a room type'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InteriorStyleSelectionScreen(
          uploadedImage: widget.uploadedImage,
          preUploadedUrl: widget.preUploadedUrl,
          roomType: _selectedRoomType!,
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
          'Step 1 of 4',
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
                value: 0.25,
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
              'Select Room Type',
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
              'What type of room do you want to redesign?',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ),

          const SizedBox(height: 24),

          // Room Type Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _roomTypes.length,
              itemBuilder: (context, index) => _buildRoomCard(_roomTypes[index]),
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
                backgroundColor: _selectedRoomType != null
                    ? const Color(0xFF0EA5E9) // Sky Blue
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
      ),
    );
  }

  Widget _buildRoomCard(RoomType roomType) {
    final isSelected = _selectedRoomType == roomType;
    final icon = _roomIcons[roomType] ?? Icons.home_outlined;

    return GestureDetector(
      onTap: () => setState(() => _selectedRoomType = roomType),
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
                  ? const Color(0xFF0EA5E9).withOpacity(0.15)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0EA5E9).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              roomType.displayName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFF0EA5E9) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
