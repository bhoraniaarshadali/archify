import '../../services/helper/temp_file_upload_service.dart';
import '../../services/daily_credit_manager.dart';

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../../services/ApiFreeUse/floor_plan_service.dart'; 
import '../../services/helper/connectivity_service.dart';
import '../exterior/result_screen.dart';
import '../../services/helper/my_creations_service.dart';
import '../../services/helper/background_generation_manager.dart';
import '../../navigation/app_navigator.dart';


class FloorPlanProcessingScreen extends StatefulWidget {
  final File floorPlanImage;
  final String? preUploadedUrl;

  const FloorPlanProcessingScreen({
    super.key,
    required this.floorPlanImage,
    this.preUploadedUrl,
  });

  @override
  State<FloorPlanProcessingScreen> createState() =>
      _FloorPlanProcessingScreenState();
}

class _FloorPlanProcessingScreenState extends State<FloorPlanProcessingScreen> {
  String _statusMessage = 'Initializing...';
  String? _requestId;
  StreamSubscription? _taskSubscription;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }

  bool _isProcessing = false;

  Future<void> _startProcessing() async {
    if (_isProcessing) return;
    _isProcessing = true;

    // Check connectivity first
    if (!ConnectivityService.instance.currentStatus) {
      setState(() => _statusMessage = 'Offline');
      return;
    }

    // 🪙 Credit System Check
    if (mounted) {
      final hasCredit = await DailyCreditManager.checkAndConsume(context);
      if (!hasCredit) {
        if (mounted) Navigator.pop(context);
        return;
      }
    }
    try {
      String? imageUrl = widget.preUploadedUrl;

      if (imageUrl == null) {
        setState(() {
          _statusMessage = 'Uploading floor plan...';
        });

        // Upload original image if not pre-uploaded
        imageUrl = await TempFileUploadService.uploadImage(
          widget.floorPlanImage,
        );
        if (imageUrl == null) {
          throw Exception('Failed to upload floor plan');
        }
      }
      _uploadedImageUrl = imageUrl;

      // Calculate optimal dimensions
      final decodedImage = await decodeImageFromList(
        widget.floorPlanImage.readAsBytesSync(),
      );

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Architecting 3D Model...';
      });

      // Use Floor Plan Service (using APIFree)
      final requestId = await FloorPlanService.createFloorPlanTask(
        floorPlanUrl: imageUrl,
        width: decodedImage.width,
        height: decodedImage.height,
      );

      if (requestId == null) {
        throw Exception('Task creation failed');
      }

      if (!mounted) return;

      // ✅ Save as Processing
      await MyCreationsService.saveProcessingCreation(
        type: CreationType.image,
        category: CreationCategory.floorPlan,
        taskId: requestId,
        originalMediaUrl: _uploadedImageUrl,
        metadata: {
          'styleName': '3D Floor Plan',
          'buildingType': 'FloorPlan',
        },
      );

      setState(() {
        _requestId = requestId;
        _statusMessage = 'Rendering Details...';
      });

      // ✅ Attach to background manager immediately
      await BackgroundGenerationManager.instance.attach(
        requestId,
        CreationType.image,
        CreationCategory.floorPlan,
      );

      // ✅ Listen for completion from Background Manager
      _taskSubscription = BackgroundGenerationManager.instance.taskUpdates.listen((update) {
        if (update.taskId == requestId) {
          if (update.status == GenerationStatus.success) {
            _onGenerationComplete(update.mediaUrl);
          } else if (update.status == GenerationStatus.failed) {
            _showError('Processing failed');
          }
        }
      });

    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  void _onGenerationComplete(String? localPath) async {
    if (!mounted || localPath == null) return;

    setState(() {
      _statusMessage = 'Finalizing Blueprint...';
    });

    // Find the saved creation to get ID
    final creations = await MyCreationsService.getCreations();
    final creation = creations.where((c) => c.taskId == _requestId).firstOrNull;
    if (creation == null) return;

    AppNavigator.pushReplacement(
      context,
      ResultScreen(
        originalImage: widget.floorPlanImage,
        generatedImage: File(localPath), // Pass the local file
        styleName: '3D Floor Plan',
        creationId: creation.id,
        allowFromCreations: true,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Processing Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to uploading screen
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, child) {
        if (!isOnline && _requestId == null) {
          return _buildOfflineUI();
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated building icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.domain_add_rounded,
                      size: 64,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    !isOnline ? 'Connection Lost...' : 'Analyzing your plan...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      !isOnline
                          ? "Waiting for internet to resume architecting..."
                          : _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "You can continue using the app.\nYour result will appear in My Creations.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // ✅ Hide Progress Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _requestId == null ? null : _hideProgress,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _requestId == null ? Colors.grey.withOpacity(0.3) : const Color(0xFF3B82F6),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Hide Progress',
                          style: TextStyle(
                            color: _requestId == null ? Colors.grey : const Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideProgress() {
    if (_requestId == null) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing in background. Check My Creations later!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _buildOfflineUI() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'No Internet Connection',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your connection and try again to start your floor plan processing.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _startProcessing(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry Connection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
