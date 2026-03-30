import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'dart:io';
import 'dart:async';
import '../../services/helper/connectivity_service.dart';
import '../../services/helper/image_compression_service.dart';
import '../../services/helper/my_creations_service.dart';
import '../../services/helper/temp_file_upload_service.dart';
import '../../utils/loading_tips_provider.dart';
import '../../navigation/app_navigator.dart';

import '../../core/design_mode.dart';
import '../../ads/remote_config_service.dart';
import '../../models/interior_style_model.dart' as exp;
import '../../services/interior/interior_design_pipeline.dart';
import '../../services/interior/interior_image_service.dart';
import '../../services/helper/background_generation_manager.dart';
import '../../services/daily_credit_manager.dart';
import '../exterior/result_screen.dart';


class InteriorLoadingScreen extends StatefulWidget {
  final File uploadedImage;
  final String? preUploadedUrl;
  final RoomType roomType;
  final exp.InteriorStyle interiorStyle;
  final List<String> selectedColors;
  final int transformationProgress;

  const InteriorLoadingScreen({
    super.key,
    required this.uploadedImage,
    this.preUploadedUrl,
    required this.roomType,
    required this.interiorStyle,
    required this.selectedColors,
    required this.transformationProgress,
  });

  @override
  State<InteriorLoadingScreen> createState() => _InteriorLoadingScreenState();
}

class _InteriorLoadingScreenState extends State<InteriorLoadingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _tipTimer;
  String _statusMessage = 'Initializing AI...';
  String? _taskId;
  String? _uploadedUrl;
  int _currentTipIndex = 0;
  Map<String, String> _currentTip = LoadingTipsProvider.getTip(0);
  late AnimationController _pulseController;
  StreamSubscription? _taskSubscription;

  void _startTipRotation() {
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % LoadingTipsProvider.tipCount;
          _currentTip = LoadingTipsProvider.getTip(_currentTipIndex);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startTipRotation();

    // Start generation process after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createTask();
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

    if (!ConnectivityService.instance.currentStatus) {
      if (mounted) setState(() => _statusMessage = 'Offline');
      return;
    }

    // 🪙 1. Check Credit Availability (No deduction yet)
    if (mounted) {
      final canProceed = await DailyCreditManager.checkCreditOnly(context);
      if (!canProceed) {
        if (mounted) Navigator.pop(context);
        return;
      }
    }

    try {
      if (!mounted) return;
      _uploadedUrl = widget.preUploadedUrl;
      
      if (_uploadedUrl == null || _uploadedUrl!.isEmpty) {
        if (mounted) setState(() => _statusMessage = 'Optimizing Image...');
        final compressedImage = await ImageCompressionService.compressImage(widget.uploadedImage);
        
        if (!mounted) return;
        if (mounted) setState(() => _statusMessage = 'Uploading...');
        _uploadedUrl = await TempFileUploadService.uploadImage(compressedImage);
        
        if (_uploadedUrl == null || _uploadedUrl!.isEmpty) {
          throw Exception('Upload failed');
        }
      }

      if (!mounted) return;
      if (mounted) setState(() => _statusMessage = 'AI is Dreaming... ✨');
      
      // Get image dimensions for the API
      final decodedImage = await decodeImageFromList(await widget.uploadedImage.readAsBytes());
      final int imageWidth = decodedImage.width;
      final int imageHeight = decodedImage.height;

      // Build Prompt
      final finalPrompt = InteriorDesignPipeline.buildPrompt(
        styleName: widget.interiorStyle.styleName,
        stylePrompt: widget.interiorStyle.prompt,
        selectedColors: widget.selectedColors,
        progress: widget.transformationProgress,
        roomType: widget.roomType.displayName,
      );


      // Submit Task
      if (mounted) {
        final provider = RemoteConfigService.getInteriorProviderSelection();
        setState(() => _statusMessage = provider == 'kie' 
            ? 'AI is designing your interior... ✨' 
            : 'AI is Dreaming... ✨');
      }

      final taskId = await InteriorImageService.editInteriorImage(
        imageUrl: _uploadedUrl!,
        prompt: finalPrompt,
        width: imageWidth,
        height: imageHeight,
      );

      if (taskId == null) throw Exception('AI Generation failed to start');
      
      // 🪙 2. Successful Submission -> DEDUCT CREDIT
      await DailyCreditManager.consumeCredit();
      
      if (!mounted) return;
      
      // ✅ Save to My Creations as "Processing"
      await MyCreationsService.saveProcessingCreation(
        type: CreationType.image,
        category: CreationCategory.interior,
        taskId: taskId,
        originalMediaUrl: _uploadedUrl,
        metadata: {
          'styleId': widget.interiorStyle.templateId,
          'styleName': widget.interiorStyle.styleName,
          'roomType': widget.roomType.name,
          'transformation': widget.transformationProgress,
          'colors': widget.selectedColors,
        },
      );

      if (mounted) {
        final provider = RemoteConfigService.getInteriorProviderSelection();
        setState(() {
          _taskId = taskId;
          _statusMessage = provider == 'kie' 
              ? 'AI is designing your interior... ✨' 
              : 'Generating Design...';
        });
      }

      // ✅ Attach to background manager immediately
      await BackgroundGenerationManager.instance.attach(
        taskId, 
        CreationType.image, 
        CreationCategory.interior
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
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _onGenerationComplete(String? localPath) async {
    if (!mounted || localPath == null) return;
    
    setState(() => _statusMessage = 'Finalizing...');
    
    // Find the saved creation to get ID
    final creations = await MyCreationsService.getCreations();
    final creation = creations.firstWhereOrNull((c) => c.taskId == _taskId);
    if (creation == null) return;

    if (mounted) {
      AppNavigator.pushReplacement(
        context,
        ResultScreen(
          originalImage: _uploadedUrl,
          generatedImage: localPath, // 🔒 Local Path
          buildingType: 'Interior - ${widget.roomType.displayName}',
          styleName: widget.interiorStyle.styleName,
          colorPalette: widget.selectedColors.join(', '),
          creationId: creation.id,
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
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
                colors: [const Color(0xFF0EA5E9).withOpacity(0.05), Colors.white],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // AI Pulse Animation
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.1).animate(_pulseController),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chair_alt_outlined,
                            color: const Color(0xFF0EA5E9),
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF0EA5E9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Status Message
                Text(
                  !isOnline ? 'Connection Lost...' : _statusMessage,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  !isOnline 
                      ? "Waiting for internet to resume processing..." 
                      : "Transforming your ${widget.roomType.displayName.toLowerCase()}...",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                        color: const Color(0xFF0EA5E9).withOpacity(0.1),
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
                            Text(
                              _currentTip['icon'] ?? '💡',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currentTip['title']?.toUpperCase() ?? 'DID YOU KNOW?',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0EA5E9),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentTip['message'] ?? '',
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

                // Bottom Warning
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.blue[800],
                    ),
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

                const SizedBox(height: 30),

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
                          color: _taskId == null 
                              ? Colors.grey.withOpacity(0.3) 
                              : const Color(0xFF0EA5E9),
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
                              : const Color(0xFF0EA5E9),
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

    // Manager is already attached after task creation

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing in background. Check My Creations later!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate to Home or Pop
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
                'Please check your connection and try again to start your design.',
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
                    backgroundColor: const Color(0xFF0EA5E9),
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
