import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const DeleteConfirmationDialog({
    super.key,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("프로필 삭제"),
      content: const Text("프로필을 삭제하시겠습니까? 모든 설정이 초기화됩니다."),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text("취소"),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text("삭제", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
