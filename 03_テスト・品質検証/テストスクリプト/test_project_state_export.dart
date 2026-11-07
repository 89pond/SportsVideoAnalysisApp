// Agent 3: プロジェクト状態 (JSON) 保存・復元 単体テスト
import 'dart:convert';

// テスト用 Offset クラス
class Offset {
  final double dx;
  final double dy;
  const Offset(this.dx, this.dy);
}

// テスト用モデル
class DrawingObject {
  final String type;
  final int colorValue;
  final double strokeWidth;
  final double? calculatedAngle;
  final List<Offset> points;

  DrawingObject({
    required this.type,
    required this.colorValue,
    required this.strokeWidth,
    this.calculatedAngle,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'color': colorValue,
        'strokeWidth': strokeWidth,
        'calculatedAngle': calculatedAngle,
        'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      };

  factory DrawingObject.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    return DrawingObject(
      type: json['type'] as String,
      colorValue: json['color'] as int,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      calculatedAngle: (json['calculatedAngle'] as num?)?.toDouble(),
      points: rawPoints.map((p) {
        final m = p as Map<String, dynamic>;
        return Offset((m['dx'] as num).toDouble(), (m['dy'] as num).toDouble());
      }).toList(),
    );
  }
}

class AnalysisProjectState {
  final String projectId;
  final String viewMode;
  final double syncOffsetSeconds;
  final double ghostOpacity;
  final List<String> selectedWaveforms;
  final List<DrawingObject> annotations;

  AnalysisProjectState({
    required this.projectId,
    required this.viewMode,
    required this.syncOffsetSeconds,
    required this.ghostOpacity,
    required this.selectedWaveforms,
    required this.annotations,
  });

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'viewMode': viewMode,
        'syncOffsetSeconds': syncOffsetSeconds,
        'ghostOpacity': ghostOpacity,
        'selectedWaveforms': selectedWaveforms,
        'annotations': annotations.map((a) => a.toJson()).toList(),
      };

  factory AnalysisProjectState.fromJson(Map<String, dynamic> json) {
    final rawAnnotations = json['annotations'] as List<dynamic>? ?? [];
    return AnalysisProjectState(
      projectId: json['projectId'] as String,
      viewMode: json['viewMode'] as String,
      syncOffsetSeconds: (json['syncOffsetSeconds'] as num).toDouble(),
      ghostOpacity: (json['ghostOpacity'] as num).toDouble(),
      selectedWaveforms: (json['selectedWaveforms'] as List<dynamic>).map((e) => e.toString()).toList(),
      annotations: rawAnnotations.map((e) => DrawingObject.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());
  static AnalysisProjectState fromJsonString(String str) =>
      AnalysisProjectState.fromJson(jsonDecode(str) as Map<String, dynamic>);
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
  print('Project State JSON Export / Restore 単体テスト');
  print('======================================================');

  // 1. プロジェクト状態オブジェクトの作成
  final original = AnalysisProjectState(
    projectId: 'PROJ_20261108_TEST',
    viewMode: 'ghostOverlay',
    syncOffsetSeconds: 0.85,
    ghostOpacity: 0.65,
    selectedWaveforms: ['accelTotal', 'gyroTotal', 'angleTotal'],
    annotations: [
      DrawingObject(
        type: 'angleGoniometer',
        colorValue: 0xFFFFD600,
        strokeWidth: 3.5,
        calculatedAngle: 112.4,
        points: [const Offset(100.0, 150.0), const Offset(120.0, 220.0), const Offset(150.0, 300.0)],
      ),
      DrawingObject(
        type: 'arrow',
        colorValue: 0xFFFF5252,
        strokeWidth: 2.5,
        points: [const Offset(50.0, 50.0), const Offset(80.0, 80.0)],
      ),
    ],
  );

  // 2. JSONシリアライズ
  final jsonString = original.toJsonString();
  print('\n-- 生成されたJSON文字列 (プレビュー) --');
  print(jsonString);

  // 3. JSONデシリアライズ (復元)
  print('\n-- 復元データアサーション検証 --');
  final restored = AnalysisProjectState.fromJsonString(jsonString);

  assertEqual('プロジェクトID復元', restored.projectId, 'PROJ_20261108_TEST');
  assertEqual('表示モード復元', restored.viewMode, 'ghostOverlay');
  assertEqual('同期オフセット秒数復元', restored.syncOffsetSeconds, 0.85);
  assertEqual('ゴースト透過度復元', restored.ghostOpacity, 0.65);
  assertEqual('選択波形数復元', restored.selectedWaveforms.length, 3);
  assertEqual('第1選択波形', restored.selectedWaveforms[0], 'accelTotal');

  // アノテーション復元検証
  assertEqual('アノテーション件数復元', restored.annotations.length, 2);
  final obj1 = restored.annotations[0];
  assertEqual('アノテーション1 種別', obj1.type, 'angleGoniometer');
  assertEqual('アノテーション1 計算角度', obj1.calculatedAngle, 112.4);
  assertEqual('アノテーション1 頂点B dx', obj1.points[1].dx, 120.0);
  assertEqual('アノテーション1 頂点B dy', obj1.points[1].dy, 220.0);

  final obj2 = restored.annotations[1];
  assertEqual('アノテーション2 種別', obj2.type, 'arrow');
  assertEqual('アノテーション2 始点 dx', obj2.points[0].dx, 50.0);

  print('------------------------------------------------------');
  print('テスト結果: $passed 成功 / $failed 失敗');
  print('======================================================');

  if (failed > 0) {
    throw Exception('テスト失敗');
  }
}
