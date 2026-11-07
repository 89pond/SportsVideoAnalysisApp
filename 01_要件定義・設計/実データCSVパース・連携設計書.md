# 実データCSVパース・連携 詳細設計書

## 目次
- [1. 概要と目的](#1-概要と目的)
- [2. 対象CSVフォーマット仕様](#2-対象csvフォーマット仕様)
  - [2.1 StopWatch LinkLog CSV (全22カラム)](#21-stopwatch-linklog-csv-全22カラム)
  - [2.2 WITMOTION 加速度・IMU CSV (全31カラム)](#22-witmotion-加速度imu-csv-全31カラム)
- [3. パーサー設計および安全保護ロジック](#3-パーサー設計および安全保護ロジック)
  - [3.1 UTF-8 BOM (`\uFEFF`) および CRLF 改行の安全処理](#31-utf-8-bom-ufeff-および-crlf-改行の安全処理)
  - [3.2 RFC 4180準拠のカンマ・ダブルクォートエスケープ分離](#32-rfc-4180準拠のカンマダブルクォートエスケープ分離)
  - [3.3 Excel保護用タブ文字 (`\t`) のトリミング](#33-excel保護用タブ文字-t-のトリミング)
  - [3.4 欠損値 (NULL) およびゼロ除算防止ハンドリング](#34-欠損値-null-およびゼロ除算防止ハンドリング)
- [4. 時系列インデックス算出・同期マッピング](#4-時系列インデックス算出同期マッピング)
  - [4.1 センサー経過ミリ秒 (elapsedMilliseconds) の正規化](#41-センサー経過ミリ秒-elapsedmilliseconds-の正規化)
  - [4.2 動画タイムスタンプとセンサーデータの突合](#42-動画タイムスタンプとセンサーデータの突合)
- [5. UI連携および状態更新フロー](#5-ui連携および状態更新フロー)

---

## 1. 概要と目的
本設計書は、計測現場から出力されるストップウォッチデータ（`StopWatch LinkLog` 出力CSV）およびセンサーデータ（`WITMOTION` 9軸IMU出力CSV）を端末内で安全・高速にパースし、アプリのHUD表示や加速度波形グラフへリアルタイム反映させるデータ読み込みパイプラインの内部設計を定義するものです。

---

## 2. 対象CSVフォーマット仕様

### 2.1 StopWatch LinkLog CSV (全22カラム)
- **形式**: Tidy Data形式（1行＝1ラップの観測値）
- **主要カラム**:
  1. `session_id`, 2. `player_name`, 3. `player_gender`, 4. `team_name`, 5. `is_my_team`,
  6. `tournament_name`, 7. `event_type`, 8. `race_distance`, 9. `round`, 10. `measured_at`,
  11. `total_time_str`, 12. `lap_no`, 13. `lap_seconds`, 14. `lap_time_str`,
  15. `split_seconds`, 16. `split_time_str`, 17. `lap_distance_m`, 18. `cumulative_distance_m`,
  19. `speed_kmh`, 20. `is_fastest`, 21. `is_manual_edited`, 22. `is_missing`

### 2.2 WITMOTION 加速度・IMU CSV (全31カラム)
- **形式**: WinMotion互換 時系列連続ログ
- **主要カラム**:
  - A列: `Time`（`\tYYYY-MM-DD HH:MM:SS.fff`）
  - C列: `Chip Time()`（`\tYYYY-MM-DD HH:MM:SS.fff`）
  - D〜F列: `Acceleration X(g)`, `Acceleration Y(g)`, `Acceleration Z(g)`
  - G〜I列: `Angular velocity X(°/s)`, `Angular velocity Y(°/s)`, `Angular velocity Z(°/s)`
  - J〜L列: `Angle X(°)`, `Angle Y(°)`, `Angle Z(°)`
  - M〜O列: `Magnetic field X(μt)`, `Magnetic field Y(μt)`, `Magnetic field Z(μt)`
  - P列: `Temperature(℃)`

---

## 3. パーサー設計および安全保護ロジック

### 3.1 UTF-8 BOM (`\uFEFF`) および CRLF 改行の安全処理
Windows環境やExcelで出力されたCSVには、ファイル先頭にBOM（`\uFEFF`）が含まれる場合があります。パーサーは先頭文字がBOMであるかを自動検知し、安全にストリップします。また、改行コードは `\r\n` および `\n` の双方に完全対応します。

### 3.2 RFC 4180準拠のカンマ・ダブルクォートエスケープ分離
大会名や選手名にカンマが含まれる場合（例: `"佐藤, 花子"`）や `""` エスケープが存在する場合でも誤分割しない、ステートマシン型のCSVラインスプリッターを実装します。

### 3.3 Excel保護用タブ文字 (`\t`) のトリミング
Phase 1 で付加されたExcel誤認防止用のタブ文字 `\t` を検知し、文字列から除去して日時（`DateTime.parse`）や数値として安全にパースします。

### 3.4 欠損値 (NULL) およびゼロ除算防止ハンドリング
ストップウォッチの計測ボタン押し忘れ時（`is_missing = TRUE` や `lap_seconds = ""`）に、文字列から `double` へのパースで例外が発生しないよう `double.tryParse` を用い、安全に `null` を代入します。

---

## 4. 時系列インデックス算出・同期マッピング

### 4.1 センサー経過ミリ秒 (elapsedMilliseconds) の正規化
1. CSV先頭レコードのタイムスタンプ $T_0$ をセッション開始時刻として記録。
2. 第 $i$ 行目のタイムスタンプ $T_i$ に対し、経過ミリ秒を算出:
   $$\text{elapsedMilliseconds}_i = T_i - T_0 \quad [\text{ms}]$$
3. これにより、動画の再生シーク位置（ミリ秒）と二分探索（$O(\log N)$）で完全直結します。

### 4.2 動画タイムスタンプとセンサーデータの突合
動画ファイルの作成日時メタデータ（UTC）またはユーザー手動設定に基づき、初期同期基準点をマッピングします。

---

## 5. UI連携および状態更新フロー
```
[ ユーザー: CSVファイル選択 ]
      │
      ▼
[ CsvParseService (RFC 4180 / BOM除去 / 欠損保護) ]
      │
      ├─▶ List<LapRecord>    ➔ HUD情報バー更新 (選手名・大会名・周回ハイライト)
      │
      └─▶ List<SensorRecord> ➔ 加速度・角速度・角度波形グラフ再描画
```
