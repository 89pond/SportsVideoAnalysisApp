import '../models/sensor_record.dart';
import '../models/lap_record.dart';

/// 時系列同期用 二分探索 (Binary Search) ユーティリティ
class BinarySearchSync {
  /// 指定した経過ミリ秒 (targetMs) に最も時間的に近い SensorRecord を二分探索で高速検索
  static SensorRecord? findNearestSensorRecord(
    List<SensorRecord> records,
    int targetMs,
  ) {
    if (records.isEmpty) return null;
    if (targetMs <= records.first.elapsedMilliseconds) return records.first;
    if (targetMs >= records.last.elapsedMilliseconds) return records.last;

    int low = 0;
    int high = records.length - 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final midMs = records[mid].elapsedMilliseconds;

      if (midMs == targetMs) {
        return records[mid];
      } else if (midMs < targetMs) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    // low と high のうち、targetMs に差分がより小さい方を返却
    if (low >= records.length) return records[high];
    if (high < 0) return records[low];

    final diffLow = (records[low].elapsedMilliseconds - targetMs).abs();
    final diffHigh = (records[high].elapsedMilliseconds - targetMs).abs();
    return (diffLow < diffHigh) ? records[low] : records[high];
  }

  /// 現在の再生位置 (targetMs) における最新の通過 LapRecord を二分探索で検索
  static LapRecord? findCurrentLapRecord(
    List<LapRecord> laps,
    int targetMs,
  ) {
    if (laps.isEmpty) return null;
    LapRecord? currentLap;

    for (final lap in laps) {
      if (lap.splitMilliseconds <= targetMs) {
        currentLap = lap;
      } else {
        break;
      }
    }
    return currentLap ?? laps.first;
  }
}
