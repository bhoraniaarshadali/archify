import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
// Need for decoding
import '../../services/helper/connectivity_service.dart';
import '../../services/helper/image_compression_service.dart';
import '../../services/helper/my_creations_service.dart';
import '../../services/helper/temp_file_upload_service.dart';
import '../../utils/loading_tips_provider.dart';
import '../exterior/result_screen.dart';
import '../../services/ApiFreeUse/style_transfer_service.dart';
import '../../navigation/app_navigator.dart';
import '../../services/helper/background_generation_manager.dart';
import 'package:collection/collection.dart';


class StyleTransferLoadingScreen extends StatefulWidget {
  final File originalImage;
  final File referenceImage;

  const StyleTransferLoadingScreen({
    super.key,
    required this.originalImage,
    required this.referenceImage,
  });

  @override
  State<StyleTransferLoadingScreen> createState() => _StyleTransferLoadingScreenState();
}

class _StyleTransferLoadingScreenState extends State<StyleTransferLoadingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _tipTimer;
  String _statusMessage = 'Analyzing Images...';
  String? _taskId;
  String? _originalImageUrl;
  int _currentTipIndex = 0;
  Map<String, String> _currentTip = LoadingTipsProvider.getTip(0);
  late AnimationController _pulseController;
  StreamSubscription? _taskSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _createTask();
    _startTipRotation();
  }

  void _startTipRotation() {
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex =
              (_currentTipIndex + 1) % LoadingTipsProvider.tipCount;
          _currentTip = LoadingTipsProvider.getTip(_currentTipIndex);
        });
      }
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _pulseController.dispose();
    _taskSubscription?.cancel();
    super.dispose();
  }

  bool _isCreatingTask = false;

  Future<void> _createTask() async {
    if (_isCreatingTask) return;
    _isCreatingTask = true;

    // Check connectivity first
    if (!ConnectivityService.instance.currentStatus) {
      setState(() => _statusMessage = 'Offline');
      return;
    }

    try {
      if (!mounted) return;
      
      // Upload Original Image
      setState(() => _statusMessage = 'Uploading Original Image...');
      final compressedOriginal = await ImageCompressionService.compressImage(
        widget.originalImage,
      );
      _originalImageUrl = await TempFileUploadService.uploadImage(compressedOriginal);
      
      if (!mounted) return;
      
      final compressedReference = await ImageCompressionService.compressImage(
        widget.referenceImage,
      );
      final referenceUrl = await TempFileUploadService.uploadImage(compressedReference);

      try {
        if (compressedOriginal.path != widget.originalImage.path) {
          await compressedOriginal.delete();
        }
        if (compressedReference.path != widget.referenceImage.path) {
          await compressedReference.delete();
        }
      } catch (e) {}
      
      if (_originalImageUrl == null || referenceUrl == null) {
        throw Exception('Upload failed');
      }

      final decodedImage = await decodeImageFromList(
          widget.originalImage.readAsBytesSync());

      if (!mounted) return;
      
      setState(() => _statusMessage = 'Applying Style...');
      
      // Use Style Transfer Service
      final taskId = await StyleTransferService.createStyleTransferTask(
        originalImageUrl: _originalImageUrl!,
        referenceImageUrl: referenceUrl,
        width: decodedImage.width,
        height: decodedImage.height,
      );
      
      if (taskId == null) throw Exception('Generation failed to start');
      if (!mounted) return;

      // ✅ Save to My Creations as "Processing"
      await MyCreationsService.saveProcessingCreation(
        type: CreationType.image,
        category: CreationCategory.styleTransfer,
        taskId: taskId,
        originalMediaUrl: _originalImageUrl,
        metadata: {
          'styleName': 'Style Transfer',
        },
      );

      setState(() {
        _taskId = taskId;
        _statusMessage = 'In Queue...';
      });

      // ✅ Attach to background manager immediately
      await BackgroundGenerationManager.instance.attach(
        taskId,
        CreationType.image,
        CreationCategory.styleTransfer,
      );

      // ✅ Listen for completion via BackgroundManager
      _taskSubscription = BackgroundGenerationManager.instance
          .taskUpdates.listen((update) {
        if (update.taskId == taskId) {
          if (update.status == GenerationStatus.success) {
            _handleSuccess(update.mediaUrl);
          } else if (update.status == GenerationStatus.failed) {
            _showError('Generation failed.');
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }


  void _handleSuccess(String? localPath) async {
    if (!mounted || localPath == null) return;
    setState(() => _statusMessage = 'Finalizing...');

    final creations = await MyCreationsService.getCreations();
    final creation = creations.firstWhereOrNull(
        (c) => c.taskId == _taskId
    );

    if (creation != null && mounted) {
      AppNavigator.pushReplacement(
        context,
        ResultScreen(
          originalImage: _originalImageUrl,
          generatedImage: creation.mediaUrl,
          buildingType: 'Style Transfer',
          styleName: 'Reference Style',
          colorPalette: 'Custom',
          creationId: creation.id,
        ),
      );
    } else {
      if (mounted) _showError('Failed to save result.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, child) {
        if (!isOnline && _taskId == null) {
          return _buildOfflineUI();
        }
        return Scaffold(
          backgroundColor: const Color(0xFFFDFBFF),
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFFEC4899).withOpacity(0.05), Colors.white],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Magic Wand Animation
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.1).animate(_pulseController),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_fix_high,
                      color: Color(0xFFEC4899),
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                Text(
                  !isOnline ? 'Connection Lost...' : _statusMessage,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 60),

                // Tip Card
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    key: ValueKey<int>(_currentTipIndex),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFEC4899).withOpacity(0.1),
                      ),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_currentTip['icon']!, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              _currentTip['title']!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEC4899),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentTip['message']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _taskId == null ? null : _hideProgress,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _taskId == null
                              ? Colors.grey.withOpacity(0.3)
                              : const Color(0xFFEC4899),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Hide Progress',
                        style: TextStyle(
                          color: _taskId == null
                              ? Colors.grey
                              : const Color(0xFFEC4899),
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
    if (_taskId == null) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Processing in background. Check My Creations later!'
          ),
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
                'Please check your connection and try again to start your style transfer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _createTask(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
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
