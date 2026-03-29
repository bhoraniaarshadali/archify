import 'dart:async';
import 'package:flutter/material.dart';
import '../../navigation/app_navigator.dart';
import '../../services/helper/background_generation_manager.dart';

import '../../services/helper/my_creations_service.dart';
import './video_result_screen.dart';

class VideoGenerationLoadingScreen extends StatefulWidget {
  final String requestId;
  final String category;
  final int duration;
  final String? originalImageUrl;

  const VideoGenerationLoadingScreen({
    super.key,
    required this.requestId,
    required this.category,
    required this.duration,
    this.originalImageUrl,
  });

  @override
  State<VideoGenerationLoadingScreen> createState() => _VideoGenerationLoadingScreenState();
}

class _VideoGenerationLoadingScreenState extends State<VideoGenerationLoadingScreen> {
  double _progress = 0.05;
  Timer? _progressTimer;
  String? _errorMessage;
  StreamSubscription? _taskSubscription;

  void _startProgressSimulation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_progress < 0.95) {
        if (mounted) {
          setState(() {
            _progress += 0.005; // Smooth incremental progress
          });
        }
      } else {
        _progressTimer?.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _saveProcessingCreation();
    _startBackgroundPolling();
    _startProgressSimulation();
  }

  void _startBackgroundPolling() async {
    // ✅ Attach to background manager immediately
    CreationCategory cat = CreationCategory.interior;
    try {
      cat = CreationCategory.values.byName(widget.category.toLowerCase());
    } catch (_) {}

    await BackgroundGenerationManager.instance.attach(
      widget.requestId,
      CreationType.video,
      cat,
    );

    // ✅ Listen for completion
    _taskSubscription = BackgroundGenerationManager.instance.taskUpdates.listen((update) {
      if (update.taskId == widget.requestId) {
        if (update.status == GenerationStatus.success) {
          _onGenerationComplete(update.mediaUrl);
        } else if (update.status == GenerationStatus.failed) {
          if (mounted) {
            setState(() {
              _errorMessage = "Failed to generate video. Please try again.";
            });
          }
        }
      }
    });
  }

  Future<void> _saveProcessingCreation() async {
    CreationCategory cat = CreationCategory.interior;
    try {
      cat = CreationCategory.values.byName(widget.category.toLowerCase());
    } catch (_) {}

    await MyCreationsService.saveProcessingCreation(
      type: CreationType.video,
      category: cat,
      taskId: widget.requestId,
      originalMediaUrl: widget.originalImageUrl,
      metadata: {
        'duration': widget.duration,
        'originalImage': widget.originalImageUrl,
      },
    );
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _onGenerationComplete(String? localPath) async {
    if (!mounted || localPath == null) return;
    
    setState(() {
      _errorMessage = null;
      _progress = 1.0;
    });

    if (mounted) {
      AppNavigator.pushReplacement(
        context,
        VideoResultScreen(
          videoUrl: localPath, // 🔒 Local path
          category: widget.category,
          duration: widget.duration,
          originalImageUrl: widget.originalImageUrl,
          creationId: widget.requestId, // Using taskId as creationId placeholder if not found, but we should find it
          allowFromCreations: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage == null) ...[
                const SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'This may take a minute or two.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Colors.blue[800]),
                    const SizedBox(width: 6),
                    Text(
                      "You can continue using the app.\nYour result will appear in My Creations.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ✅ HIDE PROGRESS BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _hideProgress,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.indigo, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Hide Progress',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _hideProgress() async {
    CreationCategory cat = CreationCategory.interior;
    try {
      cat = CreationCategory.values.byName(widget.category.toLowerCase());
    } catch (_) {}

    await BackgroundGenerationManager.instance.attach(
      widget.requestId,
      CreationType.video,
      cat,
    );

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
}
