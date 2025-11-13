import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_settings.dart';
import '../firebase_database_config.dart';
import '../widgets/app_name_header.dart';
import '../widgets/brightness_control.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/humidity_control.dart';
import '../widgets/info_dialog.dart';
import '../widgets/mbti_input_panel.dart';
import '../widgets/temperature_control.dart';

class MainScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onProfileDeleted;

  const MainScreen({super.key, required this.userId, required this.onProfileDeleted});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late SharedPreferences _prefs;
  double _temperature = 26.0;
  int _humidity = 3;
  int _brightness = 2; // 0..10 discrete
  bool _useBodyInfo = false;
  String _mbtiEI = ""; // E or I or ""
  String _mbtiNS = ""; // N or S or ""
  String _mbtiTF = ""; // T or F or ""
  String _mbtiPJ = ""; // P or J or ""

  String get _mbtiCombined {
    return [_mbtiEI, _mbtiNS, _mbtiTF, _mbtiPJ].where((e) => e.isNotEmpty).join();
  }

  bool _showInfoPopup = false;
  bool _showMbtiOverlay = false;
  bool _showDeleteConfirmation = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _temperature = _prefs.getDouble('temperature') ?? 26.0;
      _humidity = _prefs.getInt('humidity') ?? 3;
      // Migrate brightness: prefer new int key, fallback to legacy double (0.0-1.0) * 10 rounding.
      if (_prefs.containsKey('brightness')) {
        // Could be legacy double or new int; attempt int first
        final dynamic raw = _prefs.get('brightness');
        if (raw is int) {
          _brightness = raw.clamp(0, 10);
        } else if (raw is double) {
          _brightness = (raw * 10).round().clamp(0, 10);
        } else {
          _brightness = 2;
        }
      } else {
        _brightness = 2;
      }
      _useBodyInfo = _prefs.getBool('useBodyInfo') ?? false;
      // Read new discrete MBTI fields, with migration from legacy combined key 'mbti' if present
      _mbtiEI = _prefs.getString('mbtiEI') ?? "";
      _mbtiNS = _prefs.getString('mbtiNS') ?? "";
      _mbtiTF = _prefs.getString('mbtiTF') ?? "";
      _mbtiPJ = _prefs.getString('mbtiPJ') ?? "";
      if (_mbtiEI.isEmpty && _mbtiNS.isEmpty && _mbtiTF.isEmpty && _mbtiPJ.isEmpty) {
        final legacy = _prefs.getString('mbti') ?? "";
        if (legacy.isNotEmpty) {
          _applyCombinedMbti(legacy, persist: true);
        }
      }
    });
  }

  void _updateTemperature(double newTemp) {
    setState(() {
      _temperature = newTemp.clamp(18.0, 28.0);
      _prefs.setDouble('temperature', _temperature);
    });
  }

  void _updateHumidity(int level) {
    setState(() {
      _humidity = level;
      _prefs.setInt('humidity', _humidity);
    });
  }

  void _updateBrightness(int newLevel) {
    setState(() {
      _brightness = newLevel.clamp(0, 10);
      _prefs.setInt('brightness', _brightness);
    });
  }
  
  void _updateUseBodyInfo(bool useBodyInfo) {
    setState(() {
      _useBodyInfo = useBodyInfo;
      _prefs.setBool('useBodyInfo', _useBodyInfo);
    });
  }

  void _updateMbti(String combined) {
    setState(() {
      _applyCombinedMbti(combined, persist: true);
    });
  }

  void _applyCombinedMbti(String combined, {bool persist = false}) {
    // Parse combined string into the four discrete fields
    _mbtiEI = combined.contains('E')
        ? 'E'
        : (combined.contains('I') ? 'I' : '');
    _mbtiNS = combined.contains('N')
        ? 'N'
        : (combined.contains('S') ? 'S' : '');
    _mbtiTF = combined.contains('T')
        ? 'T'
        : (combined.contains('F') ? 'F' : '');
    _mbtiPJ = combined.contains('P')
        ? 'P'
        : (combined.contains('J') ? 'J' : '');
    if (persist) {
      _prefs.setString('mbtiEI', _mbtiEI);
      _prefs.setString('mbtiNS', _mbtiNS);
      _prefs.setString('mbtiTF', _mbtiTF);
      _prefs.setString('mbtiPJ', _mbtiPJ);
      // Optionally keep legacy combined for backward compatibility
      _prefs.setString('mbti', _mbtiCombined);
    }
  }

  void _sendDataToServer() {
    final userSettings = UserSettings(
      temperature: _temperature,
      humidity: _humidity,
      brightness: _brightness,
      mbtiEI: _mbtiEI,
      mbtiNS: _mbtiNS,
      mbtiTF: _mbtiTF,
      mbtiPJ: _mbtiPJ,
      useBodyInfo: _useBodyInfo,
    );
    // Compose payload with metadata
    final payload = {
      ...userSettings.toJson(),
      'userId': widget.userId,
      'updatedAt': ServerValue.timestamp, // Server-side timestamp
    };
    final db = FirebaseDbConfig.databaseUrl.isNotEmpty
    ? FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: FirebaseDbConfig.databaseUrl)
        : FirebaseDatabase.instance;
    db
        .ref('users/${widget.userId}')
        .update(payload) // create if missing, merge if exists
      .then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터가 성공적으로 전송되었습니다.'))
        );
      })
      .catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 전송 실패: $error'))
        );
      });

    // Also write to Firestore (create or merge document)
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .set(payload, SetOptions(merge: true))
        .catchError((error) {
      // Log Firestore error without interrupting UX (Realtime DB already handled success/failure toast)
      // In a future iteration, we could surface combined status.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              AppNameHeader(
                userId: widget.userId,
                onHeartClick: () => setState(() => _showInfoPopup = true),
                onPlusClick: () => setState(() => _showMbtiOverlay = true),
                onUserIdClick: () => setState(() => _showDeleteConfirmation = true),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: TemperatureControl(
                        temperature: _temperature,
                        onTemperatureChange: _updateTemperature,
                      ),
                    ),
                    Expanded(
                      child: HumidityControl(
                        selectedLevel: _humidity,
                        onLevelSelected: _updateHumidity,
                      ),
                    ),
                    Expanded(
                      child: BrightnessControl(
                        brightnessLevel: _brightness,
                        onBrightnessLevelChange: _updateBrightness,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _sendDataToServer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E86AB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("설정값 전송하기", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          if (_showInfoPopup)
            InfoDialog(
              useBodyInfo: _useBodyInfo,
              onUseBodyInfoChange: (value) {
                _updateUseBodyInfo(value);
              },
              onDismiss: () => setState(() => _showInfoPopup = false),
            ),
          if (_showDeleteConfirmation)
            DeleteConfirmationDialog(
              onConfirm: () {
                widget.onProfileDeleted();
                setState(() => _showDeleteConfirmation = false);
              },
              onDismiss: () => setState(() => _showDeleteConfirmation = false),
            ),
          if (_showMbtiOverlay) ...[
            GestureDetector(
              onTap: () => setState(() => _showMbtiOverlay = false),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: MbtiInputPanel(
                mbti: _mbtiCombined,
                onMbtiChange: _updateMbti,
                onClose: () => setState(() => _showMbtiOverlay = false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
