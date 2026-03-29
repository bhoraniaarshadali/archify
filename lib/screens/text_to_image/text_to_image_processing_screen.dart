import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/ApiFreeUse/text_to_image_zimage_service.dart';
import '../../services/helper/background_generation_manager.dart';
import '../../services/helper/connectivity_service.dart';
import '../../services/helper/my_creations_service.dart';
import '../../services/helper/text_to_image_count_service.dart';
import '../../services/daily_credit_manager.dart';
import '../exterior/result_screen.dart';


class TextToImageProcessingScreen extends StatefulWidget {
  final String prompt;
  final String aspectRatio;
  final String designType;

  const TextToImageProcessingScreen({
    super.key,
    required this.prompt,
    required this.aspectRatio,
    required this.designType,
  });

  @override
  State<TextToImageProcessingScreen> createState() => _TextToImageProcessingScreenState();
}

class _TextToImageProcessingScreenState extends State<TextToImageProcessingScreen> {
  String _statusMessage = 'Initializing...';
  String? _requestId;
  bool _isError = false;

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

  Future<void> _startProcessing() async {
    if (!ConnectivityService.instance.currentStatus) {
      if (mounted) setState(() => _isError = true);
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
      if (mounted) setState(() { _statusMessage = 'Creating your design...'; _isError = false; });

      final requestId = await TextToImageZImageService.createZImageTask(
        prompt: widget.prompt,
        aspectRatio: widget.aspectRatio,
      );

      if (requestId == null) throw Exception('Request failed');

      // ✅ Save as Processing
      await MyCreationsService.saveProcessingCreation(
        type: CreationType.image,
        category: CreationCategory.textToImage,
        taskId: requestId,
        metadata: {
          'prompt': widget.prompt,
          'aspectRatio': widget.aspectRatio,
          'designType': widget.designType,
        },
      );

      if (mounted) {
        setState(() {
          _requestId = requestId;
          _statusMessage = 'AI is working on your pixels...';
        });
      }

      // ✅ Attach to background manager immediately
      await BackgroundGenerationManager.instance.attach(
        requestId,
        CreationType.image,
        CreationCategory.textToImage,
      );

      // ✅ Listen for completion
      _taskSubscription = BackgroundGenerationManager.instance.taskUpdates.listen((update) {
        if (update.taskId == requestId) {
          if (update.status == GenerationStatus.success) {
            _onGenerationComplete(update.mediaUrl);
          } else if (update.status == GenerationStatus.failed) {
            _showError('Generation failed.');
          }
        }
      });

    } catch (e) {
      _showError('Failed to process: $e');
    }
  }

  void _onGenerationComplete(String? localPath) async {
    if (!mounted || localPath == null) return;
    
    setState(() => _statusMessage = 'Finalizing...');
    await TextToImageUsageService.incrementGenerationCount();

    // Find the saved creation from local storage to get its ID
    final creations = await MyCreationsService.getCreations();
    final creation = creations.firstWhere((c) => c.taskId == _requestId);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            originalImage: null,
            generatedImage: localPath,
            buildingType: widget.designType,
            styleName: 'AI Generated',
            creationId: creation.id,
            showSlider: false,
            allowFromCreations: true,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isError = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, _) {
        if (!isOnline && _requestId == null) return _buildOfflineUI();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // RepaintBoundary isolates the animation for performance
                const RepaintBoundary(
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.purple),
                ),
                const SizedBox(height: 32),
                 Text(_statusMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Generating ${widget.designType} design...', style: TextStyle(color: Colors.grey[500])),
                
                const SizedBox(height: 60),

                // ✅ HIDE PROGRESS BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _requestId == null ? null : _hideProgress,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _requestId == null ? Colors.grey.withOpacity(0.3) : Colors.purple,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Hide Progress',
                        style: TextStyle(
                          color: _requestId == null ? Colors.grey : Colors.purple,
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
      },
    );
  }

  void _hideProgress() async {
    if (_requestId == null) return;
    await BackgroundGenerationManager.instance.attach(
      _requestId!,
      CreationType.image,
      CreationCategory.textToImage,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing in background. Check My Gallery later!'), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }


  Widget _buildOfflineUI() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            const Text('No Internet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _startProcessing,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}