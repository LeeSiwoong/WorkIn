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
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('이용약관'),
                      content: const SingleChildScrollView(
                        child: Text(
                          "본 서비스를 사용함으로써 사용자 본인의 개인정보(ID, 선호 환경) 및 선택적 개인정보(입력 시 MBTI, 신체 정보 등)가 데이터베이스에 업로드되며, 모델 학습에 활용됨에 동의합니다. 동의하시지 않는 경우 앱을 사용하실 수 없습니다.",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('닫기'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('이용약관'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '확인 버튼을 눌러 앱을 사용함으로써 이용약관에 동의합니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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
}
