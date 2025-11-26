import 'dart:math' as math;
import 'package:flutter/material.dart';
import '_outlined_text.dart';

class BrightnessControl extends StatefulWidget {
  final int brightnessLevel; // 0..10
  final ValueChanged<int> onBrightnessLevelChange;

  const BrightnessControl({
    super.key,
    required this.brightnessLevel,
    required this.onBrightnessLevelChange,
  });

  @override
  State<BrightnessControl> createState() => _BrightnessControlState();
}

class _BrightnessControlState extends State<BrightnessControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swayController;
  double _swayTime = 0.0; // 0..1 animation time
  int _lastLevel = 0;

  @override
  void initState() {
    super.initState();
    _lastLevel = widget.brightnessLevel;
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        setState(() {
          _swayTime = _swayController.value; // 0..1
        });
      });
  }

  @override
  void didUpdateWidget(covariant BrightnessControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brightnessLevel != widget.brightnessLevel) {
      // Start a new sway when slider level changes
      _lastLevel = oldWidget.brightnessLevel;
      _swayController
        ..stop()
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _swayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Map discrete level to 0.0-1.0 intensity
    final double t = (widget.brightnessLevel.clamp(0, 10)) / 10.0;
  // Warm flat background (no gradient). Keep hue similar, reduce saturation and brightness as t -> 0.
  // Use the previous level-0 warm as the 10-level base, then desaturate+darken toward 0.
  const baseWarm = Color(0xFFFFF0D6);
  final hslBase = HSLColor.fromColor(baseWarm);
  final double baseSat = hslBase.saturation;
  final double minSat = (baseSat * 0.20).clamp(0.0, 1.0);
  final double sat = minSat + (baseSat - minSat) * t;
  final double minLight = (hslBase.lightness * 0.42).clamp(0.0, 1.0);
  final double maxLight = (hslBase.lightness * 0.90).clamp(0.0, 1.0);
  final double lightness = minLight + (maxLight - minLight) * t;
  final Color bgColor = hslBase.withSaturation(sat).withLightness(lightness).toColor();
    // Text colors tuned for warm background
  final Color titleColor = const Color(0xFF5B3A16); // deep warm brown
  final Color statusColor = const Color(0xFF6E4A1F);
  final Color trackActive = const Color(0xFFFFA000); // orange
  final Color trackInactive = const Color(0x66FFCC80); // semi transparent light orange

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bgColor,
        ),
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double curtainWidth = width * (1.0 - t) / 2.0; // open as t increases
            // Light grayish green curtains whose brightness follows t
            Color curtainBase1 = const Color(0xFFE9F2EA);
            Color curtainBase2 = const Color(0xFFE3EFE6);
            // Darken toward t->0 using HSL
            HSLColor c1 = HSLColor.fromColor(curtainBase1);
            HSLColor c2 = HSLColor.fromColor(curtainBase2);
            final double minCurtainLight = 0.70; // not too dark
            final double l1 = minCurtainLight + (c1.lightness - minCurtainLight) * t;
            final double l2 = minCurtainLight + (c2.lightness - minCurtainLight) * t;
            curtainBase1 = c1.withLightness(l1).toColor();
            curtainBase2 = c2.withLightness(l2).toColor();

            final BoxDecoration curtainDeco = BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [curtainBase1, curtainBase2, curtainBase1],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7CA882).withOpacity(0.12),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                )
              ],
            );

            // Compute sway offset (damped oscillation)
            // amplitude based on openness and recent change
            final double delta = (widget.brightnessLevel - _lastLevel).abs().toDouble();
            // 더 헐렁하고 흔들리게: 진폭, 감쇠, 진동수 조정
            final double baseAmp = 7.0 * (1.0 - t) * (0.7 + 0.3 * delta / 10.0).clamp(0.0, 1.0); // 진폭 완화
            final double damp = 2.2; // 감쇠 강화
            final double freq = 2.2; // 진동수 완화
            final double sway = baseAmp * math.exp(-damp * _swayTime) * math.sin(2 * math.pi * freq * _swayTime);

            return Stack(
              children: [
                // Window backdrop (revealed as curtains open)
                Positioned.fill(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      // Keep window width constant (full card width) so curtains simply cover/reveal it.
                      width: width,
                      height: constraints.maxHeight * 0.55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFBBB2), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFB3D7FF), // sky top
                            Color(0xFFE6F4FF), // sky light
                            Color(0xFFFFF7E9), // warm near sill
                          ],
                        ),
                      ),
                      child: CustomPaint(
                        painter: _WindowFramePainter(openness: t),
                      ),
                    ),
                  ),
                ),
                // Left curtain
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(-sway, 0),
                    child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: curtainWidth.clamp(0.0, width / 2),
                    height: double.infinity,
                    decoration: curtainDeco,
                      child: CustomPaint(
                        painter: FabricTexturePainter(
                          phase: _swayTime * 2 * math.pi,
                          mirror: false,
                        ),
                      ),
                    ),
                  ),
                ),
                // Right curtain
                Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: Offset(sway, 0),
                    child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: curtainWidth.clamp(0.0, width / 2),
                    height: double.infinity,
                    decoration: curtainDeco,
                      child: CustomPaint(
                        painter: FabricTexturePainter(
                          phase: _swayTime * 2 * math.pi + math.pi, // mirrored
                          mirror: true,
                        ),
                      ),
                    ),
                  ),
                ),

                // Foreground content
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedText(
                          text: "Brightness",
                          fontSize: 22,
                          color: titleColor,
                          strokeColor: Colors.white,
                          strokeWidth: 2.2,
                          fontWeight: FontWeight.w800,
                        ),
                        OutlinedText(
                          text: '${(widget.brightnessLevel.clamp(0, 10) * 10).toString()}%',
                          fontSize: 22,
                          color: statusColor,
                          strokeColor: Colors.white,
                          strokeWidth: 2.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    // 슬라이더를 더 아래로 내림
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            activeTrackColor: trackActive,
                            inactiveTrackColor: trackInactive,
                            thumbColor: const Color(0xFFFFA726), // orange sun
                            overlayColor: const Color(0x33FFA726),
                            thumbShape: SunThumbShape(
                              intensity: t,
                              coreColor: const Color(0xFFFFA726),
                              rayColor: const Color(0xFFFFA726),
                              maxRayLen: 8.0,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: 10,
                            divisions: 10,
                            value: widget.brightnessLevel.clamp(0, 10).toDouble(),
                            onChanged: (v) => widget.onBrightnessLevelChange(v.round().clamp(0, 10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WindowFramePainter extends CustomPainter {
  final double openness; // 0..1
  const _WindowFramePainter({required this.openness});

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = const Color(0xFFB0ACA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw outer frame already supplied by parent border; add inner mullions.
    final double mullionWidth = 2;
    final mullionPaint = Paint()
      ..color = const Color(0xFFC7C3BA)
      ..strokeWidth = mullionWidth;

    // Inner frame inset
    final Rect inner = Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3);
    canvas.drawRect(inner, framePaint);

    // Vertical center bar
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), mullionPaint);
    // Horizontal bar about 40% down
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), mullionPaint);

    // Optional subtle sun glow based on openness
    if (openness > 0.05) {
      final sunRadius = 18.0 + 12.0 * openness;
      final sunCenter = Offset(size.width * 0.25, size.height * 0.25);
      final sunGradient = RadialGradient(
        colors: [
          const Color(0xFFFFD77A).withOpacity(0.85 * openness),
          const Color(0xFFFFF3D0).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
      final sunPaint = Paint()..shader = sunGradient;
      canvas.drawCircle(sunCenter, sunRadius, sunPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WindowFramePainter oldDelegate) => oldDelegate.openness != openness;
}

class SunThumbShape extends SliderComponentShape {
  final double intensity; // 0..1 controls ray length
  final double radius;
  final Color? coreColor;
  final Color? rayColor;
  final double maxRayLen; // cap length so it doesn't get too long at 10

  const SunThumbShape({
    required this.intensity,
    this.radius = 10,
    this.coreColor,
    this.rayColor,
    this.maxRayLen = 8.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    // Reserve space for max rays to avoid layout jumps.
    final r = radius + maxRayLen + 2;
    return Size(r * 2, r * 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter? labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

  // Colors derived from params/theme
  final Color sunCore = coreColor ?? sliderTheme.thumbColor ?? const Color(0xFFFFEB3B);
  final Color rays = (rayColor ?? sunCore).withOpacity(0.95);

    // Draw sun core
    final Paint corePaint = Paint()..color = sunCore;
    canvas.drawCircle(center, radius, corePaint);

    // Draw rays
    final Paint rayPaint = Paint()
      ..color = rays
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    final int rayCount = 8;
    // Ray length: 0 at intensity=0; up to maxRayLen at intensity=1.
    final double rayLen = (intensity <= 0.001) ? 0.0 : maxRayLen * intensity;

    if (rayLen > 0) {
      for (int i = 0; i < rayCount; i++) {
        final double angle = (2 * math.pi / rayCount) * i;
        final Offset dir = Offset(math.cos(angle), math.sin(angle));
        final Offset start = center + dir * (radius + 2);
        final Offset end = center + dir * (radius + 2 + rayLen);
        canvas.drawLine(start, end, rayPaint);
      }
    }
  }
}

class FabricTexturePainter extends CustomPainter {
  final double phase; // animate folds
  final bool mirror;

  const FabricTexturePainter({required this.phase, this.mirror = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle vertical folds using a sinusoidal shading, plus weave lines
    final Paint lightStripe = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.08)
      ..strokeWidth = 1.0;
    final Paint darkStripe = Paint()
      ..color = const Color(0xFF7CA882).withOpacity(0.08)
      ..strokeWidth = 0.8;

    // Folds: variable intensity lines
    const double spacingV = 10.0;
    final double dir = mirror ? -1.0 : 1.0;
    for (double x = 0; x <= size.width; x += spacingV) {
      // modulation shifts with phase for sway effect
      final double modulation = 0.5 + 0.5 * math.sin((x * 0.10 * dir) + phase);
      lightStripe.color = const Color(0xFFFFFFFF).withOpacity(0.04 + 0.06 * modulation);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lightStripe);

      // Offset darker thread in between
      final double x2 = x + spacingV * 0.5;
      if (x2 <= size.width) {
        darkStripe.color = const Color(0xFF7CA882).withOpacity(0.05 + 0.05 * (1 - modulation));
        canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), darkStripe);
      }
    }

    // Horizontal fine lines for cross-weave
    final Paint crossWeave = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.04)
      ..strokeWidth = 0.8;
    const double spacingH = 8.0;
    for (double y = 0; y <= size.height; y += spacingH) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), crossWeave);
    }
  }

  @override
  bool shouldRepaint(covariant FabricTexturePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.mirror != mirror;
  }
}
