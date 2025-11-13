import 'package:flutter/material.dart';

class UserIdInputScreen extends StatefulWidget {
  final Function(String) onIdSaved;

  const UserIdInputScreen({super.key, required this.onIdSaved});

  @override
  State<UserIdInputScreen> createState() => _UserIdInputScreenState();
}

class _UserIdInputScreenState extends State<UserIdInputScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isButtonEnabled = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("아이디를 입력하세요", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "사용자 ID",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isButtonEnabled
                  ? () => widget.onIdSaved(_controller.text)
                  : null,
              child: const Text("저장"),
            ),
          ],
        ),
      ),
    );
  }
}
