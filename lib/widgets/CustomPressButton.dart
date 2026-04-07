import 'package:flutter/material.dart';

class CustomPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  final Duration duration;
  final double darkOpacity;

  const CustomPressButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 40,
    this.duration = const Duration(milliseconds: 20),
    this.darkOpacity = 0.35,
  });

  @override
  State<CustomPressButton> createState() => _CustomPressButtonState();
}

class _CustomPressButtonState extends State<CustomPressButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!mounted) return;
    if (_pressed != v) {
      setState(() => _pressed = v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled
          ? (_) {
              _setPressed(false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            widget.child,

            /// DARK OVERLAY
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: widget.duration,
                  opacity: enabled && _pressed ? widget.darkOpacity : 0,
                  child: Container(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
