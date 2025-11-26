import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final double progress; // 0..1 optional progress
  const SplashScreen({super.key, this.progress = 0.0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E86AB), Color(0xFF6CB4D9), Color(0xFFBEE7F5)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PocketHome',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  value: progress == 0.0 ? null : progress, // indeterminate until we have a value
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD77A)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '로딩 중...',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
