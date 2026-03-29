import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import '../../services/remote_config_controller.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  // Global mute state for the session
  static bool isGlobalMuted = false;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  final RemoteConfigController _remoteConfigController = Get.find<RemoteConfigController>();
  int _currentPage = 0;

  List<String> get _videoUrls => _remoteConfigController.adsVariable.value.reelsUrls;

  @override
  void initState() {
    super.initState();
    // Initial preload of the first few videos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadVideos(0);
    });
  }

  void _preloadVideos(int currentIndex) {
    if (_videoUrls.isEmpty) return;
    
    // Preload next 3 videos
    for (int i = currentIndex + 1; i <= currentIndex + 3; i++) {
      final actualIndex = i % _videoUrls.length;
      final url = _videoUrls[actualIndex];
      // Trigger cache download without waiting for it
      DefaultCacheManager().getSingleFile(url).catchError((e) {
        debugPrint('Preload error for $url: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (_videoUrls.isEmpty) {
          return const Center(
            child: Text(
              'No reels available',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        
        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          // Use a very large number for infinite scroll effect
          itemCount: 999999, 
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
            _preloadVideos(index);
          },
          itemBuilder: (context, index) {
            final actualIndex = index % _videoUrls.length;
            return ReelItem(
              key: ValueKey('reel_$index'), // Unique key for each page
              videoUrl: _videoUrls[actualIndex],
              isActive: index == _currentPage,
              onMuteToggle: () {
                setState(() {});
              },
            );
          },
        );
      }),
    );
  }
}

class ReelItem extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onMuteToggle;
  final bool isActive;
  const ReelItem({super.key, required this.videoUrl, this.onMuteToggle, required this.isActive});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDownloading = false;
  
  // For showing mute/unmute icon briefly
  bool _showMuteIndicator = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initializeVideo();
  }

  @override
  void didUpdateWidget(ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized && _controller != null) {
      if (widget.isActive && !oldWidget.isActive) {
        _controller!.play();
      } else if (!widget.isActive && oldWidget.isActive) {
        _controller!.pause();
        // Option: _controller!.seekTo(Duration.zero);
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final File file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      _controller = VideoPlayerController.file(file);
      
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _controller!.setLooping(true);
          // Apply global mute state
          _controller!.setVolume(ReelsScreen.isGlobalMuted ? 0 : 1);
          if (widget.isActive) {
            _controller!.play();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Video Cache Error: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    
    setState(() {
      ReelsScreen.isGlobalMuted = !ReelsScreen.isGlobalMuted;
      _controller!.setVolume(ReelsScreen.isGlobalMuted ? 0 : 1);
      _showMuteIndicator = true;
    });

    _fadeController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showMuteIndicator = false);
        }
      });
    });

    widget.onMuteToggle?.call();
  }

  Future<void> _downloadVideo() async {
    if (_isDownloading) return;
    
    setState(() => _isDownloading = true);
    
    try {
      // 1. Check for storage permission (gal handles this internally mostly, but we trigger the attempt)
      final bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      // 2. Get file from cache (it should already be there since video is playing)
      final File file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      
      // 3. Save to gallery
      await Gal.putVideo(file.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video saved to gallery! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Download Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save video. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleMute,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (_hasError)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text('Failed to load video', style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          
          // Mute/Unmute Indicator Overlay
          if (_showMuteIndicator)
            Center(
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ReelsScreen.isGlobalMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),

          // UI Overlay
          Positioned(
            bottom: 40,
            left: 16,
            right: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '@archify_ai',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check out this amazing AI-generated interior transformation! ✨ #InteriorDesign #AI',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Right side buttons
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                _buildActionButton(
                  _isDownloading ? Icons.hourglass_empty : Icons.file_download_outlined, 
                  _isDownloading ? 'Downloading...' : 'Download',
                  onTap: _downloadVideo,
                  isLoading: _isDownloading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onTap, bool isLoading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: isLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 12, 
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
