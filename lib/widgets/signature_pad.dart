import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SignaturePad extends StatefulWidget {
  final Function(Uint8List signature) onSignatureChanged;
  final Color penColor;
  final double penStrokeWidth;
  final Color backgroundColor;

  const SignaturePad({
    super.key,
    required this.onSignatureChanged,
    this.penColor = Colors.black,
    this.penStrokeWidth = 3.0,
    this.backgroundColor = Colors.white,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final GlobalKey _signatureKey = GlobalKey();
  final List<Offset> _points = [];
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Signature canvas
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: RepaintBoundary(
              key: _signatureKey,
              child: CustomPaint(
                painter: _SignaturePainter(
                  points: _points,
                  color: widget.penColor,
                  strokeWidth: widget.penStrokeWidth,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          
          // Clear button
          if (_points.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: _clearSignature,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          
          // Hint text
          if (_points.isEmpty)
            const Center(
              child: Text(
                'Подпишите здесь',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          
          // Drawing surface
          Positioned.fill(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _isDrawing = true;
      _points.add(localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _points.add(localPosition);
    });
    
    _captureSignature();
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
    });
    
    _captureSignature();
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
    });
    widget.onSignatureChanged(Uint8List(0));
  }

  Future<void> _captureSignature() async {
    if (_points.isEmpty) {
      widget.onSignatureChanged(Uint8List(0));
      return;
    }

    try {
      final RenderRepaintBoundary boundary = _signatureKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage();
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        widget.onSignatureChanged(pngBytes);
      }
    } catch (e) {
      // Handle error
    }
  }

  void clear() {
    _clearSignature();
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  _SignaturePainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
