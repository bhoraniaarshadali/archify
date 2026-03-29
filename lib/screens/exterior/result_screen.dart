import 'package:flutter/material.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../../ads/app_state.dart';
import '../../services/helper/my_creations_service.dart';
import '../../widgets/premium_before_after_slider.dart';
import '../home/home_screen.dart';
import '../edit_item/item_replace_screen.dart';
import 'loading_screen.dart';
import '../../core/app_status.dart';
import '../premium/premium_module_screen.dart';

import '../../navigation/app_navigator.dart';
import '../../ads/ad_manager.dart';

class ResultScreen extends StatefulWidget {
  final dynamic originalImage; // File or String (path/url), can be null for Text-to-Image
  final dynamic generatedImage; // File or String (path/url)
  final String? buildingType;
  final String? styleName;
  final String? colorPalette;
  final String? creationId;
  final bool allowFromCreations;
  final bool? showSlider;

  const ResultScreen({
    super.key,
    this.originalImage,
    required this.generatedImage,
    this.buildingType,
    this.styleName,
    this.colorPalette,
    this.creationId,
    this.allowFromCreations = false,
    this.showSlider,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final Logger _logger = Logger();
  double _sliderValue = 0.5; // Slider position (0.0 to 1.0)
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Saving is now handled in the loading screen before navigation.
  }

  CreationCategory _determineCategory() {
    final style = widget.styleName?.toLowerCase() ?? '';
    final building = widget.buildingType?.toLowerCase() ?? '';

    if (building.contains('floor') || building.contains('blueprint')) return CreationCategory.floorPlan;
    if (building.contains('3d') || building.contains('model')) return CreationCategory.model3D;
    if (building.contains('garden')) return CreationCategory.garden;
    if (building.contains('interior') || building.contains('kitchen') || building.contains('room')) return CreationCategory.interior;
    if (building.contains('exterior') || building.contains('house')) return CreationCategory.exterior;
    if (style.contains('removal')) return CreationCategory.removeObject;
    if (style.contains('replace')) return CreationCategory.replaceObject;
    if (style.contains('text to image') || style.contains('ai art')) return CreationCategory.textToImage;

    return CreationCategory.exterior;
  }

  // --- Logic Functions (Unchanged) ---

  Widget _buildEditOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.deepPurpleAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _regenerateImage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Variation?'),
        content: const Text(
          'We will create a fresh design using your original settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Regenerate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final originalPath = await _getImagePath(widget.originalImage);
      if (originalPath == null) {
        _showMessage('Could not prepare original image for regeneration');
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingScreen(
            uploadedImage: File(originalPath),
            buildingType: widget.buildingType ?? 'House',
            styleName: widget.styleName ?? 'Modern',
            colorPalette: widget.colorPalette,
          ),
        ),
      );
    }
  }

  Future<void> _editImage() async {
    final genPath = await _getImagePath(widget.generatedImage);
    final origPath = await _getImagePath(widget.originalImage);

    if (genPath == null || origPath == null) {
      _showMessage('Could not prepare images for editing');
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Refine Design',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildEditOption(
              icon: Icons.auto_fix_high_rounded,
              title: 'Object Replacement',
              subtitle: 'Change any specific part or furniture',
              onTap: () {
                Navigator.pop(context);
                AppNavigator.push(
                  context,
                  ItemReplaceScreen(
                    generatedImage: File(genPath),
                    originalImage: File(origPath),
                    mode: 'replace',
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildEditOption(
              icon: Icons.cleaning_services_rounded,
              title: 'Object Removal',
              subtitle: 'Instantly remove unwanted items',
              onTap: () {
                Navigator.pop(context);
                AppNavigator.push(
                  context,
                  ItemReplaceScreen(
                    generatedImage: File(genPath),
                    originalImage: File(origPath),
                    mode: 'remove',
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildEditOption(
              icon: Icons.refresh_rounded,
              title: 'Regenerate',
              subtitle: 'Try again with same settings',
              onTap: () {
                Navigator.pop(context);
                _regenerateImage();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<String?> _getImagePath(dynamic imageSource) async {
    if (imageSource is File) return imageSource.path;
    final url = imageSource.toString();
    if (!url.startsWith('http')) return url;

    try {
      final response = await http.get(Uri.parse(url));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${url.hashCode}.jpg');
      if (!await file.exists()) {
        await file.writeAsBytes(response.bodyBytes);
      }
      return file.path;
    } catch (e) {
      debugPrint('Error downloading image for export/share: $e');
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return; // Double-tap protection
    setState(() => _isSaving = true);

    try {
      if (!AppState.isPremiumUser) {
        final bool allowed = await AdsManager.showRewardedOrFallback(context);
        if (!allowed) {
          setState(() => _isSaving = false);
          return;
        }
      }

      final path = await _getImagePath(widget.generatedImage);
      if (path != null) {
        await Gal.putImage(path);
        _showMessage('Saved to Gallery Successfully');
      } else {
        _showMessage('Could not prepare image for saving');
      }
    } catch (e) {
      _showMessage('Image not saved. Check permissions.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareImage() async {
    try {
      final path = await _getImagePath(widget.generatedImage);
      if (path != null) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'My home, redesigned by AI! 🏠✨',
          ),
        );
      } else {
        _showMessage('Could not prepare image for sharing');
      }
    } catch (e) {
      _showMessage('Failed to share');
    }
  }

  Future<void> _deleteImage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Delete'),
        content: const Text('This masterpiece will be lost forever. Proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (widget.creationId != null) {
        await MyCreationsService.deleteCreation(widget.creationId!);
      }

      if (mounted) {
        if (widget.allowFromCreations) {
          Navigator.pop(context, true); // Return true to refresh gallery
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
          );
        }
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Expert Dark Mode Preview
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () {
            if (widget.allowFromCreations) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
              );
            }
          },
        ),
        title: Column(
          children: [
            Text(
              widget.allowFromCreations ? 'My Creation' : 'Generation Result',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (widget.styleName != null)
              Text(
                widget.styleName!,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumModuleScreen(initialTabIndex: 0),
                  ),
                );
              },
              icon: const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Colors.black,
              ),
              label: const Text(
                'PRO',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8FF76),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [


          // Main Preview with Premium Before/After Slider
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _shouldShowSlider
                    ? PremiumBeforeAfterSlider(
                  beforeImage: _getCleanPath(widget.originalImage),
                  afterImage: _getCleanPath(widget.generatedImage),
                  initialValue: _sliderValue,
                  onValueChanged: (value) {
                    setState(() {
                      _sliderValue = value;
                    });
                  },
                )
                    : _buildSingleImage(),
              ),
            ),
          ),

          // Bottom Controls
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!AppStatus.isMaintenance)
                      _buildIconBtn(
                        Icons.auto_fix_high_rounded,
                        'Refine',
                        _editImage,
                        color: Colors.blueAccent,
                      ),
                    if (!AppStatus.isMaintenance)
                      _buildIconBtn(
                        Icons.refresh_rounded,
                        'Retry',
                        _regenerateImage,
                        color: Colors.deepPurpleAccent,
                      ),
                    _buildIconBtn(
                      Icons.file_download_outlined,
                      'Export',
                      _saveToGallery,
                      color: Colors.green,
                    ),
                    _buildIconBtn(
                      Icons.share_rounded,
                      'Share',
                      _shareImage,
                      color: Colors.orange,
                    ),
                    _buildIconBtn(
                      Icons.delete_outline_rounded,
                      'Discard',
                      _deleteImage,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (widget.allowFromCreations) {
                      Navigator.pop(context); // Just back if from Creations
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                            (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleImage() {
    return _renderImage(widget.generatedImage);
  }

  Widget _renderImage(dynamic imageSource) {
    if (imageSource == null) return const SizedBox.shrink();

    // 🔒 STRICT: Local File Only
    File? file;
    if (imageSource is File) {
      file = imageSource;
    } else if (imageSource is String) {
      if (imageSource.startsWith('http')) {
        // ❌ Error: Network URL passed to ResultScreen
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 40),
              SizedBox(height: 8),
              Text(
                'Offline View Only',
                style: TextStyle(color: Colors.white),
              )
            ],
          ),
        );
      }
      file = File(imageSource.replaceFirst('file://', ''));
    }

    if (file != null) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white24)),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  String _getCleanPath(dynamic imageSource) {
    if (imageSource == null) return '';
    if (imageSource is File) return imageSource.path;
    return imageSource.toString().replaceFirst('file://', '');
  }

  bool get _shouldShowSlider {
    if (widget.showSlider != null) return widget.showSlider!;

    if (widget.originalImage == null) return false;

    // Compare paths if they are files or strings
    final origPath = widget.originalImage is File ? widget.originalImage.path : widget.originalImage.toString();
    final genPath = widget.generatedImage is File ? widget.generatedImage.path : widget.generatedImage.toString();

    if (origPath == genPath) return false;

    return true;
  }

  Widget _buildIconBtn(
      IconData icon,
      String label,
      VoidCallback onTap, {
        required Color color,
      }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}