/// 1ラップ分のストップウォッチ計測データ (StopWatch LinkLog 22カラム互換)
class LapRecord {
  final String sessionId;
  final String playerName;
  final String tournamentName;
  final String eventType;
  final int lapNo;
  final double? lapSeconds;        // 区間秒数 (押し忘れ欠損時はnull)
  final String? lapTimeStr;       // 0:00:37.20
  final double splitSeconds;      // スプリット累計秒数
  final String splitTimeStr;      // 0:01:14.40
  final double lapDistanceM;      // 周回距離 (m)
  final double cumulativeDistanceM;
  final double? speedKmh;         // 区間時速 (km/h)
  final bool isFastest;           // 最速ラップフラグ
  final bool isMissing;           // 押し忘れ欠損フラグ

  LapRecord({
    required this.sessionId,
    required this.playerName,
    required this.tournamentName,
    required this.eventType,
    required this.lapNo,
    this.lapSeconds,
    this.lapTimeStr,
    required this.splitSeconds,
    required this.splitTimeStr,
    required this.lapDistanceM,
    required this.cumulativeDistanceM,
    this.speedKmh,
    this.isFastest = false,
    this.isMissing = false,
  });

  /// スプリット経過ミリ秒 (動画同期用)
  int get splitMilliseconds => (splitSeconds * 1000).round();
}
