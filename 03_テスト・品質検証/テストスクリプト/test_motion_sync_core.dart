// Agent 3: コア同期ロジック・角度計算単体テストスクリプト
import 'dart:math';

// テスト用 Offset クラス (Flutter UI非依存の軽量ダミー)
class Offset {
  final double dx;
  final double dy;
  const Offset(this.dx, this.dy);
}

// 角度計算ロジック
class GoniometerCalculator {
  static double calculateAngle(Offset pointA, Offset vertexB, Offset pointC) {
    final v1x = pointA.dx - vertexB.dx;
    final v1y = pointA.dy - vertexB.dy;
    final v2x = pointC.dx - vertexB.dx;
    final v2y = pointC.dy - vertexB.dy;

    final dotProduct = v1x * v2x + v1y * v2y;
    final len1 = sqrt(v1x * v1x + v1y * v1y);
    final len2 = sqrt(v2x * v2x + v2y * v2y);

    if (len1 == 0 || len2 == 0) return 0.0;
    final cosTheta = (dotProduct / (len1 * len2)).clamp(-1.0, 1.0);
    final radians = acos(cosTheta);
    final degrees = radians * (180.0 / pi);
    return double.parse(degrees.toStringAsFixed(1));
  }
}

// レコードダミー
class DummySensorRecord {
  final int elapsedMilliseconds;
  final double totalG;
  DummySensorRecord(this.elapsedMilliseconds, this.totalG);
}

// 二分探索ロジック
class BinarySearchSync {
  static DummySensorRecord? findNearest(List<DummySensorRecord> records, int targetMs) {
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

    if (low >= records.length) return records[high];
    if (high < 0) return records[low];

    final diffLow = (records[low].elapsedMilliseconds - targetMs).abs();
    final diffHigh = (records[high].elapsedMilliseconds - targetMs).abs();
    return (diffLow < diffHigh) ? records[low] : records[high];
  }
}

void main() {
  int passed = 0;
  int failed = 0;

  void assertEqual(String testName, dynamic actual, dynamic expected) {
    if (actual == expected) {
      print(' [PASS] $testName: actual=$actual');
      passed++;
    } else {
      print(' [FAIL] $testName: actual=$actual, expected=$expected');
      failed++;
    }
  }

  print('======================================================');
  print('MotionSync Analytics コアロジック単体テスト');
  print('======================================================');

  // 1. 角度計算 (Goniometer) テスト
  print('\n-- [1/2] ゴニオメーター角度計算テスト --');
  // 直角 90度
  final angleRight = GoniometerCalculator.calculateAngle(
    const Offset(0, 100),
    const Offset(0, 0),
    const Offset(100, 0),
  );
  assertEqual('直角 (90°)', angleRight, 90.0);

  // 一直線 180度
  final angleStraight = GoniometerCalculator.calculateAngle(
    const Offset(-100, 0),
    const Offset(0, 0),
    const Offset(100, 0),
  );
  assertEqual('一直線 (180°)', angleStraight, 180.0);

  // 45度
  final angle45 = GoniometerCalculator.calculateAngle(
    const Offset(100, 100),
    const Offset(0, 0),
    const Offset(100, 0),
  );
  assertEqual('45度傾斜 (45°)', angle45, 45.0);

  // 2. 二分探索 (Binary Search) 同期テスト
  print('\n-- [2/2] 時系列二分探索同期テスト --');
  final records = List.generate(10, (i) => DummySensorRecord(i * 100, i * 0.5)); // 0, 100, 200, ..., 900 ms

  // 完全一致
  final rExact = BinarySearchSync.findNearest(records, 300);
  assertEqual('完全一致 (300ms)', rExact?.elapsedMilliseconds, 300);

  // 中間点 (320ms -> 300ms に近い)
  final rNear1 = BinarySearchSync.findNearest(records, 320);
  assertEqual('近傍探索 (320ms -> 300ms)', rNear1?.elapsedMilliseconds, 300);

  // 中間点 (380ms -> 400ms に近い)
  final rNear2 = BinarySearchSync.findNearest(records, 380);
  assertEqual('近傍探索 (380ms -> 400ms)', rNear2?.elapsedMilliseconds, 400);

  // 境界値 (0ms未満)
  final rUnder = BinarySearchSync.findNearest(records, -50);
  assertEqual('境界値 (先頭以前 -> 0ms)', rUnder?.elapsedMilliseconds, 0);

  // 境界値 (900ms超過)
  final rOver = BinarySearchSync.findNearest(records, 1500);
  assertEqual('境界値 (末尾超過 -> 900ms)', rOver?.elapsedMilliseconds, 900);

  print('------------------------------------------------------');
  print('テスト結果: $passed 成功 / $failed 失敗');
  print('======================================================');

  if (failed > 0) {
    throw Exception('テストが失敗しました');
  }
}
