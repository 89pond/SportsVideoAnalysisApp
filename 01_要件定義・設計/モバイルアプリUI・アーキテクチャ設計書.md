# モバイルアプリ UI・アーキテクチャ設計書 - MotionSync Analytics

## 目次
- [1. 概要とシステム構成](#1-概要とシステム構成)
- [2. UIレイアウトおよび表示モード設計](#2-uiレイアウトおよび表示モード設計)
  - [2.1 1画面モード (Single View)](#21-1画面モード-single-view)
  - [2.2 2画面並列モード (Dual Split View)](#22-2画面並列モード-dual-split-view)
  - [2.3 透過ゴーストモード (Ghost Overlay View)](#23-透過ゴーストモード-ghost-overlay-view)
- [3. 画面構成およびウィジェットツリー設計](#3-画面構成およびウィジェットツリー設計)
  - [3.1 メイン画面構成図](#31-メイン画面構成図)
  - [3.2 主要コンポーネント詳細](#32-主要コンポーネント詳細)
- [4. 状態管理アーキテクチャ (Riverpod)](#4-状態管理アーキテクチャ-riverpod)
  - [4.1 状態管理データモデル一覧](#41-状態管理データモデル一覧)
  - [4.2 状態遷移フロー](#42-状態遷移フロー)
- [5. ディレクトリおよびファイル構造設計](#5-ディレクトリおよびファイル構造設計)

---

## 1. 概要とシステム構成
本設計書は、Flutter（iOS / Android クロスプラットフォーム）で構築する「スポーツ動作・センサーデータ統合分析モバイルアプリ（MotionSync Analytics）」のフロントエンド画面UI、ウィジェット階層、および状態管理アーキテクチャを定義するものです。

- **UI描画エンジン**: Flutter SDK (Impeller / Skia) - 60fps〜120fpsの低遅延レンダリング
- **状態管理フレームワーク**: `flutter_riverpod` (v2.x) によるリアクティブ状態管理
- **UIテーマ**: スポーツ科学・分析用ダークモードテーマ（高コントラスト、屋外視認性重視）

---

## 2. UIレイアウトおよび表示モード設計

要件定義書に準拠し、上部動画表示エリアは以下の3つのモードをシームレスに切り替え可能とします。

### 2.1 1画面モード (Single View)
- メイン動画（自選手または分析対象）を画面上部に全幅表示。
- 直下にHUD（通過ラップタイム、合成G値）および加速度波形グラフを大きく配置し、単一動作の精密フォーム確認に集中できるレイアウト。

### 2.2 2画面並列モード (Dual Split View)
- **横持ち（Landscape時）**: 画面を左右に50:50で2分割し、動画A（自選手）と動画B（お手本・過去の自分）を並列表示。
- **縦持ち（Portrait時）**: 画面を上下に2分割して表示。
- 個別アンロック時はそれぞれの動画を独立シーク可能、同期ロック時は両画面が完全同期してコマ送り・スロー再生。

### 2.3 透過ゴーストモード (Ghost Overlay View)
- 動画Aの上に動画Bを重ね合わせ表示。
- **不透明度スライダー（0%〜100%）**: スライダー操作により、動画Bの透過率をリアルタイムに調整。フォームのわずかな重なり具合（足の接地角度、上半身の傾き等）の差異を直接可視化。

---

## 3. 画面構成およびウィジェットツリー設計

### 3.1 メイン画面構成図

```text
┌────────────────────────────────────────────────────────┐
│ [戻る]      プロジェクト名 / ファイル名      [エクスポート] │  <- HeaderBar
├──────────────────────────┬─────────────────────────────┤
│        動画 A            │          動画 B             │  <- VideoViewportArea
│   (メイン / 自選手)      │    (比較対象 / お手本)      │     (1画面/2画面/透過ゴースト切替)
│                          │                             │     + AnnotationCanvas
│   [ 角度: 112.4° ]       │    [ 角度: 125.0° ]         │       (描画・角度オーバーレイ)
├──────────────────────────┴─────────────────────────────┤
│ [再生/停止] [コマ戻し] [コマ送り] [速度: 0.25x] [同期ロック/解除] │  <- PlaybackControlBar
├────────────────────────────────────────────────────────┤
│ [HUD] LAP 3: 9.42s (Diff: -0.12s)   合成G: 1.84 G      │  <- HudOverlayBar
├────────────────────────────────────────────────────────┤
│ 加速度波形 (X / Y / Z / 合成)                          │  <- SensorWaveformArea
│ ────/\─────/\───────│────────/\─────────/\──────────── │     (再生ヘッド縦ライン追従)
├────────────────────────────────────────────────────────┤
│ 同期オフセット微調整: [ -0.05s ]  [ < ] [ > ]  [ +0.05s ]│  <- SyncOffsetControlBar
│ 描画ツール: [選択] [ペン] [直線] [矢印] [円] [角度] [消去] │  <- DrawingToolbar
└────────────────────────────────────────────────────────┘
```

### 3.2 主要コンポーネント詳細

1. **HeaderBar**:
   - プロジェクト名および読み込み済みファイル名（動画A/動画B/CSV）を表示。
   - 表示モード切り替えスイッチ（`1画面` / `2画面並列` / `透過ゴースト`）。
   - 静止画PNG保存・MP4動画エクスポートボタン。
2. **VideoViewportArea**:
   - モードに応じた動画コンテナ（`InteractiveViewer` を内包し、ピンチズーム・パン対応）。
   - その最前面に `CustomPaint`（`AnnotationPainter`）を配置し、描画線やゴニオメーター（角度）をリアルタイム重畳。
3. **PlaybackControlBar**:
   - 再生／一時停止、1フレーム単位のコマ送り／コマ戻しボタン。
   - 再生速度セレクター（`0.1x`, `0.25x`, `0.5x`, `1.0x`）。
   - 同期ロック（連動再生）／個別アンロック（頭出し用独立操作）切り替えトグル。
4. **HudOverlayBar**:
   - ストップウォッチCSVから抽出された現在フレームの通過ラップ情報（周回番号、区間ラップ、スプリット、差分Diff）。
   - 加速度センサーから算出された現在の合成加速度（$G = \sqrt{X^2+Y^2+Z^2}$）のゲージ表示。
5. **SensorWaveformArea**:
   - 3軸加速度（$X, Y, Z$）および合成Gの時系列波形グラフ。
   - 現在の動画再生ミリ秒に対応する位置に再生ヘッド（縦ライン）が60fpsで追従。
6. **SyncOffsetControlBar & DrawingToolbar**:
   - $\pm 0.01$ 秒および $\pm 0.05$ 秒単位のタイムスタンプ手動オフセット微調整ボタン。
   - 描画ツールパレット（フリーハンド、直線、矢印、円、3点タップ角度計測、全消去、色選択）。

---

## 4. 状態管理アーキテクチャ (Riverpod)

### 4.1 状態管理データモデル一覧

```dart
// 1. 表示レイアウトモード
enum ViewMode { single, splitHorizontal, splitVertical, ghostOverlay }

// 2. 再生制御状態
class PlaybackState {
  final bool isPlaying;
  final double playbackSpeed;     // 0.1, 0.25, 0.5, 1.0
  final Duration currentPositionA;
  final Duration currentPositionB;
  final bool isSyncLocked;        // 同期ロック中か個別操作中か
}

// 3. 同期オフセット状態
class SyncOffsetState {
  final double offsetSeconds;     // 動画Aと動画B、または動画とセンサーの差分秒数
}

// 4. ゴースト表示状態
class GhostOverlayState {
  final double opacityB;          // 0.0 〜 1.0 (動画Bの不透明度)
}

// 5. 描画・アノテーション状態
enum DrawingToolType { select, freehand, line, arrow, circle, angleGoniometer }

class DrawingState {
  final DrawingToolType currentTool;
  final Color selectedColor;
  final double strokeWidth;
  final List<DrawingObject> objects;
  final List<Offset> currentPoints; // 角度計測時のタップ点 (点A, 点B, 点C)
}

// 6. センサー・ストップウォッチデータ状態
class AnalysisDataState {
  final List<SensorRecord> sensorRecords;
  final List<LapRecord> lapRecords;
  final SensorRecord? currentSensorRecord;
  final LapRecord? currentLapRecord;
}
```

### 4.2 状態遷移フロー
- ユーザーがシークバーまたはコマ送り操作 ➔ `PlaybackState.currentPosition` 更新 ➔ 二分探索プロバイダが即座に最新の `SensorRecord` および `LapRecord` をインデックス参照 ➔ `HudOverlayBar` と `SensorWaveformArea` の再生ヘッドが再描画。

---

## 5. ディレクトリおよびファイル構造設計

Flutterプロジェクト（`02_実装・コーディング/モバイルアプリ/`）の構造：

```text
02_実装・コーディング/モバイルアプリ/
├── pubspec.yaml
├── lib/
│   ├── main.dart                          # アプリ起動・テーマ定義
│   ├── models/                            # データモデル
│   │   ├── sensor_record.dart             # 加速度・IMUデータ型
│   │   ├── lap_record.dart                # ストップウォッチラップ型
│   │   └── drawing_object.dart            # アノテーション・角度計測型
│   ├── providers/                         # Riverpod状態管理
│   │   ├── playback_provider.dart         # 再生・同期制御
│   │   ├── view_mode_provider.dart        # 1画面/2画面/透過モード
│   │   ├── drawing_provider.dart          # 描画・ゴニオメーター状態
│   │   └── sensor_data_provider.dart      # CSVパース・二分探索同期
│   ├── ui/
│   │   ├── main_analysis_screen.dart      # 統合分析メイン画面
│   │   ├── components/
│   │   │   ├── header_bar.dart            # 上部ヘッダー
│   │   │   ├── video_viewport_area.dart   # 1画面/2画面/透過ビュー
│   │   │   ├── annotation_canvas.dart     # CustomPainter描画キャンバス
│   │   │   ├── playback_control_bar.dart  # コマ送り・速度コントロール
│   │   │   ├── hud_overlay_bar.dart       # LAP・Diff・合成Gゲージ
│   │   │   ├── sensor_waveform_area.dart  # 加速度波形グラフ
│   │   │   └── bottom_toolbar.dart        # オフセット調整・描画パレット
│   │   └── theme/
│   │       └── app_theme.dart             # 分析用ダークテーマ
│   └── utils/
│       ├── binary_search_sync.dart        # ミリ秒二分探索ロジック
│       └── goniometer_calculator.dart     # 3点関節角度幾何計算
└── test/
    ├── goniometer_test.dart               # 角度計算ロジック単体テスト
    ├── binary_search_test.dart            # 二分探索同期テスト
    └── widget_test.dart                   # UIコンポーネントテスト
```
