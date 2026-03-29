import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'item_processing_screen.dart';
import 'item_replacement_upload_screen.dart';

class ItemReplaceScreen extends StatefulWidget {
  final File generatedImage;
  final File originalImage;
  final String mode; // 'remove' or 'replace'
  final String? preUploadedUrl;

  const ItemReplaceScreen({
    super.key,
    required this.generatedImage,
    required this.originalImage,
    this.mode = 'replace',
    this.preUploadedUrl,
  });

  @override
  State<ItemReplaceScreen> createState() => _ItemReplaceScreenState();
}
  
class _ItemReplaceScreenState extends State<ItemReplaceScreen> {
  // Store multiple strokes (each stroke is a list of points)
  final List<List<Offset>> _strokes = [];
  final List<List<Offset>> _redoStrokes = [];

  List<Offset> _currentStroke = [];
  double _brushSize = 60.0;
  bool _isDrawing = false;
  final GlobalKey _imageKey = GlobalKey();

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStrokes.add(_strokes.removeLast());
    });
  }

  void _redo() {
    if (_redoStrokes.isEmpty) return;
    setState(() {
      _strokes.add(_redoStrokes.removeLast());
    });
  }

  void _clearAll() {
    setState(() {
      _redoStrokes.clear();
      _strokes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.mode == 'remove' ? 'Object Removal' : 'Object Replacement',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Step 2 of 3',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          // Tooltip/Hint
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_fix_normal_rounded,
                  color: Colors.deepPurpleAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Paint over the area you want to ${widget.mode}',
                  style: const TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Editor Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _isDrawing = true;
                            _currentStroke = [details.localPosition];
                            // Clear redo stack when new stroke starts
                            _redoStrokes.clear();
                          });
                        },
                        onPanUpdate: (details) {
                          if (_isDrawing) {
                            setState(() {
                              _currentStroke.add(details.localPosition);
                            });
                          }
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _isDrawing = false;
                            if (_currentStroke.isNotEmpty) {
                              _strokes.add(List.from(_currentStroke));
                              _currentStroke = [];
                            }
                          });
                        },
                        child: Stack(
                          children: [
                            // Base Image
                            Image.file(
                              widget.generatedImage,
                              key: _imageKey,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            // Transparent Overlay with Painting
                            CustomPaint(
                              painter: TransparentSelectionPainter(
                                completedStrokes: _strokes,
                                currentStroke: _currentStroke,
                                brushSize: _brushSize,
                              ),
                              size: Size.infinite,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),

          // Controls Panel
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final hasAnyStrokes = _strokes.isNotEmpty || _currentStroke.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Undo/Redo/Clear Row
          Row(
            children: [
              // Undo
              IconButton(
                onPressed: _strokes.isEmpty ? null : _undo,
                icon: Icon(
                  Icons.undo_rounded,
                  color: _strokes.isEmpty ? Colors.grey.shade700 : Colors.white,
                ),
                tooltip: 'Undo',
              ),
              // Redo
              IconButton(
                onPressed: _redoStrokes.isEmpty ? null : _redo,
                icon: Icon(
                  Icons.redo_rounded,
                  color: _redoStrokes.isEmpty ? Colors.grey.shade700 : Colors.white,
                ),
                tooltip: 'Redo',
              ),
              const Spacer(),
              // Clear All
              IconButton(
                onPressed: hasAnyStrokes ? _clearAll : null,
                icon: Icon(
                  Icons.delete_sweep_rounded,
                  color: hasAnyStrokes ? Colors.redAccent : Colors.grey.shade700,
                ),
                tooltip: 'Clear All',
              ),
            ],
          ),

          const Divider(color: Colors.white10, height: 24),

          // Brush Size Control
          Row(
            children: [
              const Icon(Icons.brush_rounded, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.deepPurpleAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    overlayColor: Colors.deepPurpleAccent.withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _brushSize,
                    min: 20,
                    max: 150,
                    divisions: 26,
                    onChanged: (v) => setState(() => _brushSize = v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_brushSize.round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showTips,
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  label: const Text('Tips'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: hasAnyStrokes ? _continueToDescription : null,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withOpacity(0.05),
                    disabledForegroundColor: Colors.grey.shade700,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTips() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Editing Tips',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _tipItem(
              Icons.gesture,
              'Paint smooth strokes over the object you want to ${widget.mode}',
            ),
            _tipItem(
              Icons.layers,
              'You can paint multiple separate areas on the same image',
            ),
            _tipItem(
              Icons.brush,
              'Adjust brush size for better precision on edges',
            ),
            _tipItem(
              Icons.undo,
              'Use undo/redo to refine your selection',
            ),
            _tipItem(
              Icons.delete_sweep,
              'Clear all to start fresh if needed',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepPurpleAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _continueToDescription() async {
    if (_strokes.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
      ),
    );

    try {
      final maskImage = await _generateMaskImage();
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      if (maskImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process selection'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (widget.mode == 'remove') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemProcessingScreen(
              originalImage: widget.generatedImage,
              selectedAreaImage: maskImage,
              mode: 'remove',
              preUploadedUrl: widget.preUploadedUrl,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemReplacementUploadScreen(
              originalImage: widget.generatedImage,
              selectedAreaImage: maskImage,
              preUploadedUrl: widget.preUploadedUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<File?> _generateMaskImage() async {
    try {
      final RenderBox? box =
      _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || _strokes.isEmpty) return null;

      // Get Image Info
      final imageBytes = await widget.generatedImage.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Calculate Scaling
      final double imageAspectRatio = image.width / image.height;
      final double boxAspectRatio = box.size.width / box.size.height;

      double scale;
      double offsetX = 0;
      double offsetY = 0;

      if (imageAspectRatio > boxAspectRatio) {
        scale = image.width / box.size.width;
        double scaledHeight = image.height / scale;
        offsetY = (box.size.height - scaledHeight) / 2;
      } else {
        scale = image.height / box.size.height;
        double scaledWidth = image.width / scale;
        offsetX = (box.size.width - scaledWidth) / 2;
      }

      // Create Mask
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White Background (Protected Area)
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        bgPaint,
      );

      // Black Mask (Selected Areas)
      final maskPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = _brushSize * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final circlePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      // Draw all strokes
      for (final stroke in _strokes) {
        if (stroke.isEmpty) continue;

        final mappedStroke = stroke.map((p) {
          return Offset(
            (p.dx - offsetX) * scale,
            (p.dy - offsetY) * scale,
          );
        }).toList();

        // Draw lines
        for (int i = 0; i < mappedStroke.length - 1; i++) {
          canvas.drawLine(mappedStroke[i], mappedStroke[i + 1], maskPaint);
        }

        // Draw circles
        for (final point in mappedStroke) {
          canvas.drawCircle(point, (_brushSize / 2) * scale, circlePaint);
        }
      }

      // Save Mask Image
      final picture = recorder.endRecording();
      final maskImage = await picture.toImage(image.width, image.height);

      final byteData = await maskImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final maskFile = File(
        '${tempDir.path}/mask_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await maskFile.writeAsBytes(pngBytes);

      return maskFile;
    } catch (e) {
      debugPrint("Error generating mask: $e");
      return null;
    }
  }
}

/// Professional transparent overlay painter with smooth strokes
class TransparentSelectionPainter extends CustomPainter {
  final List<List<Offset>> completedStrokes;
  final List<Offset> currentStroke;
  final double brushSize;

  TransparentSelectionPainter({
    required this.completedStrokes,
    required this.currentStroke,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for completed strokes
    final completedPaint = Paint()
      ..color = Colors.deepPurpleAccent.withOpacity(0.4)
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final completedCirclePaint = Paint()
      ..color = Colors.deepPurpleAccent.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Paint for current stroke (brighter)
    final currentPaint = Paint()
      ..color = Colors.deepPurpleAccent.withOpacity(0.6)
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final currentCirclePaint = Paint()
      ..color = Colors.deepPurpleAccent.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw all completed strokes
    for (final stroke in completedStrokes) {
      if (stroke.isEmpty) continue;

      // Draw lines
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], completedPaint);
      }

      // Draw circles for smooth appearance
      for (final point in stroke) {
        canvas.drawCircle(point, brushSize / 2, completedCirclePaint);
      }
    }

    // Draw current stroke (being drawn)
    if (currentStroke.isNotEmpty) {
      // Draw lines
      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], currentPaint);
      }

      // Draw circles
      for (final point in currentStroke) {
        canvas.drawCircle(point, brushSize / 2, currentCirclePaint);
      }
    }
  }

  @override
  bool shouldRepaint(TransparentSelectionPainter oldDelegate) {
    return oldDelegate.completedStrokes.length != completedStrokes.length ||
        oldDelegate.currentStroke.length != currentStroke.length ||
        oldDelegate.brushSize != brushSize;
  }
}