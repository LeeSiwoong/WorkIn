import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  // Firebase 초기화
  await Firebase.initializeApp();
  final db = FirebaseDatabase.instance;
  final firestore = FirebaseFirestore.instance;
  final rng = Random();

  for (int i = 1; i <= 1000; i++) {
    final userId = 'dummy_user_$i';
    final userData = {
      'userId': userId,
      'temperature': 20 + rng.nextInt(9),
      'humidity': 1 + rng.nextInt(5),
      'brightness': rng.nextInt(11),
      'mbtiEI': rng.nextBool() ? 'E' : 'I',
      'mbtiNS': rng.nextBool() ? 'N' : 'S',
      'mbtiTF': rng.nextBool() ? 'T' : 'F',
      'mbtiPJ': rng.nextBool() ? 'P' : 'J',
      'useBodyInfo': rng.nextBool(),
      'bodyMetrics': {
        'heartRateVariation': 5 + rng.nextInt(21),
        'spo2Average': 95 + rng.nextDouble() * 4,
        'collectedAt': DateTime.now().toIso8601String(),
      },
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    // Realtime Database
    await db.ref('users/$userId').set(userData);
    // Firestore
    await firestore.collection('users').doc(userId).set(userData);
    if (i % 100 == 0) {
      print('Uploaded $i users...');
    }
  }
  print('1000 dummy users uploaded!');
}
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  // Firebase 초기화
  await Firebase.initializeApp();
  final db = FirebaseDatabase.instance;
  final firestore = FirebaseFirestore.instance;
  final rng = Random();

  for (int i = 1; i <= 1000; i++) {
    final userId = 'dummy_user_$i';
    final userData = {
      'userId': userId,
      'temperature': 20 + rng.nextInt(9),
      'humidity': 1 + rng.nextInt(5),
      'brightness': rng.nextInt(11),
      'mbtiEI': rng.nextBool() ? 'E' : 'I',
      'mbtiNS': rng.nextBool() ? 'N' : 'S',
      'mbtiTF': rng.nextBool() ? 'T' : 'F',
      'mbtiPJ': rng.nextBool() ? 'P' : 'J',
      'useBodyInfo': rng.nextBool(),
      'bodyMetrics': {
        'heartRateVariation': 5 + rng.nextInt(21),
        'spo2Average': 95 + rng.nextDouble() * 4,
        'collectedAt': DateTime.now().toIso8601String(),
      },
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    // Realtime Database
    await db.ref('users/$userId').set(userData);
    // Firestore
    await firestore.collection('users').doc(userId).set(userData);
    if (i % 100 == 0) {
      print('Uploaded $i users...');
    }
  }
  print('1000 dummy users uploaded!');
}
