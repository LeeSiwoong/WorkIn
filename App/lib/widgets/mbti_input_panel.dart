import 'package:flutter/material.dart';

class MbtiInputPanel extends StatelessWidget {
  final String mbti;
  final ValueChanged<String> onMbtiChange;
  final VoidCallback onClose;

  const MbtiInputPanel({
    super.key,
    required this.mbti,
    required this.onMbtiChange,
    required this.onClose,
  });

  void _updateMbti(String newChar) {
    final sortedChars = "EINSTFPJ";
    var currentChars = mbti.split('').toSet();

    if (currentChars.contains(newChar)) {
      currentChars.remove(newChar);
    } else {
      switch (newChar) {
        case 'E':
        case 'I':
          currentChars.removeAll(['E', 'I']);
          break;
        case 'N':
        case 'S':
          currentChars.removeAll(['N', 'S']);
          break;
        case 'T':
        case 'F':
          currentChars.removeAll(['T', 'F']);
          break;
        case 'P':
        case 'J':
          currentChars.removeAll(['P', 'J']);
          break;
      }
      currentChars.add(newChar);
    }

    final newMbti = sortedChars.split('').where((c) => currentChars.contains(c)).join();
    onMbtiChange(newMbti);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: 300,
        height: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MBTI 입력", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: ['E', 'N', 'T', 'P'].map((char) {
                return Expanded(
                  child: MbtiButton(
                    text: char,
                    isSelected: mbti.contains(char),
                    onPressed: () => _updateMbti(char),
                  ),
                );
              }).toList(),
            ),
            Row(
              children: ['I', 'S', 'F', 'J'].map((char) {
                return Expanded(
                  child: MbtiButton(
                    text: char,
                    isSelected: mbti.contains(char),
                    onPressed: () => _updateMbti(char),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("저장"),
            ),
          ],
        ),
      ),
    );
  }
}

class MbtiButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;

  const MbtiButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF2E86AB) : Colors.grey[300],
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
