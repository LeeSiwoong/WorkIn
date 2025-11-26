import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TemperatureControl extends StatelessWidget {
  final double temperature;
  final ValueChanged<double> onTemperatureChange;

  const TemperatureControl({
    super.key,
    required this.temperature,
    required this.onTemperatureChange,
  });

  @override
  Widget build(BuildContext context) {
    // Air-conditioner styled UI: seven-segment display + up/down buttons.
    final t = temperature.clamp(18.0, 28.0);
    // AC-like white body
    final bgLightTop = const Color(0xFFF9FAFB);
    final bgLightBottom = const Color(0xFFEDEFF2);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgLightTop, bgLightBottom],
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
          ],
          border: Border.all(color: Colors.black12, width: 0.6),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                // Slightly brighter than pure black for the display background
                color: Color(0xFF0F1115),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Center(
                child: _SevenSegmentTemperature(value: t),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AdjustButton(
                  icon: Icons.keyboard_arrow_down,
                  onChanged: () {
                    HapticFeedback.selectionClick();
                    onTemperatureChange((t - 0.5).clamp(18.0, 28.0));
                  },
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Temperature',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _AdjustButton(
                  icon: Icons.keyboard_arrow_up,
                  onChanged: () {
                    HapticFeedback.selectionClick();
                    onTemperatureChange((t + 0.5).clamp(18.0, 28.0));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onChanged;
  const _AdjustButton({required this.icon, required this.onChanged});

  @override
  State<_AdjustButton> createState() => _AdjustButtonState();
}

class _AdjustButtonState extends State<_AdjustButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final double size = 60; // square button
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onChanged,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _pressed
                    ? const [Color(0xFFE2E4E7), Color(0xFFF5F6F7)]
                    : const [Color(0xFFFDFDFD), Color(0xFFE6E8EB)],
              ),
              boxShadow: _pressed
                  ? const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2), spreadRadius: 0),
                      BoxShadow(color: Colors.white, blurRadius: 2, offset: Offset(1, 1)),
                    ]
                  : const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6)),
                      BoxShadow(color: Colors.white, blurRadius: 4, offset: Offset(-2, -2)),
                    ],
              border: Border.all(color: Colors.black12, width: 0.6),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              color: Colors.black87,
              size: 30,
            ),
          ),
        ),
    );
  }
}

class _SevenSegmentTemperature extends StatelessWidget {
  final double value;
  const _SevenSegmentTemperature({required this.value});

  @override
  Widget build(BuildContext context) {
    // Round to one decimal place to avoid floating errors
    final rounded = (value * 10).round() / 10.0;
    final intVal = rounded.floor();
    final tens = (intVal ~/ 10) % 10;
    final ones = intVal % 10;
    final decimalDigit = ((rounded * 10).round()) % 10; // expect 0 or 5
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
  _SevenSegmentDigit(digit: tens),
  const SizedBox(width: 8),
        // Ones with decimal point at bottom-right
        SizedBox(
          width: 36,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: SizedBox()),
              Positioned.fill(child: _SevenSegmentDigit(digit: ones)),
              // Decimal point LED
              Positioned(
                right: -12,
                bottom: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7CF6FD),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Decimal digit (smaller)
        SizedBox(
          width: 26,
          height: 46,
          child: _SevenSegmentDigit(digit: decimalDigit),
        ),
        const SizedBox(width: 14),
        // Degree + C as a compact overlay: small degree at top-left of a larger C
        SizedBox(
          width: 34,
          height: 32,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                left: 9,
                top: 5,
                child: Text(
                  'C',
                  style: TextStyle(
                    color: Color(0xFF7CF6FD),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    fontSize: 24,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF7CF6FD), width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SevenSegmentDigit extends StatelessWidget {
  final int digit; // 0-9
  const _SevenSegmentDigit({required this.digit});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SevenSegmentPainter(digit: digit),
      size: const Size(36, 64),
    );
  }
}

class _SevenSegmentPainter extends CustomPainter {
  final int digit;
  _SevenSegmentPainter({required this.digit});

  static const ledOn = Color(0xFF7CF6FD); // cyan LED

  @override
  void paint(Canvas canvas, Size size) {
    // Slightly thinner segments for a sleeker look
  final thickness = size.height * 0.12;
  // Extend horizontal segment length (a, d, g) by reducing side margin factor
  // Previously: size.width - thickness * 1.6; now allow more width occupancy.
  final lengthH = size.width - thickness * 0.8;
  // Make vertical segments longer for a more pronounced look
  final lengthV = size.height * 0.40;

    // No neon glow; solid LED color for on, very transparent for off
    final Paint onPaint = Paint()..color = ledOn;
  final Paint offPaint = Paint()..color = ledOn.withValues(alpha: 0.06);

    // Consistent tiny gap between segments
    final double gap = thickness * 0.20;
    // Precompute half thickness and a safe edge margin so vertical segments can move closer to the edges
    final double halfTh = thickness / 2;
    final double edgeMargin = halfTh + gap; // sliver of padding from the canvas edge

    // Segment rectangles positions (squared edges; no rounded corners)
    // a (top)
    // Push the top horizontal segment further up
  final aCenter = Offset(size.width / 2, size.height * 0.05);
    // d (middle)
  final dCenter = Offset(size.width / 2, size.height / 2);
    // g (bottom)
    // Push the bottom horizontal segment further down
  final gCenter = Offset(size.width / 2, size.height * 0.95);
    // b (top-left)
  final bCenter = Offset(edgeMargin, size.height * 0.27);
    // c (top-right)
  final cCenter = Offset(size.width - edgeMargin, size.height * 0.27);
    // e (bottom-left)
  final eCenter = Offset(edgeMargin, size.height * 0.73);
    // f (bottom-right)
  final fCenter = Offset(size.width - edgeMargin, size.height * 0.73);

    Path segH(Offset center) {
      final len = (lengthH - 2 * gap).clamp(0.0, lengthH);
      final halfLen = len / 2;
      final halfTh = thickness / 2;
      final slope = halfTh; // angled depth
      final path = Path();
      path.moveTo(center.dx - halfLen, center.dy); // left tip
      path.lineTo(center.dx - halfLen + slope, center.dy - halfTh);
      path.lineTo(center.dx + halfLen - slope, center.dy - halfTh);
      path.lineTo(center.dx + halfLen, center.dy); // right tip
      path.lineTo(center.dx + halfLen - slope, center.dy + halfTh); 
      path.lineTo(center.dx - halfLen + slope, center.dy + halfTh);
      path.close();
      return path;
    }

    Path segV(Offset center) {
      final len = (lengthV - 2 * gap).clamp(0.0, lengthV);
      final halfLen = len / 2;
      final halfTh = thickness / 2;
      final slope = halfTh; // angled depth
      final path = Path();
      path.moveTo(center.dx, center.dy - halfLen); // top tip
      path.lineTo(center.dx + halfTh, center.dy - halfLen + slope);
      path.lineTo(center.dx + halfTh, center.dy + halfLen - slope);
      path.lineTo(center.dx, center.dy + halfLen); // bottom tip
      path.lineTo(center.dx - halfTh, center.dy + halfLen - slope);
      path.lineTo(center.dx - halfTh, center.dy - halfLen + slope);
      path.close();
      return path;
    }

    // Map digits to active segments [a,b,c,d,e,f,g]
    final map = <int, List<bool>>{
      0: [true, true, true, false, true, true, true],
      1: [false, false, true, false, false, true, false],
      2: [true, false, true, true, true, false, true],
      3: [true, false, true, true, false, true, true],
      4: [false, true, true, true, false, true, false],
      5: [true, true, false, true, false, true, true],
      6: [true, true, false, true, true, true, true],
      7: [true, false, true, false, false, true, false],
      8: [true, true, true, true, true, true, true],
      9: [true, true, true, true, false, true, true],
    };
    final active = map[digit] ?? map[0]!;

    final paths = [
      segH(aCenter), // a
      segV(bCenter), // b
      segV(cCenter), // c
      segH(dCenter), // d
      segV(eCenter), // e
      segV(fCenter), // f
      segH(gCenter), // g
    ];
    for (int i = 0; i < paths.length; i++) {
      canvas.drawPath(paths[i], active[i] ? onPaint : offPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SevenSegmentPainter oldDelegate) => oldDelegate.digit != digit;
}
