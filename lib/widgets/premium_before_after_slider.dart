import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

/// Minimal Professional Before/After Slider
///
/// Design Philosophy: Less is More
/// - Clean white thumb with subtle shadow
/// - Thin, elegant divider line
/// - Minimalist labels that fade gracefully
/// - Smooth but subtle animations
/// - Professional, sophisticated aesthetic

class PremiumBeforeAfterSlider extends StatefulWidget {
  final String beforeImage; // Path or URL
  final String afterImage;  // Path or URL
  final double initialValue;
  final ValueChanged<double> onValueChanged;

  const PremiumBeforeAfterSlider({
    super.key,
    required this.beforeImage,
    required this.afterImage,
    this.initialValue = 0.5,
    required this.onValueChanged,
  });

  @override
  State<PremiumBeforeAfterSlider> createState() =>
      _PremiumBeforeAfterSliderState();
}

class _PremiumBeforeAfterSliderState extends State<PremiumBeforeAfterSlider>
    with TickerProviderStateMixin {
  late double _sliderValue;
  bool _isDragging = false;
  late AnimationController _thumbAnimationController;
  late Animation<double> _thumbScaleAnimation;
  late AnimationController _snapAnimationController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    // Start with Before image fully visible
    _sliderValue = 0.0; 

    // Subtle thumb animation
    _thumbAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _thumbScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _thumbAnimationController, curve: Curves.easeOut),
    );

    // Snap animation controller (also used for intro)
    _snapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Slightly slower for intro
      vsync: this,
    );

    _snapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _snapAnimationController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      setState(() {
        _sliderValue = _snapAnimation.value;
      });
      widget.onValueChanged(_sliderValue);
    });

    // Run the intro animation after a short delay
    _runIntroSequence();
  }

  Future<void> _runIntroSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Phase 1: Swipe Left to Right (0 -> 1)
    _snapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _snapAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    await _snapAnimationController.forward(from: 0.0);
    
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 300)); // Short pause at full After
    
    if (!mounted) return;
    // Phase 2: Rest in Middle (1 -> 0.5)
    _snapAnimationController.duration = const Duration(milliseconds: 600);
    _snapAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _snapAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    await _snapAnimationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    _snapAnimationController.dispose();
    super.dispose();
  }

  void _updateSliderValue(double value) {
    setState(() {
      _sliderValue = value.clamp(0.0, 1.0);
    });
    widget.onValueChanged(_sliderValue);
  }

  void _onDragStart() {
    setState(() => _isDragging = true);
    _thumbAnimationController.forward();
    _snapAnimationController.stop(); // Stop any ongoing snap animation
  }

  void _onDragEnd() {
    setState(() => _isDragging = false);
    _thumbAnimationController.reverse();

    // Snap to nearest edge (left or right)
    final targetValue = _sliderValue < 0.5 ? 0.0 : 1.0;
    _snapAnimationController.duration = const Duration(milliseconds: 300);
    _snapAnimation =
        Tween<double>(begin: _sliderValue, end: targetValue).animate(
          CurvedAnimation(
            parent: _snapAnimationController,
            curve: Curves.easeOut,
          ),
        )..addListener(() {
          setState(() {
            _sliderValue = _snapAnimation.value;
          });
          widget.onValueChanged(_sliderValue);
        });

    _snapAnimationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragStart: (_) => _onDragStart(),
          onHorizontalDragUpdate: (details) {
            _updateSliderValue(details.localPosition.dx / constraints.maxWidth);
          },
          onHorizontalDragEnd: (_) => _onDragEnd(),
          onTapDown: (details) {
            _onDragStart();
            _updateSliderValue(details.localPosition.dx / constraints.maxWidth);
          },
          onTapUp: (_) => _onDragEnd(),
          child: Stack(
            children: [
              // Before Image (Full)
              Positioned.fill(
                child: _buildImage(widget.beforeImage),
              ),

              // After Image (Clipped)
              Positioned.fill(
                child: ClipRect(
                  clipper: _AfterImageClipper(_sliderValue),
                  child: _buildImage(widget.afterImage),
                ),
              ),

              // Minimal Divider Line
              Positioned(
                left: constraints.maxWidth * _sliderValue - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Clean Professional Thumb
              Positioned(
                left: constraints.maxWidth * _sliderValue - 24,
                top: constraints.maxHeight / 2 - 24,
                child: AnimatedBuilder(
                  animation: _thumbScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _thumbScaleAnimation.value,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: _isDragging ? 12 : 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.compare_arrows,
                          color: Colors.grey.shade800,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Minimal BEFORE Label
              Positioned(
                top: 24,
                left: 24,
                child: AnimatedOpacity(
                  opacity: _sliderValue > 0.2 ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BEFORE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // Minimal AFTER Label
              Positioned(
                top: 24,
                right: 24,
                child: AnimatedOpacity(
                  opacity: _sliderValue < 0.8 ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AFTER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String source) {
    if (source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      String cleanPath = source.replaceFirst('file://', '');
      return Image.file(File(cleanPath), fit: BoxFit.contain);
    }
  }
}

/// Custom clipper for the after image
class _AfterImageClipper extends CustomClipper<Rect> {
  final double sliderValue;

  _AfterImageClipper(this.sliderValue);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(size.width * sliderValue, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(_AfterImageClipper oldClipper) {
    return oldClipper.sliderValue != sliderValue;
  }
}
