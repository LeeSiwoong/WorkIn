import 'dart:math';

class BodyMetrics {
  final int heartRateVariation; // 5분간 심박수 변화 폭
  final int stressAvg; // 5분간 외부에서 수집한 스트레스 지수
  final DateTime collectedAt;

  BodyMetrics({
    required this.heartRateVariation,
    required this.stressAvg,
    required this.collectedAt,
  });

  Map<String, dynamic> toJson() => {
        'heartRateVariation': heartRateVariation,
        'stressAvg': stressAvg,
        'collectedAt': collectedAt.toIso8601String(),
      };
}

class BodyMetricsService {
  static final _rng = Random();

  // Simulate fetching 5-minute aggregated metrics with brief delay.
  static Future<BodyMetrics> fetchRecentMetrics({int? externalStress}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final variation = 5 + _rng.nextInt(21); // 5..25 bpm
    final stress = externalStress ?? (30 + _rng.nextInt(41)); // 외부 입력 없으면 임의값
    return BodyMetrics(
      heartRateVariation: variation,
      stressAvg: stress,
      collectedAt: DateTime.now(),
    );
  }
}
