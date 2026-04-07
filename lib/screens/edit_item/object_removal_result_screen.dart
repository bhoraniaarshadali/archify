import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_status.dart';
import 'package:gal/gal.dart';
import '../../services/helper/my_creations_service.dart';
import '../../widgets/premium_before_after_slider.dart'; // Using the premium slider if available, else basic
import '../home/home_screen.dart';
import 'item_processing_screen.dart';
import '../premium/pro_screen.dart';
import '../../ads/ad_manager.dart';
import '../../ads/app_state.dart';

class ObjectRemovalResultScreen extends StatefulWidget {
  final dynamic originalImage; // File or String (path/url)
  final dynamic generatedImage; // File or String (path/url)
  final File maskImage; // Needed for retry
  final bool isAccurateResult; // To disable retry if accurate result
  final String? creationId;
  final bool allowFromCreations;

  const ObjectRemovalResultScreen({
    super.key,
    required this.originalImage,
    required this.generatedImage,
    required this.maskImage,
    required this.isAccurateResult,
    this.creationId,
    this.allowFromCreations = false, // Defaults to false -> Navigate Home
  });

  @override
  State<ObjectRemovalResultScreen> createState() => _ObjectRemovalResultScreenState();
}

class _ObjectRemovalResultScreenState extends State<ObjectRemovalResultScreen> {
  double _sliderValue = 0.5;

  @override
  void initState() {
    super.initState();
    if (!widget.allowFromCreations) {
      _autoSaveToMyCreations();
    }
  }

  Future<void> _autoSaveToMyCreations() async {
    try {
      final generatedUrl = widget.generatedImage is File 
          ? (widget.generatedImage as File).path 
          : widget.generatedImage?.toString();
      final originalUrl = widget.originalImage is File 
          ? (widget.originalImage as File).path 
          : widget.originalImage?.toString();

      if (generatedUrl == null) return;

      await MyCreationsService.saveCreation(
        MyCreation(
          id: widget.creationId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: CreationType.image,
          category: CreationCategory.removeObject,
          mediaUrl: generatedUrl,
          originalMediaUrl: originalUrl,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('❌ Auto-save failed: $e');
    }
  }

  Future<void> _saveToGallery() async {
    // 🔸 Check Premium / Show Ad
    if (!AppState.isPremiumUser) {
        bool watched = await AdsManager.showRewardedAd();
        if (!watched) {
          // If they didn't watch or ad failed, maybe show a dialog or snackbar?
          // For now, let's just return, or you can decide to let them save anyway if ad fails (fail-open).
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Watch ad to save image (Non-Premium)')),
          );
          return;
        }
    }

    try {
      await Gal.putImage(widget.generatedImage.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to Gallery Successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Check permissions.')),
      );
    }
  }

  void _showRetryDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Refine Result',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _buildRetryOption(
              title: 'Normal Mode',
              subtitle: 'Fast, Free (OpenAI)',
              isPremium: false,
              onTap: () {
                Navigator.pop(context);
                _retry(isAccurate: false); // Normal
              },
            ),
            const SizedBox(height: 16),
            _buildRetryOption(
              title: 'Accurate Mode',
              subtitle: 'High Precision (Premium/Ad)',
              isPremium: true,
              onTap: () {
                Navigator.pop(context);
                _handleAccurateRetry();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryOption({
    required String title,
    required String subtitle,
    required bool isPremium,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPremium ? const Color(0xFFFFF8E1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPremium ? Colors.amber : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPremium ? Icons.star_rounded : Icons.flash_on_rounded,
              color: isPremium ? Colors.amber[800] : Colors.blue,
              size: 28,
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
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _handleAccurateRetry() {
    // 1. Check if Premium
    if (AppState.isPremiumUser) {
      // Premium user -> Go directly
      _retry(isAccurate: true);
    } else {
      // Free user -> Go to Premium Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProScreen(from: "object_removal")),
      ).then((_) {
        // After returning from Premium Screen
        if (AppState.isPremiumUser) {
          // If they bought it
          _retry(isAccurate: true);
        } else {
          // If they didn't buy it -> Show Ad Popup
          _showAdPopup();
        }
      });
    }
  }

  void _showAdPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Complete Your Design',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Unlock unlimited access with PRO or watch an ad to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            
            // Primary Action: Remove Limits (Premium)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProScreen(from: "object_removal")),
                ).then((_) {
                  // Check if they bought it
                  if (AppState.isPremiumUser) {
                    _retry(isAccurate: true);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Remove Limits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Secondary Action: Watch Ad
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showRewardedAd();
              },
              icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
              label: const Text('Watch an Ad'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: Colors.black, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showRewardedAd() async {
    bool watched = await AdsManager.showRewardedAd();
    if (watched) {
      // Correct Ad watching -> Start accurate retry
      _retry(isAccurate: true);
    } else {
       // If dismissed without reward, do nothing
    }
  }

  void _retry({required bool isAccurate}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ItemProcessingScreen(
          originalImage: widget.originalImage,
          selectedAreaImage: widget.maskImage,
          mode: 'remove',
          isAccurateMode: isAccurate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
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
        title: const Text(
          'Removal Result',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Slider Preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: PremiumBeforeAfterSlider(
                  beforeImage: widget.originalImage is File ? widget.originalImage.path : widget.originalImage.toString(),
                  afterImage: widget.generatedImage is File ? widget.generatedImage.path : widget.generatedImage.toString(),
                  initialValue: _sliderValue,
                  onValueChanged: (v) => setState(() => _sliderValue = v),
                ),
              ),
            ),
          ),
          
          // Controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Retry Button (Hidden if Accurate Result or Maintenance)
                    if (!widget.isAccurateResult && !AppStatus.isMaintenance)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showRetryDialog,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black12),
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    
                    if (!widget.isAccurateResult && !AppStatus.isMaintenance)
                      const SizedBox(width: 16),

                    // Save Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _saveToGallery,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Save to Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.grey[800],
                    ),
                    child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
