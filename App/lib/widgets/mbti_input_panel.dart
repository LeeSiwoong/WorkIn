import 'package:flutter/material.dart';

class MbtiInputPanel extends StatelessWidget {
  final String mbti;
  final ValueChanged<String> onMbtiChange;
  final VoidCallback? onClose;

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
    // mbti가 4글자가 아니어도 항상 반영
    onMbtiChange(newMbti);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.98),
      child: Container(
        width: 300,
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("MBTI 입력", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: '닫기',
                ),
              ],
            ),
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
            // 저장 버튼 제거
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
