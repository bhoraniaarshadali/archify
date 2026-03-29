import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../services/helper/my_creations_service.dart';
import '../services/helper/temp_file_upload_service.dart';
import 'data/interior_styles_repository.dart';
import 'model/interior_style_model.dart';
import 'service/interior_experiment_pipeline.dart';
import 'service/interior_experiment_api_service.dart';
import 'package:flutter/services.dart';

/// 🧪 EXPERIMENTAL TEST SCREEN WITH FULL API INTEGRATION
/// Complete testing UI for JSON-based interior pipeline
class InteriorExperimentScreen extends StatefulWidget {
  const InteriorExperimentScreen({super.key});

  @override
  State<InteriorExperimentScreen> createState() => _InteriorExperimentScreenState();
}

class _InteriorExperimentScreenState extends State<InteriorExperimentScreen> {
  List<InteriorStyle> _styles = [];
  InteriorStyle? _selectedStyle;
  final List<String> _selectedColors = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  double _progress = 0.0;
  String _statusMessage = '';

  File? _selectedImage;
  String? _uploadedImageUrl;
  String? _generatedImageUrl;
  int _transformationProgress = 50;

// Get color palette for selected style
  List<Map<String, dynamic>> _getColorPalette() {
    if (_selectedStyle == null) {
      return [
        {'name': 'Warm White (0xFFF5F1E8)', 'color': const Color(0xFFF5F1E8)},
        {'name': 'Soft Beige (0xFFD8CFC4)', 'color': const Color(0xFFD8CFC4)},
        {'name': 'Natural Oak (0xFFC8A97E)', 'color': const Color(0xFFC8A97E)},
      ];
    }

    final styleId = _selectedStyle!.templateId;

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


  @override
  void initState() {
    super.initState();
    _loadStyles();
  }

  Future<void> _loadStyles() async {
    try {
      final styles = await InteriorStylesRepository.loadStyles();
      setState(() {
        _styles = styles;
        _isLoading = false;
      });
      debugPrint('✅ Loaded ${styles.length} styles from JSON');
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Error loading styles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading styles: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _uploadedImageUrl = null;
        _generatedImageUrl = null;
      });
    }
  }

  String _buildFinalPrompt() {
    if (_selectedStyle == null) return 'No style selected';

    return InteriorExperimentPipeline.buildPrompt(
      styleName: _selectedStyle!.styleName,
      stylePrompt: _selectedStyle!.prompt,
      selectedColors: _selectedColors,
      progress: _transformationProgress,
    );
  }

  Future<void> _generateDesign() async {
    if (_isGenerating) return;

    if (_selectedStyle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a style first')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image first')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _statusMessage = 'Uploading image...';
      _generatedImageUrl = null;
    });

    try {
      // Step 1: Upload image
      setState(() {
        _progress = 0.1;
        _statusMessage = 'Uploading image to cloud...';
      });

      final uploadedUrl = await TempFileUploadService.uploadImage(_selectedImage!);
      
      if (uploadedUrl == null) {
        throw Exception('Failed to upload image');
      }

      setState(() {
        _uploadedImageUrl = uploadedUrl;
        _progress = 0.3;
        _statusMessage = 'Creating generation task...';
      });

      // Step 2: Get image dimensions
      final bytes = await _selectedImage!.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      
      // Step 3: Build final prompt
      final finalPrompt = _buildFinalPrompt();
      
      // Step 4: Create task
      final requestId = await InteriorExperimentService.createTask(
        imageUrl: uploadedUrl,
        finalPrompt: finalPrompt,
        width: decodedImage?.width,
        height: decodedImage?.height,
      );

      if (requestId == null) {
        throw Exception('Failed to create generation task');
      }

      setState(() {
        _progress = 0.5;
        _statusMessage = 'AI is transforming your space...';
      });

      // Step 5: Poll for result
      final resultUrl = await InteriorExperimentService.pollResult(requestId);

      if (resultUrl == null) {
        throw Exception('Generation failed or timed out');
      }

      setState(() {
        _progress = 0.9;
        _statusMessage = 'Finalizing & Saving...';
      });

      // ✅ Centralized Save: Download once → Save locally → UI Render
      final savedCreation = await MyCreationsService.saveGeneratedCreation(
        type: CreationType.image,
        category: CreationCategory.interior,
        mediaUrl: resultUrl,
        originalMediaUrl: uploadedUrl,
        metadata: {
          'styleName': _selectedStyle!.styleName,
          'styleId': _selectedStyle!.templateId,
          'colors': _selectedColors,
          'prompt': finalPrompt,
          'source': 'experiment',
          'transformation_progress': _transformationProgress,
        },
      );

      debugPrint('✅ Saved to My Creations: ${savedCreation?.id}');

      setState(() {
        _progress = 1.0;
        _statusMessage = 'Complete!';
        _generatedImageUrl = resultUrl;
        _isGenerating = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Generation complete & saved to My Creations!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _statusMessage = 'Error: $e';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          '🧪 Interior Experiment (${_styles.length} Styles)',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Banner
                  // Container(
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.amber.shade50,
                  //     borderRadius: BorderRadius.circular(12),
                  //     border: Border.all(color: Colors.amber.shade200),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       const Icon(Icons.science, color: Colors.amber),
                  //       const SizedBox(width: 12),
                  //       Expanded(
                  //         child: Text(
                  //           'Testing ${_styles.length} styles from JSON with real API calls',
                  //           style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 24),

                  // Image Upload Section
                  const Text(
                    '1. Upload Image',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _isGenerating ? null : _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_selectedImage!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text('Tap to upload image',
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Style Selection with Photos
                  Text(
                    '2. Select Style (${_styles.length} available)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _styles.length,
                      itemBuilder: (context, index) {
                        final style = _styles[index];
                        final isSelected = _selectedStyle?.templateId == style.templateId;
                        return GestureDetector(
                          onTap: _isGenerating
                              ? null
                              : () {
                                  setState(() => _selectedStyle = style);
                                  debugPrint('Selected: ${style.styleName}');
                                },
                          child: Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.deepPurple.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Example Image from JSON
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(
                                    style.exampleImage,
                                    height: 110,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 110,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 110,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                // Style Name
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          style.styleName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected ? Colors.deepPurple : Colors.black87,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'SELECTED',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Color Palette Selection
                  const Text(
                    '3. Select Colors',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Visual Color Palette Boxes
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _getColorPalette().length,
                      itemBuilder: (context, index) {
                        final colorData = _getColorPalette()[index];
                        final colorName = colorData['name'] as String;
                        final color = colorData['color'] as Color;
                        final isSelected = _selectedColors.contains(colorName);
                        
                        return GestureDetector(
                          onTap: _isGenerating
                              ? null
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedColors.remove(colorName);
                                    } else {
                                      _selectedColors.add(colorName);
                                    }
                                  });
                                },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.deepPurple.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Column(
                              children: [
                                // Color Box
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Center(
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 24,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black45,
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                // Color Name
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.deepPurple : Colors.white,
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    colorName,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transformation Progress Slider
                  const Text(
                    '4. Transformation Strength',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0% (Preserve)',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                            Text(
                              '$_transformationProgress%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Text(
                              '100% (Upgrade)',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Slider(
                          min: 0,
                          max: 100,
                          divisions: 2,
                          value: _transformationProgress.toDouble(),
                          activeColor: Colors.deepPurple,
                          inactiveColor: Colors.deepPurple.withValues(alpha: 0.2),
                          onChanged: _isGenerating
                              ? null
                              : (v) {
                                  // Snapping logic for extra safety, though divisions: 2 handles it
                                  int snappedValue;
                                  if (v < 25) {
                                    snappedValue = 0;
                                  } else if (v < 75) {
                                    snappedValue = 50;
                                  } else {
                                    snappedValue = 100;
                                  }
                                  setState(() => _transformationProgress = snappedValue);
                                },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _transformationProgress <= 0
                                ? 'Maximum preservation of original image elements.'
                                : _transformationProgress >= 100
                                    ? 'Full style upgrade while maintaining the layout.'
                                    : 'A balanced blend of original layout and new style.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Generated Prompt Preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '5. Final Prompt (Preview)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final prompt = _buildFinalPrompt();
                          Clipboard.setData(ClipboardData(text: prompt)).then((_) {
                            if (mounted) {
                              if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Prompt copied to clipboard!'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                            }
                          });
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text(''),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _buildFinalPrompt(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generateDesign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isGenerating
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Generating...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Generate Design',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Progress Indicator
                  if (_isGenerating) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  // Generated Result
                  if (_generatedImageUrl != null) ...[
                    const SizedBox(height: 32),
                    const Text(
                      '✅ Generated Result',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _generatedImageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 300,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
