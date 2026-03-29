import 'package:flutter/material.dart';
import 'dart:io';
import 'interior_loading_screen.dart';
import '../../core/design_mode.dart';
import '../../widgets/primary_generate_button.dart';
import '../../models/interior_style_model.dart' as exp;

class InteriorTransformationScreen extends StatefulWidget {
  final File uploadedImage;
  final String? preUploadedUrl;
  final RoomType roomType;
  final exp.InteriorStyle interiorStyle;
  final List<String> selectedColors;

  const InteriorTransformationScreen({
    super.key,
    required this.uploadedImage,
    this.preUploadedUrl,
    required this.roomType,
    required this.interiorStyle,
    required this.selectedColors,
  });

  @override
  State<InteriorTransformationScreen> createState() => _InteriorTransformationScreenState();
}

class _InteriorTransformationScreenState extends State<InteriorTransformationScreen> {
  int _transformationProgress = 50;

  void _generate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InteriorLoadingScreen(
          uploadedImage: widget.uploadedImage,
          preUploadedUrl: widget.preUploadedUrl,
          roomType: widget.roomType,
          interiorStyle: widget.interiorStyle,
          selectedColors: widget.selectedColors,
          transformationProgress: _transformationProgress,
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
          'Step 4 of 4',
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
          // Progress Bar (100% complete at the end of this step)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 1.0,
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
              'Transformation',
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
              'How much should AI transform your space?',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ),

          const SizedBox(height: 48),

          // Slider Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Preserve',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_transformationProgress%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                            ),
                            const Text(
                              'Upgrade',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF0EA5E9),
                            inactiveTrackColor: const Color(0xFF0EA5E9).withOpacity(0.1),
                            thumbColor: Colors.white,
                            overlayColor: const Color(0xFF0EA5E9).withOpacity(0.1),
                            trackHeight: 8,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                              elevation: 4,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: 100,
                            divisions: 2,
                            value: _transformationProgress.toDouble(),
                            onChanged: (v) {
                              setState(() => _transformationProgress = v.toInt());
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _transformationProgress <= 0
                              ? 'Maximum preservation. Only light color and realism refinements.'
                              : _transformationProgress >= 100
                                  ? 'Full style upgrade. Modernize furniture and surfaces completely.'
                                  : 'Balanced blend. Upgrade style while maintaining original vibe.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Quick Preview of Selections
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryItem(Icons.room_outlined, 'Room', widget.roomType.displayName),
                        _buildSummaryItem(Icons.palette_outlined, 'Style', widget.interiorStyle.styleName),
                        _buildSummaryItem(Icons.color_lens_outlined, 'Colors', widget.selectedColors.isEmpty ? 'AI Choice' : widget.selectedColors.join(', ')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Generate Button
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
              title: 'Generate Design',
              isGenerating: false,
              onTap: _generate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0EA5E9)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
