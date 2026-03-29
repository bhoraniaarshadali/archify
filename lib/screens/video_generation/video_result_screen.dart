// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:gal/gal.dart';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import '../../services/helper/my_creations_service.dart';
//
// class VideoResultScreen extends StatefulWidget {
//   final String videoUrl;
//   final String category;
//   final int duration;
//   final String? originalImageUrl;
//   final String? creationId;
//   final bool allowFromCreations;
//
//   const VideoResultScreen({
//     super.key,
//     required this.videoUrl,
//     required this.category,
//     required this.duration,
//     this.originalImageUrl,
//     this.creationId,
//     this.allowFromCreations = false,
//   });
//
//   @override
//   State<VideoResultScreen> createState() => _VideoResultScreenState();
// }
//
// class _VideoResultScreenState extends State<VideoResultScreen> {
//   late VideoPlayerController _controller;
//   bool _isInitialized = false;
//   bool _isSaving = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializePlayer();
//     if (!widget.allowFromCreations) {
//       _saveToMyCreations();
//     }
//   }
//
//   Future<void> _initializePlayer() async {
//     if (widget.videoUrl.startsWith('http')) {
//       _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
//     } else {
//       _controller = VideoPlayerController.file(File(widget.videoUrl));
//     }
//     try {
//       await _controller.initialize();
//       await _controller.setLooping(true);
//       await _controller.setVolume(0.0); // Muted by default
//       await _controller.play();
//       if (mounted) {
//         setState(() {
//           _isInitialized = true;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error initializing video player: $e');
//     }
//   }
//
//   Future<void> _saveToMyCreations() async {
//     await MyCreationsService.saveCreation(
//       MyCreation(
//         id: widget.creationId ?? DateTime.now().millisecondsSinceEpoch.toString(),
//         type: CreationType.video,
//         category: _getCategoryEnum(widget.category),
//         mediaUrl: widget.videoUrl,
//         originalMediaUrl: widget.originalImageUrl,
//         createdAt: DateTime.now(),
//         metadata: {
//           'duration': widget.duration,
//           'category': widget.category,
//         },
//       ),
//     );
//   }
//
//   CreationCategory _getCategoryEnum(String category) {
//     switch (category) {
//       case 'Interior':
//         return CreationCategory.interior;
//       case 'Exterior':
//         return CreationCategory.exterior;
//       case '3D Model':
//         return CreationCategory.model3D;
//       default:
//         return CreationCategory.interior;
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   Future<void> _downloadVideo() async {
//     setState(() => _isSaving = true);
//     try {
//       final response = await http.get(Uri.parse(widget.videoUrl));
//       final bytes = response.bodyBytes;
//       final tempDir = await getTemporaryDirectory();
//       final file = File('${tempDir.path}/generated_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
//       await file.writeAsBytes(bytes);
//
//       await Gal.putVideo(file.path);
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Video saved to gallery!')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to save video: $e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Generated Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Center(
//               child: _isInitialized
//                   ? AspectRatio(
//                       aspectRatio: _controller.value.aspectRatio,
//                       child: VideoPlayer(_controller),
//                     )
//                   : const CircularProgressIndicator(color: Colors.white),
//             ),
//           ),
//
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(30),
//                 topRight: Radius.circular(30),
//               ),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Video Generated Successfully!',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Your AI cinematic animation is ready.',
//                   style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _isSaving ? null : _downloadVideo,
//                         icon: _isSaving
//                           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
//                           : const Icon(Icons.download, color: Colors.black),
//                         label: Text(_isSaving ? 'Saving...' : 'Download', style: const TextStyle(color: Colors.black)),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey[200],
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           SharePlus.instance.share('Check out this AI-generated home design video! ${widget.videoUrl}' as ShareParams);
//                         },
//                         icon: const Icon(Icons.share, color: Colors.white),
//                         label: const Text('Share', style: TextStyle(color: Colors.white)),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.indigo,
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   child: TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('Done', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../services/helper/my_creations_service.dart';

class VideoResultScreen extends StatefulWidget {
  final String videoUrl;
  final String category;
  final int duration;
  final String? originalImageUrl;
  final String? creationId;
  final bool allowFromCreations;

  const VideoResultScreen({
    super.key,
    required this.videoUrl,
    required this.category,
    required this.duration,
    this.originalImageUrl,
    this.creationId,
    this.allowFromCreations = false,
  });

  @override
  State<VideoResultScreen> createState() => _VideoResultScreenState();
}

class _VideoResultScreenState extends State<VideoResultScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isPlaying = true;
  bool _isMuted = true;
  bool _showControls = true;

  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _setupCelebrationAnimation();
    if (!widget.allowFromCreations) {
      _saveToMyCreations();
    }
  }

  void _setupCelebrationAnimation() {
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _celebrationAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );
    _celebrationController.forward();
  }

  Future<void> _initializePlayer() async {
    if (widget.videoUrl.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    } else {
      _controller = VideoPlayerController.file(File(widget.videoUrl));
    }
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0.0);
      await _controller.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      _controller.addListener(() {
        if (mounted) setState(() {});
      });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load video. Please try again.');
      }
    }
  }

  Future<void> _saveToMyCreations() async {
    try {
      await MyCreationsService.saveCreation(
        MyCreation(
          id: widget.creationId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          type: CreationType.video,
          category: _getCategoryEnum(widget.category),
          mediaUrl: widget.videoUrl,
          originalMediaUrl: widget.originalImageUrl,
          createdAt: DateTime.now(),
          metadata: {
            'duration': widget.duration,
            'category': widget.category,
          },
        ),
      );
    } catch (e) {
      debugPrint('Error saving to My Creations: $e');
    }
  }

  CreationCategory _getCategoryEnum(String category) {
    switch (category) {
      case 'Interior':
        return CreationCategory.interior;
      case 'Exterior':
        return CreationCategory.exterior;
      case '3D Model':
        return CreationCategory.model3D;
      default:
        return CreationCategory.interior;
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo() async {
    setState(() => _isSaving = true);
    try {
      final response = await http.get(Uri.parse(widget.videoUrl));
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/ai_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.writeAsBytes(bytes);

      await Gal.putVideo(file.path);

      if (mounted) {
        _showSuccessSnackBar('Video saved to gallery!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareVideo() async {
    try {
      final response = await http.get(Uri.parse(widget.videoUrl));
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_video.mp4');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this AI-generated video!',
      );
    } catch (e) {
      Share.share(
        'Check out this AI-generated video! ${widget.videoUrl}',
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  IconData _getCategoryIcon() {
    switch (widget.category) {
      case 'Interior':
        return Icons.meeting_room_rounded;
      case 'Exterior':
        return Icons.landscape_rounded;
      case '3D Model':
        return Icons.view_in_ar_rounded;
      default:
        return Icons.movie_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _showControls = !_showControls),
                  child: _isInitialized
                      ? Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                      if (_showControls) _buildVideoControls(),
                    ],
                  )
                      : _buildLoadingState(),
                ),
              ),
            ),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Video Ready!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(),
                      size: 14,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.category} • ${widget.duration}s',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF6366F1),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading your video...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildVideoControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        children: [
          if (_isInitialized) _buildProgressBar(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onTap: _togglePlayPause,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatDuration(position),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatDuration(duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor:
            const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E1E1E).withOpacity(0.95),
            const Color(0xFF1E1E1E),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.download_rounded,
                  label: _isSaving ? 'Saving...' : 'Download',
                  onTap: _isSaving ? null : _downloadVideo,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: _shareVideo,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Done Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Done',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final LinearGradient gradient;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: onTap != null ? gradient : null,
        color: onTap == null ? Colors.white.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onTap != null
            ? [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}