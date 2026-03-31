import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import '../../services/remote_config_controller.dart';
import '../../ads/remote_config_service.dart';
import '../../ads/nativeAds/reel_native_ad_helper.dart';
import 'reel_ad_item.dart';

class ReelsScreen extends StatefulWidget {
  final bool isActuallyVisible;
  const ReelsScreen({super.key, this.isActuallyVisible = false});

  // Global mute state for the session
  static bool isGlobalMuted = false;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  final RemoteConfigController _remoteConfigController =
      Get.find<RemoteConfigController>();
  int _currentPage = 0;

  List<String> get _videoUrls =>
      _remoteConfigController.adsVariable.value.reelsUrls;

  // 📺 Ad Logic
  late int _adFrequency;
  // Use a map to store ad helpers for specific positions to ensure they persist while scrolling
  final Map<int, ReelNativeAdHelper> _adHelpers = {};

  @override
  void initState() {
    super.initState();
    _adFrequency = RemoteConfigService.getReelAdFrequency();
    // Initial preload of the first few videos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadVideos(0);
      _preloadAds(0);
    });
  }

  void _preloadAds(int currentIndex) {
    if (RemoteConfigService.isReelAdsDisabled()) return;

    // Preload next 2 ad slots
    // If freq = 2, slots are 2, 5, 8...
    // Current slot index: (currentIndex + 1) ~/ (_adFrequency + 1)
    int currentSlotGroup = (currentIndex + 1) ~/ (_adFrequency + 1);

    for (int i = 1; i <= 2; i++) {
      int nextAdSlotIndex = (currentSlotGroup + i) * (_adFrequency + 1) - 1;

      if (nextAdSlotIndex > 0 && !_adHelpers.containsKey(nextAdSlotIndex)) {
        debugPrint('🚀 Preloading Reel Ad at index $nextAdSlotIndex');
        final helper = ReelNativeAdHelper();
        helper.loadAd(() {});
        _adHelpers[nextAdSlotIndex] = helper;
      }
    }
  }

  void _preloadVideos(int currentIndex) {
    if (_videoUrls.isEmpty) return;

    // Preload next 3 videos
    for (int i = currentIndex + 1; i <= currentIndex + 3; i++) {
      final actualIndex = i % _videoUrls.length;
      final url = _videoUrls[actualIndex];
      _safePreload(url);
    }
  }

  Future<void> _safePreload(String url) async {
    try {
      await DefaultCacheManager().getSingleFile(url);
    } catch (e) {
      debugPrint('Preload error for $url: $e');
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
            _preloadAds(index);
          },
          itemBuilder: (context, index) {
            // 🪙 Ad Logic: Show ad after frequency
            // Formula: every (freq + 1) items is an ad slot.
            // Example freq=2, slots = 2, 5, 8, 11...
            // If freq=2, we want: Reel(0), Reel(1), Ad(2), Reel(3), Reel(4), Ad(5)...

            final bool isAdSlot =
                index > 0 && (index + 1) % (_adFrequency + 1) == 0;

            if (isAdSlot && !RemoteConfigService.isReelAdsDisabled()) {
              if (!_adHelpers.containsKey(index)) {
                _adHelpers[index] = ReelNativeAdHelper()
                  ..loadAd(() {
                    if (mounted && _currentPage == index) setState(() {});
                  });
              }

              final helper = _adHelpers[index]!;

              // If ad failed, automatically skip to next reel (per requirement)
              if (helper.lastError != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_currentPage == index) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
                return const SizedBox.shrink();
              }

              return ReelAdItem(adHelper: helper);
            }

            // Calculate actual video index
            // Subtract number of ad slots before this index
            final int adSlotsBefore = (index + 1) ~/ (_adFrequency + 1);
            final int actualIndex = (index - adSlotsBefore) % _videoUrls.length;

            return ReelItem(
              key: ValueKey('reel_$index'), // Unique key for each page
              videoUrl: _videoUrls[actualIndex],
              isActive: widget.isActuallyVisible && index == _currentPage,
              onMuteToggle: () {
                setState(() {});
              },
            );
          },
        );
      }),
    );
  }

  @override
  void dispose() {
    for (var helper in _adHelpers.values) {
      helper.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }
}

class ReelItem extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onMuteToggle;
  final bool isActive;
  const ReelItem({
    super.key,
    required this.videoUrl,
    this.onMuteToggle,
    required this.isActive,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDownloading = false;

  // For showing mute/unmute icon briefly
  bool _showMuteIndicator = false;
  String _errorMsg = 'Failed to load video';
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Slower, smoother fade
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
      final File file = await DefaultCacheManager().getSingleFile(
        widget.videoUrl,
      );
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
        bool isNetworkError = e is SocketException || e is HttpException ||
            e.toString().contains('Connection failed');
        setState(() {
          _hasError = true;
          _errorMsg = isNetworkError
              ? 'No internet connection'
              : 'Failed to load video';
        });
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

    _fadeController.reset();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _fadeController.forward().then((_) {
          if (mounted) {
            setState(() => _showMuteIndicator = false);
          }
        });
      }
    });

    widget.onMuteToggle?.call();
  }

  Future<void> _downloadVideo() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      // 1. Check for storage permission
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }

      if (!hasAccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage permission denied. Please enable it in settings.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 2. Get file from cache (it should already be there since video is playing)
      final File file = await DefaultCacheManager().getSingleFile(
        widget.videoUrl,
      );

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
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isInitialized && _controller != null)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          )
        else if (_hasError)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  _errorMsg,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        // Mute/Unmute Indicator Overlay
        if (_showMuteIndicator)
          Center(
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 1.0,
                end: 0.0,
              ).animate(_fadeController),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ReelsScreen.isGlobalMuted
                      ? Icons.volume_off
                      : Icons.volume_up,
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
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mute/Unmute Action Button
              _buildActionButton(
                ReelsScreen.isGlobalMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                ReelsScreen.isGlobalMuted ? 'Muted' : 'Sound',
                onTap: _toggleMute,
              ),
              const SizedBox(height: 20),
              // Download Action Button
              _buildActionButton(
                Icons.file_download_outlined,
                'Download',
                onTap: _downloadVideo,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 24),
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
