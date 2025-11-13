import 'package:flutter/material.dart';

class HumidityControl extends StatelessWidget {
  final int selectedLevel;
  final ValueChanged<int> onLevelSelected;

  const HumidityControl({
    super.key,
    required this.selectedLevel,
    required this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Color.lerp(const Color(0xFFB3E5FC), const Color(0xFF01579B), selectedLevel / 5)!;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bg.withOpacity(0.85), bg],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Humidity",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final level = index + 1;
                final isSelected = (level == selectedLevel);
                return _WaterDrop(
                  filled: level <= selectedLevel,
                  large: level <= selectedLevel,
                  selected: isSelected,
                  onTap: () => onLevelSelected(level),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              _humidityLabel(selectedLevel),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _humidityLabel(int level) {
  switch (level) {
    case 1:
      return 'Very Dry';
    case 2:
      return 'Dry';
    case 3:
      return 'Neutral';
    case 4:
      return 'Humid';
    case 5:
      return 'Very Humid';
    default:
      return '';
  }
}

class _WaterDrop extends StatelessWidget {
  final bool filled;
  final bool large;
  final bool selected;
  final VoidCallback onTap;

  const _WaterDrop({required this.filled, required this.large, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = filled ? Colors.white : Colors.white54;
    final double diameter = large ? 56 : 44;
    final double iconSize = large ? 30 : 26;
    return InkResponse(
      onTap: onTap,
      radius: diameter / 2 + 6,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: diameter,
        height: diameter,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: base.withOpacity(0.22),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.water_drop,
            color: base,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
