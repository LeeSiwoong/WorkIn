import 'package:flutter/material.dart';

class InfoDialog extends StatelessWidget {
  final bool useBodyInfo;
  final ValueChanged<bool> onUseBodyInfoChange;
  final VoidCallback onDismiss;

  const InfoDialog({
    super.key,
    required this.useBodyInfo,
    required this.onUseBodyInfoChange,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("신체 정보 활용"),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("사용자의 신체 정보를 활용합니다"),
          Switch(
            value: useBodyInfo,
            onChanged: onUseBodyInfoChange,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text("확인"),
        ),
      ],
    );
  }
}
