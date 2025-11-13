class UserSettings {
  final double temperature;
  final int humidity;
  // Brightness now represented as discrete level 0-10 instead of 0.0-1.0 double.
  final int brightness; // 0..10
  // MBTI is stored as four independent one-letter options. Each can be "", or one of its pair (E/I, N/S, T/F, P/J).
  final String mbtiEI; // "E" | "I" | ""
  final String mbtiNS; // "N" | "S" | ""
  final String mbtiTF; // "T" | "F" | ""
  final String mbtiPJ; // "P" | "J" | ""
  final bool useBodyInfo;

  const UserSettings({
    required this.temperature,
    required this.humidity,
  required this.brightness,
    required this.mbtiEI,
    required this.mbtiNS,
    required this.mbtiTF,
    required this.mbtiPJ,
    required this.useBodyInfo,
  });

  /// Combined MBTI string for UI compatibility (order follows E/I, N/S, T/F, P/J)
  String get mbtiCombined => [mbtiEI, mbtiNS, mbtiTF, mbtiPJ].where((e) => e.isNotEmpty).join();

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
  'brightness': brightness,
      // Store discrete fields
      'mbtiEI': mbtiEI,
      'mbtiNS': mbtiNS,
      'mbtiTF': mbtiTF,
      'mbtiPJ': mbtiPJ,
      // Keep a combined "mbti" for backward/analytics convenience
      'mbti': mbtiCombined,
      'useBodyInfo': useBodyInfo,
    };
  }
}
