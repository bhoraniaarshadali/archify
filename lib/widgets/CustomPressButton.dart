import 'package:flutter/material.dart';

class CustomPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleValue;

  const CustomPressButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleValue = 0.95,
  });

  @override
  State<CustomPressButton> createState() => _CustomPressButtonState();
}

class _CustomPressButtonState extends State<CustomPressButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
