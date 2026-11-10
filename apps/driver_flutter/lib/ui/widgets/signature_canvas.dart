import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

class SignatureCanvas extends StatefulWidget {
  final ValueChanged<bool> onSignatureChanged;

  const SignatureCanvas({super.key, required this.onSignatureChanged});

  @override
  State<SignatureCanvas> createState() => SignatureCanvasState();
}

class SignatureCanvasState extends State<SignatureCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  bool get hasSignature => _strokes.isNotEmpty;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    widget.onSignatureChanged(false);
  }

  void signQuickPreset() {
    setState(() {
      _strokes.clear();
      // Draw signature curve simulation
      _strokes.add([
        const Offset(30, 70),
        const Offset(60, 40),
        const Offset(90, 80),
        const Offset(130, 45),
        const Offset(180, 65),
        const Offset(240, 50),
      ]);
    });
    widget.onSignatureChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AviationColors.gold500, width: 1.5),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentStroke = [details.localPosition];
                _strokes.add(_currentStroke);
              });
              widget.onSignatureChanged(true);
            },
            onPanUpdate: (details) {
              setState(() {
                _currentStroke.add(details.localPosition);
              });
            },
            child: CustomPaint(
              painter: _SignaturePainter(strokes: _strokes),
              size: Size.infinite,
            ),
          ),
          if (!hasSignature)
            const Positioned(
              bottom: 12,
              left: 16,
              child: Text(
                '✍️ Passenger / Lead Booker Sign Here On Glass',
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                TextButton(
                  onPressed: signQuickPreset,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  child: const Text('QUICK SIGN', style: TextStyle(color: Colors.black87, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.black54, size: 20),
                  onPressed: clear,
                  tooltip: 'Clear Signature',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
