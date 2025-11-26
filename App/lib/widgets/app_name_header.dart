import 'package:flutter/material.dart';

class AppNameHeader extends StatelessWidget {
  final String userId;
  final VoidCallback onHeartClick;
  final VoidCallback onPlusClick;
  final VoidCallback onUserIdClick;

  const AppNameHeader({
    super.key,
    required this.userId,
    required this.onHeartClick,
    required this.onPlusClick,
    required this.onUserIdClick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2E86AB),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: onHeartClick,
            tooltip: '신체 정보 활용',
          ),
          GestureDetector(
            onTap: onUserIdClick,
            child: Text(
              userId,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: onPlusClick,
            tooltip: 'MBTI 입력',
          ),
        ],
      ),
    );
  }
}
