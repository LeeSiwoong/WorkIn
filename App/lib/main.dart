import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_screen.dart';
import 'screens/user_id_input_screen.dart';

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
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = _prefs.getString('user_id');
    });
  }

  void _onIdSaved(String id) {
    _prefs.setString('user_id', id);
    setState(() {
      _userId = id;
    });
  }

  void _onProfileDeleted() {
    _prefs.clear();
    setState(() {
      _userId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketHome',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _userId == null
          ? UserIdInputScreen(onIdSaved: _onIdSaved)
          : MainScreen(userId: _userId!, onProfileDeleted: _onProfileDeleted),
    );
  }
}
