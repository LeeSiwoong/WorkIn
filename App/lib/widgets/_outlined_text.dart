import 'package:flutter/material.dart';

/// 텍스트에 흰색 테두리(아웃라인)를 주는 위젯
class OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final FontWeight fontWeight;

  const OutlinedText({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.strokeColor,
    required this.strokeWidth,
    required this.fontWeight,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Stroke
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        // Fill
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
      ],
    );
  }
}
