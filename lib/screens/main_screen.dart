


import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:async';
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
import '../services/body_metrics_service.dart';
import '../services/bluetooth_id_broadcaster.dart';
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
  // updatedAt 타임스탬프 포함(일반 값 변경용)

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
    final payload = userSettings.toJson();
    payload['userId'] = widget.userId;
    // yyyyMMddHHmm 형식의 숫자 타임스탬프
    final now = DateTime.now();
    final formatted =
      '${now.year.toString().padLeft(4, '0')}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}'
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}'
    ;
    payload['updatedAt'] = formatted;
    if (_useBodyInfo && _bodyMetrics != null) {
      payload['bodyMetrics'] = _bodyMetrics!.toJson();
    }
    final db = FirebaseDbConfig.databaseUrl.isNotEmpty
        ? FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: FirebaseDbConfig.databaseUrl)
        : FirebaseDatabase.instance;
    db.ref('users/${widget.userId}').update(payload);
    FirebaseFirestore.instance.collection('users').doc(widget.userId).set(payload, SetOptions(merge: true));
  }

  Future<void> _enableBodyMetrics() async {
    setState(() {
      _fetchingBodyMetrics = true;
    });
    try {
      // 외부에서 수집한 스트레스 지수를 전달하려면 fetchRecentMetrics(externalStress: ...)로 호출
      var metrics = await BodyMetricsService.fetchRecentMetrics();
      if (!mounted) return;
      setState(() {
        _bodyMetrics = metrics;
      });
      final db = FirebaseDbConfig.databaseUrl.isNotEmpty
          ? FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: FirebaseDbConfig.databaseUrl)
          : FirebaseDatabase.instance;
      // 심박수 변화(heartRateVariation)와 스트레스 지수(stressAvg)는 완전히 별개로 저장
      await db.ref('users/${widget.userId}/bodyMetrics').set({
        'heartRateVariation': metrics.heartRateVariation,
        'stressAvg': metrics.stressAvg,
        'collectedAt': metrics.collectedAt.toIso8601String(),
      });
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
        'bodyMetrics': {
          'heartRateVariation': metrics.heartRateVariation,
          'stressAvg': metrics.stressAvg,
          'collectedAt': metrics.collectedAt.toIso8601String(),
        },
      }, SetOptions(merge: true));
    } finally {
      if (mounted) {
        setState(() {
          _fetchingBodyMetrics = false;
        });
      }
    }
  }

    // updatedAt 타임스탬프 없이(신체 정보 토글용)
    void _sendDataToServerNoTimestamp() {
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
        final payload = userSettings.toJson();
        payload['userId'] = widget.userId;
        if (_useBodyInfo && _bodyMetrics != null) {
          payload['bodyMetrics'] = _bodyMetrics!.toJson();
        }
      final db = FirebaseDbConfig.databaseUrl.isNotEmpty
        ? FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: FirebaseDbConfig.databaseUrl)
        : FirebaseDatabase.instance;
      db.ref('users/${widget.userId}').update(payload);
      FirebaseFirestore.instance.collection('users').doc(widget.userId).set(payload, SetOptions(merge: true));
    }
  DateTime? _lastSnackMinute;
  // 5분마다 신체 정보 업로드용 타이머
  Timer? _bodyMetricsTimer;
  BluetoothIdBroadcaster? _bluetoothBroadcaster;
  late SharedPreferences _prefs;
  double _temperature = 26.0;
  int _humidity = 3;
  int _brightness = 2; // 0..10 discrete
  bool _useBodyInfo = false;
  BodyMetrics? _bodyMetrics;
  bool _fetchingBodyMetrics = false;
  String _mbtiEI = ""; // E or I or ""
  String _mbtiNS = ""; // N or S or ""
  String _mbtiTF = ""; // T or F or ""
  String _mbtiPJ = ""; // P or J or ""

  String get _mbtiCombined {
    return [_mbtiEI, _mbtiNS, _mbtiTF, _mbtiPJ].where((e) => e.isNotEmpty).join();
  }

  void _applyCombinedMbti(String combined, {bool persist = false}) {
    // 각 자리별로 E/I, N/S, T/F, P/J 중 선택된 값을 찾아서 반영
    String ei = "";
    String ns = "";
    String tf = "";
    String pj = "";
    if (combined.contains('E')) ei = 'E';
    if (combined.contains('I')) ei = 'I';
    if (combined.contains('N')) ns = 'N';
    if (combined.contains('S')) ns = 'S';
    if (combined.contains('T')) tf = 'T';
    if (combined.contains('F')) tf = 'F';
    if (combined.contains('P')) pj = 'P';
    if (combined.contains('J')) pj = 'J';
    setState(() {
      _mbtiEI = ei;
      _mbtiNS = ns;
      _mbtiTF = tf;
      _mbtiPJ = pj;
    });
    if (persist) {
      _prefs.setString('mbtiEI', _mbtiEI);
      _prefs.setString('mbtiNS', _mbtiNS);
      _prefs.setString('mbtiTF', _mbtiTF);
      _prefs.setString('mbtiPJ', _mbtiPJ);
    }
  }

  bool _showInfoPopup = false;
  bool _showMbtiOverlay = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Start Bluetooth ID broadcast every 5 minutes
    _bluetoothBroadcaster = BluetoothIdBroadcaster(userId: widget.userId);
    _bluetoothBroadcaster!.start();
  }

  @override
  void dispose() {
    _bluetoothBroadcaster?.stop();
    _bodyMetricsTimer?.cancel();
    super.dispose();
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
    _sendDataToServer(); // updatedAt 포함 DB 반영
  }

  void _updateHumidity(int level) {
    setState(() {
      _humidity = level;
      _prefs.setInt('humidity', _humidity);
    });
    _sendDataToServer(); // updatedAt 포함 DB 반영
  }

  void _updateBrightness(int newLevel) {
    setState(() {
      _brightness = newLevel.clamp(0, 10);
      _prefs.setInt('brightness', _brightness);
    });
    _sendDataToServer(); // updatedAt 포함 DB 반영
  }
  
  void _updateUseBodyInfo(bool useBodyInfo) {
    setState(() {
      _useBodyInfo = useBodyInfo;
      _prefs.setBool('useBodyInfo', useBodyInfo);
    });
    if (useBodyInfo) {
      _enableBodyMetrics()
        .then((_) {
          // bodyMetrics가 세팅된 후에만 전송
          _sendDataToServerNoTimestamp();
          // 5분마다 신체 정보 업로드 타이머 시작
          _bodyMetricsTimer?.cancel();
          _bodyMetricsTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
            if (_useBodyInfo) {
              await _enableBodyMetrics();
              _sendDataToServerNoTimestamp();
              // 5분 단위마다 스낵바 출력
              final now = DateTime.now();
              if (now.minute % 5 == 0 && (_lastSnackMinute == null || _lastSnackMinute!.minute != now.minute)) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('설정이 반영되었습니다.')),
                  );
                  _lastSnackMinute = now;
                }
              }
            }
          });
        })
        .catchError((e) {
          // 실패 시 다시 false로 롤백
          if (mounted) {
            setState(() {
              _useBodyInfo = false;
              _prefs.setBool('useBodyInfo', false);
            });
          }
        });
    } else {
      // 타이머 해제
      _bodyMetricsTimer?.cancel();
      _bodyMetricsTimer = null;
      _disableBodyMetrics().then((_) => _sendDataToServerNoTimestamp());
    }
    // 신체 정보 토글이 변경될 때는 updatedAt을 갱신하지 않음(즉시 DB 반영만)
  }

  void _updateMbti(String combined) {
    setState(() {
      _applyCombinedMbti(combined, persist: true);
    });
    _sendDataToServer(); // updatedAt 포함 DB 반영
  }

  Future<void> _disableBodyMetrics() async {
    setState(() {
      _useBodyInfo = false;
      _prefs.setBool('useBodyInfo', false);
    });
    // bodyMetrics의 모든 값을 'NULL'로 업데이트
    final nullMetrics = {
      'heartRateVariation': null,
      'collectedAt': null,
    };
    try {
      await FirebaseDatabase.instance.ref('users/${widget.userId}/bodyMetrics').update(nullMetrics);
    } catch (_) {}
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId)
        .set({'bodyMetrics': nullMetrics}, SetOptions(merge: true));
    } catch (_) {}
    setState(() {
      _bodyMetrics = null;
    });
    // 알림 제거: 신체 정보 토글 조작 시 스낵바 미출력
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // ...더미 유저 생성 버튼 완전 제거
              AppNameHeader(
                userId: widget.userId,
                onHeartClick: () => setState(() => _showInfoPopup = true),
                onPlusClick: !_showMbtiOverlay
                  ? () => setState(() => _showMbtiOverlay = true)
                  : () {},
                onUserIdClick: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => DeleteConfirmationDialog(
                      onConfirm: () async {
                        Navigator.of(context).pop();
                        await Future.delayed(const Duration(milliseconds: 100));
                        bool deleted = false;
                        // 1. Realtime Database에서 users/{userId} 노드 전체 삭제
                        try {
                          // Realtime Database: users/{userId} 노드 삭제
                          await FirebaseDatabase.instance.ref('users/${widget.userId}').remove();
                          deleted = true;
                        } catch (e) {
                          // 무시, Firestore도 시도
                        }
                        try {
                          // Firestore: users 컬렉션의 해당 문서 삭제
                          await FirebaseFirestore.instance.collection('users').doc(widget.userId).delete();
                          deleted = true;
                        } catch (e) {
                          // 무시
                        }
                        // 3. 앱 상태 초기화
                        widget.onProfileDeleted();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(deleted ? '아이디 및 관련 데이터가 삭제되었습니다.' : '삭제에 실패했습니다.')),
                          );
                        }
                      },
                      onDismiss: () => Navigator.of(context).pop(),
                    ),
                  );
                },
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
              // 설정값 전송 버튼 제거
            ],
          ),
          if (_showInfoPopup)
            // 확인 버튼 없는 InfoDialog: 바깥 클릭만 닫기
            if (_showInfoPopup)
              GestureDetector(
                onTap: () => setState(() => _showInfoPopup = false),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: Center(
                    child: InfoDialog(
                      key: const ValueKey('InfoDialog'),
                      useBodyInfo: _useBodyInfo,
                      onUseBodyInfoChange: (value) {
                        _updateUseBodyInfo(value);
                      },
                      onDismiss: () => setState(() => _showInfoPopup = false),
                      hideConfirm: true,
                    ),
                  ),
                ),
              ),
          if (_showMbtiOverlay)
            Stack(
              children: [
                // Blurred, darkened background
                GestureDetector(
                  onTap: () => setState(() => _showMbtiOverlay = false),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
                // Slide-in sidebar
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  right: _showMbtiOverlay ? 0 : -320, // panel width
                  top: 0,
                  bottom: 0,
                  width: 320,
                  child: MbtiInputPanel(
                    mbti: _mbtiCombined,
                    onMbtiChange: _updateMbti,
                    onClose: () => setState(() => _showMbtiOverlay = false),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
