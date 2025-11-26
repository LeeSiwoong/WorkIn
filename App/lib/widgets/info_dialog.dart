import 'package:flutter/material.dart';

class InfoDialog extends StatelessWidget {
  final bool useBodyInfo;
  final ValueChanged<bool> onUseBodyInfoChange;
  final VoidCallback onDismiss;
  final bool hideConfirm;

  const InfoDialog({
    super.key,
    required this.useBodyInfo,
    required this.onUseBodyInfoChange,
    required this.onDismiss,
    this.hideConfirm = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("신체 정보 활용"),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("사용자의 신체 정보를 활용합니다"),
          _NoAnimationSwitch(
            value: useBodyInfo,
            onChanged: onUseBodyInfoChange,
          ),
        ],
      ),
      actions: hideConfirm ? null : [
        TextButton(
          onPressed: onDismiss,
          child: const Text("확인"),
        ),
      ],
    );
  }
}

/// Switch without animation for instant toggle feedback
class _NoAnimationSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NoAnimationSwitch({required this.value, required this.onChanged});

  @override
  State<_NoAnimationSwitch> createState() => _NoAnimationSwitchState();
}

class _NoAnimationSwitchState extends State<_NoAnimationSwitch> {
  bool? _internalValue;

  @override
  void didUpdateWidget(covariant _NoAnimationSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _internalValue) {
      _internalValue = widget.value;
    }
  }

  @override
  void initState() {
    super.initState();
    _internalValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: Container(
        width: 52,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.value ? Colors.blue : Colors.grey.shade400,
        ),
        alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
