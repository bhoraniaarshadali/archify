import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../core/design_mode.dart';
import '../../services/helper/connectivity_service.dart';
import '../../services/helper/image_compression_service.dart';
import '../../services/helper/my_creations_service.dart';
import '../../services/helper/temp_file_upload_service.dart';
import '../../services/daily_credit_manager.dart';
import '../exterior/result_screen.dart';
import '../../services/kieUse/garden_service.dart';
import '../../utils/loading_tips_provider.dart';
import '../../navigation/app_navigator.dart';
import '../../services/helper/background_generation_manager.dart';


class GardenLoadingScreen extends StatefulWidget {
  final File uploadedImage;
  final String? preUploadedUrl;
  final GardenStyle gardenStyle;
  final String? colorPalette;

  const GardenLoadingScreen({
    super.key,
    required this.uploadedImage,
    this.preUploadedUrl,
    required this.gardenStyle,
    this.colorPalette,
  });

  @override
  State<GardenLoadingScreen> createState() => _GardenLoadingScreenState();
}

class _GardenLoadingScreenState extends State<GardenLoadingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _tipTimer;
  String _statusMessage = 'Initializing...';
  String? _taskId;
  String? _userImageUrl;
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

    // Defer _createTask until after the first frame to ensure context is available for ScaffoldMessenger
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
      
      String? userImageUrl = widget.preUploadedUrl;

      if (userImageUrl == null || userImageUrl.isEmpty) {
        if (mounted) setState(() => _statusMessage = 'Preparing Image...');
        final compressedImage = await ImageCompressionService.compressImage(widget.uploadedImage);
        
        if (!mounted) return;
        if (mounted) setState(() => _statusMessage = 'Uploading...');
        _userImageUrl = await TempFileUploadService.uploadImage(compressedImage);
        
        try {
          if (compressedImage.path != widget.uploadedImage.path) {
            await compressedImage.delete();
          }
        } catch (e) {}
      } else {
        _userImageUrl = userImageUrl;
      }

      if (_userImageUrl == null || _userImageUrl!.isEmpty) throw Exception('Upload failed');

      if (!mounted) return;
      if (mounted) setState(() => _statusMessage = 'AI is Designing Garden...');
      
      final taskId = await GardenService.createGardenTask(
        userImageUrl: _userImageUrl!,
        gardenStyle: widget.gardenStyle.displayName,
        colorPalette: widget.colorPalette,
      );
      
      if (taskId == null) throw Exception('Generation failed to start');
      
      // 🪙 2. Successful Submission -> DEDUCT CREDIT
      await DailyCreditManager.consumeCredit();
      if (!mounted) return;

      // ✅ Save as Processing
      await MyCreationsService.saveProcessingCreation(
        type: CreationType.image,
        category: CreationCategory.garden,
        taskId: taskId,
        originalMediaUrl: _userImageUrl,
        metadata: {
          'buildingType': 'Garden',
          'styleName': widget.gardenStyle.displayName,
          'colorPalette': widget.colorPalette,
        },
      );

      if (mounted) {
        setState(() {
          _taskId = taskId;
          _statusMessage = 'Designing your Garden - ${widget.gardenStyle.displayName}...';
        });
      }

      // ✅ Attach to background manager immediately
      await BackgroundGenerationManager.instance.attach(
        taskId, 
        CreationType.image, 
        CreationCategory.garden
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
          originalImage: _userImageUrl,
          generatedImage: localPath, // 🔒 Local path
          buildingType: 'Garden',
          styleName: widget.gardenStyle.displayName,
          colorPalette: widget.colorPalette,
          creationId: creation.id,
          allowFromCreations: true,
        ),
      );
    }
  }


  Future<File?> _preDownloadResult(String url) async {
    try {
      setState(() => _statusMessage = 'Finalizing your garden design...');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/garden_res_${DateTime.now().millisecondsSinceEpoch}.png');
        return await file.writeAsBytes(response.bodyBytes);
      }
    } catch (e) {
      debugPrint("Download error: $e");
    }
    return null;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, child) {
        if (!isOnline && _taskId == null) return _buildOfflineUI();
        return Scaffold(
          backgroundColor: const Color(0xFFFDFBFF),
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.withOpacity(0.05), Colors.white],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.1).animate(_pulseController),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 30, spreadRadius: 10)],
                    ),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation<Color>(Colors.green))),
                  ),
                ),
                const SizedBox(height: 50),
                Text(!isOnline ? 'Connection Lost...' : _statusMessage, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Planting your ideas...", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 60),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    key: ValueKey<int>(_currentTipIndex),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.green.withOpacity(0.1)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_currentTip['icon'] ?? '💡', style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            const Text('GARDEN TIP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.green, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_currentTip['message'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5)),
                      ],
                    ),
                  ),
                ),
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
                          color: _taskId == null ? Colors.grey.withOpacity(0.3) : Colors.green,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Hide Progress',
                        style: TextStyle(
                          color: _taskId == null ? Colors.grey : Colors.green,
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
    await BackgroundGenerationManager.instance.attach(
      _taskId!,
      CreationType.image,
      CreationCategory.garden,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing in background. Check My Creations later!'), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }


  Widget _buildOfflineUI() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
            const Text('No Internet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => _createTask(), child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
