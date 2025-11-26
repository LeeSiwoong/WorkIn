
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/main_screen.dart';
import 'screens/user_id_input_screen.dart';
import 'screens/splash_screen.dart';
import 'dart:async';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  String? _userId;
  bool _showSplash = true;
  double _fakeProgress = 0.0; // simple progress animation
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    // Hide status bar (Android/iOS) for fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _prefs = await SharedPreferences.getInstance();
    _userId = _prefs.getString('user_id');
    // Simulate incremental progress during 2s splash.
    const total = 2000; // ms
    const tick = 100; // ms
    int elapsed = 0;
    Timer.periodic(const Duration(milliseconds: tick), (timer) {
      elapsed += tick;
      if (!mounted) { timer.cancel(); return; }
      setState(() { _fakeProgress = (elapsed / total).clamp(0.0, 1.0); });
      if (elapsed >= total) {
        timer.cancel();
        if (mounted) {
          setState(() { _showSplash = false; });
        }
      }
    });
  }

  void _onIdSaved(String id) {
    _prefs.setString('user_id', id);
    setState(() {
      _userId = id;
    });
    // ID 입력 후 MainScreen으로 강제 전환
    Future.delayed(const Duration(milliseconds: 100), () {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainScreen(userId: id, onProfileDeleted: _onProfileDeleted)),
          (route) => false,
        );
      }
    });
  }

  void _onProfileDeleted() {
    _prefs.clear();
    setState(() {
      _userId = null;
    });
    // 삭제 후 DB에서 해당 ID가 실제로 사라졌는지 polling 후 ID 입력 화면으로 전환
    Future<void> waitForIdDelete() async {
      const maxWait = Duration(seconds: 2);
      const pollInterval = Duration(milliseconds: 200);
      final String? lastId = _prefs.getString('user_id');
      final start = DateTime.now();
      while (true) {
        bool exists = false;
        try {
          final db = FirebaseDatabase.instance;
          final snap = await db.ref('users/$lastId').get();
          exists = snap.exists;
        } catch (_) {}
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(lastId).get();
          exists = exists || doc.exists;
        } catch (_) {}
        if (!exists) break;
        if (DateTime.now().difference(start) > maxWait) break;
        await Future.delayed(pollInterval);
      }
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => UserIdInputScreen(onIdSaved: _onIdSaved)),
          (route) => false,
        );
      }
    }
    waitForIdDelete();
  }

  @override
  Widget build(BuildContext context) {
    Widget homeWidget = _showSplash
        ? SplashScreen(progress: _fakeProgress)
        : (_userId == null
            ? UserIdInputScreen(onIdSaved: _onIdSaved)
            : MainScreen(userId: _userId!, onProfileDeleted: _onProfileDeleted));
    return MaterialApp(
      title: 'PocketHome',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: homeWidget,
      ),
    );
  }
}
