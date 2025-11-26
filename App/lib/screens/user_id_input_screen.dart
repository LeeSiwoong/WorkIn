import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonEnabled ? _handleSavePressed : null,
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSavePressed() async {
    final id = _controller.text.trim();
    if (id.isEmpty) return;
    // Ensure Firebase initialized (defensive; normally already in main).
    if (Firebase.apps.isEmpty) {
      try { await Firebase.initializeApp(); } catch (_) {}
    }

    final db = FirebaseDatabase.instance;
    bool existsRealtime = false;
    try {
      final snap = await db.ref('users/$id').get();
      existsRealtime = snap.exists;
    } catch (_) {}

    bool existsFirestore = false;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      existsFirestore = doc.exists;
    } catch (_) {}

    if (existsRealtime || existsFirestore) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('아이디 중복'),
            content: const Text('이미 존재하는 아이디입니다. 다른 아이디를 입력해주세요.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('확인')),
            ],
          ),
        );
      }
      return; // Block navigation
    }
    widget.onIdSaved(id);
  }
}
