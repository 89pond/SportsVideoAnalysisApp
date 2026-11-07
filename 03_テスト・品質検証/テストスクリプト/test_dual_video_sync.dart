// Agent 3: デュアル動画同期アルゴリズム単体テスト
import 'dart:math';

/// デュアル動画同期シミュレーションモデル
class DualSyncModel {
  int posA = 0; // ms
  int posB = 0; // ms
  int durA = 10000; // 10秒
  int durB = 12000; // 12秒
  bool isSyncLocked = true;
  int baseOffset = 0; // posB - posA
  double manualOffsetSec = 0.0;

  void toggleLock() {
    isSyncLocked = !isSyncLocked;
    if (isSyncLocked) {
      baseOffset = posB - posA;
    }
  }

  void seekA(int newPosA) {
    posA = newPosA.clamp(0, durA);
    if (isSyncLocked) {
      final manualMs = (manualOffsetSec * 1000).round();
      posB = (posA + baseOffset + manualMs).clamp(0, durB);
    }
  }

  void seekB(int newPosB) {
    if (!isSyncLocked) {
      posB = newPosB.clamp(0, durB);
    }
  }

  void stepFrame(int deltaMs) {
    seekA(posA + deltaMs);
  }

  void setManualOffset(double sec) {
    manualOffsetSec = sec;
    if (isSyncLocked) {
      final manualMs = (manualOffsetSec * 1000).round();
      posB = (posA + baseOffset + manualMs).clamp(0, durB);
    }
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
  print('Dual Video Sync Algorithm 単体テスト');
  print('======================================================');

  final model = DualSyncModel();

  // テスト1: 個別頭出し (アンロック) でそれぞれの動作基準点をセット
  print('\n-- [1/4] 個別アンロック頭出しテスト --');
  model.toggleLock(); // アンロック
  assertEqual('アンロック確認', model.isSyncLocked, false);

  model.posA = 1500; // 動画A 接地瞬間 1500ms
  model.seekB(2100); // 動画B 接地瞬間 2100ms
  assertEqual('動画A 位置', model.posA, 1500);
  assertEqual('動画B 位置', model.posB, 2100);

  // テスト2: 同期ロックでオフセット確定
  print('\n-- [2/4] 同期ロックおよびオフセット固定テスト --');
  model.toggleLock(); // ロック
  assertEqual('同期ロック確認', model.isSyncLocked, true);
  assertEqual('基準オフセット (2100 - 1500 = +600ms)', model.baseOffset, 600);

  // テスト3: 同期再生・シーク追従
  print('\n-- [3/4] 同期シーク・コマ送り追従テスト --');
  model.seekA(2000);
  assertEqual('動画A シーク位置 (2000ms)', model.posA, 2000);
  assertEqual('動画B 同期追従位置 (2000 + 600 = 2600ms)', model.posB, 2600);

  // 1コマ (33ms) 送り
  model.stepFrame(33);
  assertEqual('動画A 1コマ送り (2033ms)', model.posA, 2033);
  assertEqual('動画B 1コマ追従 (2633ms)', model.posB, 2633);

  // テスト4: 手動オフセット微調整 (±0.05s)
  print('\n-- [4/4] 手動オフセット微調整テスト --');
  model.setManualOffset(-0.05); // -50ms
  assertEqual('動画B -50ms微調整位置 (2633 - 50 = 2583ms)', model.posB, 2583);

  model.setManualOffset(0.10); // +100ms
  assertEqual('動画B +100ms微調整位置 (2633 + 100 = 2733ms)', model.posB, 2733);

  print('------------------------------------------------------');
  print('テスト結果: $passed 成功 / $failed 失敗');
  print('======================================================');

  if (failed > 0) {
    throw Exception('テスト失敗');
  }
}
