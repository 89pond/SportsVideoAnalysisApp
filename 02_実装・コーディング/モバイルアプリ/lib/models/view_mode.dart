/// 表示レイアウトモード
enum ViewMode {
  single,           // 1画面モード (メイン動画 + グラフ + HUD)
  splitHorizontal,  // 2画面並列モード (横分割: 左右)
  splitVertical,    // 2画面並列モード (縦分割: 上下)
  ghostOverlay,     // 透過ゴースト (オーバーレイ重ね合わせ)
}

extension ViewModeExtension on ViewMode {
  String get label {
    switch (this) {
      case ViewMode.single:
        return '1画面';
      case ViewMode.splitHorizontal:
        return '2画面 (左右)';
      case ViewMode.splitVertical:
        return '2画面 (上下)';
      case ViewMode.ghostOverlay:
        return '透過ゴースト';
    }
  }
}

/// 描画アノテーションツール種別
enum DrawingToolType {
  none,             // 描画なし (動画タップ・ズーム優先)
  freehand,         // フリーハンドペン
  line,             // 直線
  arrow,            // 矢印
  circle,           // 円 / 楕円
  angleGoniometer,  // ゴニオメーター (3点タップ関節角度)
  clear,            // 全消去
}

extension DrawingToolTypeExtension on DrawingToolType {
  String get label {
    switch (this) {
      case DrawingToolType.none:
        return '選択';
      case DrawingToolType.freehand:
        return 'ペン';
      case DrawingToolType.line:
        return '直線';
      case DrawingToolType.arrow:
        return '矢印';
      case DrawingToolType.circle:
        return '円';
      case DrawingToolType.angleGoniometer:
        return '角度';
      case DrawingToolType.clear:
        return 'クリア';
    }
  }
}
