import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

import '../../services/helper/background_generation_manager.dart';
import '../../services/helper/connectivity_service.dart';
import '../../services/helper/my_creations_service.dart';
import '../../services/helper/temp_file_upload_service.dart';
import '../../services/kieUse/item_replacement_service.dart';
import '../../services/daily_credit_manager.dart';

import '../../navigation/app_navigator.dart';
import '../exterior/result_screen.dart';
import 'object_removal_result_screen.dart';

class ItemProcessingScreen extends StatefulWidget {
  final File originalImage;
  final File selectedAreaImage;
  final File? replacementImage;
  final String? replacementPrompt;
  final String mode; // 'remove' or 'replace'
  final bool isAccurateMode;
  final String? preUploadedUrl;

  const ItemProcessingScreen({
    super.key,
    required this.originalImage,
    required this.selectedAreaImage,
    this.replacementImage,
    this.replacementPrompt,
    required this.mode,
    this.isAccurateMode = false,
    this.preUploadedUrl,
  });

  @override
  State<ItemProcessingScreen> createState() => _ItemProcessingScreenState();
}

class _ItemProcessingScreenState extends State<ItemProcessingScreen> {
  String _statusMessage = 'Initializing...';
  String? _taskId;
  String? _originalImageUrl;
  StreamSubscription? _taskSubscription;

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

    if (!ConnectivityService.instance.currentStatus) {
      if (mounted) setState(() => _statusMessage = 'Offline');
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
      if (mounted) setState(() => _statusMessage = 'Preparing images...');

      String finalProcessedImageUrl;
      int imageWidth;
      int imageHeight;
      String? selectedAreaUrl;
      String? referenceImageUrl;

      final decodedOriginal = await decodeImageFromList(widget.originalImage.readAsBytesSync());
      imageWidth = decodedOriginal.width;
      imageHeight = decodedOriginal.height;

      // Upload Original Image (Common for both)
      if (widget.preUploadedUrl != null && widget.preUploadedUrl!.isNotEmpty) {
        _originalImageUrl = widget.preUploadedUrl;
      } else {
        if (mounted) setState(() => _statusMessage = 'Uploading original image...');
        _originalImageUrl = await TempFileUploadService.uploadImage(widget.originalImage);
        if (_originalImageUrl == null) throw Exception('Failed to upload original image');
      }
      finalProcessedImageUrl = _originalImageUrl!;

      // Upload Mask Image (Common for both now)
      if (mounted) setState(() => _statusMessage = 'Uploading mask...');
      selectedAreaUrl = await TempFileUploadService.uploadImage(widget.selectedAreaImage);
      if (selectedAreaUrl == null) throw Exception('Failed to upload mask image');

      // Upload Reference Image if present
      if (widget.replacementImage != null) {
        if (mounted) setState(() => _statusMessage = 'Uploading reference image...');
        referenceImageUrl = await TempFileUploadService.uploadImage(widget.replacementImage!);
        if (referenceImageUrl == null) throw Exception('Failed to upload reference image');
      }

      if (mounted) setState(() => _statusMessage = 'Creating task...');

      final taskId = await _createTask(
        finalProcessedImageUrl, 
        selectedAreaUrl, 
        imageWidth, 
        imageHeight,
        referenceImageUrl,
      );
      if (taskId == null) throw Exception('Failed to create task');

      if (!mounted) return;
      setState(() {
        _taskId = taskId;
        _statusMessage = 'AI is working...';
      });

      // ✅ Save as Processing
      final category = widget.mode == 'remove' 
          ? CreationCategory.removeObject 
          : CreationCategory.replaceObject;

      await MyCreationsService.saveProcessingCreation(
        type: CreationType.image,
        category: category,
        taskId: taskId,
        originalMediaUrl: _originalImageUrl,
        metadata: {
          'mode': widget.mode,
          'prompt': widget.replacementPrompt ?? (widget.mode == 'remove' ? 'Remove Object' : 'Replace Object'),
        },
      );

      await BackgroundGenerationManager.instance.attach(
        taskId, 
        CreationType.image, 
        category
      );

      // ✅ Listen for completion
      _taskSubscription = BackgroundGenerationManager.instance.taskUpdates.listen((update) {
        if (update.taskId == taskId) {
          if (update.status == GenerationStatus.success) {
            _onGenerationComplete(update.mediaUrl);
          } else if (update.status == GenerationStatus.failed) {
            _showError('Generation failed.');
          }
        }
      });

    } catch (e) {
      if (mounted) _showError('Failed to process: $e');
    }
  }

  Future<String?> _createTask(
    String processedImageUrl, 
    String maskUrl, 
    int width, 
    int height,
    [String? referenceImageUrl]
  ) async {
    if (widget.mode == 'remove') {
      return ItemReplacementService.createItemReplacementTask(
        originalImageUrl: processedImageUrl,
        maskImageUrl: maskUrl,
        prompt: "Seamlessly remove the selected object and fill the background naturally.",
      );
    } 
    
    // Replacement Mode
    if (referenceImageUrl != null) {
      debugPrint("🚀 Routing to Flux-2 Pro (Image-to-Image)");
      return ItemReplacementService.createFluxReplacementTask(
        originalImageUrl: processedImageUrl,
        maskImageUrl: maskUrl,
        referenceImageUrl: referenceImageUrl,
        prompt: widget.replacementPrompt ?? "Seamlessly integrate the object from the reference image into the masked area of the original image, matching lighting and shadows.",
      );
    } else {
      debugPrint("🚀 Routing to Ideogram V3 (Prompt-based Edit)");
      return ItemReplacementService.createItemReplacementTask(
        originalImageUrl: processedImageUrl,
        maskImageUrl: maskUrl,
        prompt: widget.replacementPrompt ?? "Replace object",
      );
    }
  }

  void _onGenerationComplete(String? localPath) async {
    if (!mounted || localPath == null) return;
    
    setState(() => _statusMessage = 'Finalizing...');

    // Find the saved creation to get ID
    final creations = await MyCreationsService.getCreations();
    final creation = creations.where((c) => c.taskId == _taskId).firstOrNull;
    if (creation == null) return;

    if (mounted) {
      if (widget.mode == 'remove') {
        AppNavigator.pushReplacement(
          context,
          ObjectRemovalResultScreen(
            originalImage: widget.originalImage,
            generatedImage: localPath, // 🔒 Local path
            maskImage: widget.selectedAreaImage,
            isAccurateResult: widget.isAccurateMode,
            creationId: creation.id,
          ),
        );
      } else {
        AppNavigator.pushReplacement(
          context,
          ResultScreen(
            originalImage: widget.originalImage,
            generatedImage: localPath, // 🔒 Local path
            creationId: creation.id,
            buildingType: 'Object Replacement',
            styleName: widget.replacementPrompt ?? 'Custom',
          ),
        );
      }
    }
  }

  void _hideProgress() async {
    if (_taskId == null) return;

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

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.purple),
            const SizedBox(height: 32),
            Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(widget.mode == 'remove' ? 'Removing selected area...' : 'Replacing with new object...', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            // ✅ HIDE PROGRESS BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _taskId == null ? null : _hideProgress,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _taskId == null ? Colors.grey.withOpacity(0.3) : Colors.purple,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Hide Progress',
                    style: TextStyle(
                      color: _taskId == null ? Colors.grey : Colors.purple,
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
    );
  }
}
