# 加速度センサーバイナリデータ（TXT）一括CSV変換プログラム 要件定義書

## 1. 概要・開発背景
- **背景:** 
  WITMOTION社製加速度センサー（9軸IMU）から記録されたデータ（`.TXT`）を「WinMotion」等の専用アプリで変換すると、1ファイルずつ手作業で行う必要があり、多大な時間がかかる。
- **目的:** 
  同一フォルダ内に格納された複数のバイナリTXTファイルを検知し、短時間で一括かつ正確にCSVへ自動デコード（パース）変換するプログラムを構築する。
- **最終形態:** 
  Pythonスクリプトによる自動処理、およびPython非インストール環境でもダブルクリックで実行可能なスタンドアローン形式（Windows向け `.exe` ファイル）。

---

## 2. 入出力仕様

### 2.1 入力データ
- **ファイル形式:** テキストファイル拡張子（`.TXT` または `.txt`）
- **データ実体:** 
  テキストファイルとして保存されているが、実体はWITMOTION通信プロトコルに基づく生の16進数バイナリデータ（リトルエンディアン形式）。
- **対象ファイル例:** `WIT00021.TXT` 等、フォルダ内のすべての該当ファイル。

### 2.2 出力データ
- **ファイル形式:** CSV形式（`.csv`、UTF-8 with BOM / `utf-8-sig`）
  - ※Excelで直接ダブルクリックして開いた際の日本語・記号の文字化けを防止。
- **出力命名規則:** `[元ファイル名].csv`（例: `WIT00021.TXT` → `WIT00021.csv`）
- **出力先:** 元ファイルと同じディレクトリ（または指定出力フォルダ）。

---

## 3. プロトコル解析・デコード仕様（WITMOTION準拠）

入力データは先頭ヘッダー `0x55` から始まる11バイト固定長のパケット群で構成される。

### 3.1 パケット構造（1パケット = 11バイト）
| バイト位置 | 名称 | 内容 |
|:---|:---|:---|
| 0 | ヘッダー | `0x55` 固定 |
| 1 | パケット種別 | データタイプ識別フラグ（`0x50` ～ `0x54` 等） |
| 2 ～ 9 | ペイロード | 8バイトのセンサーデータ（符号付き16bit整数等、リトルエンディアン） |
| 10 | チェックサム | 先頭から10バイトの合計値の下位1バイト |

### 3.2 パケット種別と変換計算式
1. **0x50: チップ時刻（Chip Time）**
   - フォーマット: `YY MM DD HH MM SS MS_L MS_H`
   - 表現: `20YY-MM-DD HH:mm:ss.fff`
2. **0x51: 加速度（Acceleration）**
   - 計算式: $\text{Value} = \frac{\text{RawData}}{32768} \times 16.0 \quad [\text{g}]$
   - 取得項目: Acceleration X, Acceleration Y, Acceleration Z, Temperature（℃ = Raw / 100）
3. **0x52: 角速度（Angular Velocity）**
   - 計算式: $\text{Value} = \frac{\text{RawData}}{32768} \times 2000.0 \quad [^\circ/\text{s}]$
   - 取得項目: Angular velocity X, Angular velocity Y, Angular velocity Z
4. **0x53: 角度（Angle）**
   - 計算式: $\text{Value} = \frac{\text{RawData}}{32768} \times 180.0 \quad [^\circ]$
   - 取得項目: Angle X, Angle Y, Angle Z
5. **0x54: 地磁気（Magnetic Field）**
   - 取得項目: Magnetic field X, Magnetic field Y, Magnetic field Z（$\mu\text{t}$）

---

## 4. 機能要件

### 4.1 一括自動検出・変換機能
- 実行ディレクトリ（または対象フォルダ）内にある `.TXT` / `.txt` ファイルを自動検出する。
- 検出された全ファイルを順番に自動処理し、進捗（「変換中: ○○.TXT -> ○○.csv ... 完了」）をコンソール上に表示する。

### 4.2 Excel表示・書式誤認対策機能（重要要件）
- **課題:** 
  A列（Time）やC列（Chip Time()）に `22:41:40.095` のような時刻・ミリ秒文字列をそのまま出力すると、Excelが自動で `mm:ss.0` や数値型に勝手に書式変換してしまい、時やミリ秒の欠損、表示崩れが発生する。
- **対応要件:**
  - 時刻文字列の先頭に `\t`（タブ文字）を挿入してCSVへ書き出す。
  - これにより、Excelや表計算ソフトが強制的に**「標準テキスト形式（文字列）」**として読み込み、ミリ秒まで欠損なく確実に保持・表示されること。

### 4.3 出力CSVカラム定義（31列構成）
出力されるCSVのカラムヘッダーは、WinMotion標準出力構成と互換性を持たせる。

```text
Time, Device name, Chip Time(), 
Acceleration X(g), Acceleration Y(g), Acceleration Z(g), 
Angular velocity X(°/s), Angular velocity Y(°/s), Angular velocity Z(°/s), 
Angle X(°), Angle Y(°), Angle Z(°), 
Magnetic field X(μt), Magnetic field Y(μt), Magnetic field Z(μt), 
Temperature(℃), Pressure(Pa), Height(m), Longitude(), Latitude(), 
GPS ground speed(km), Angle of course(°), GPS height(m), Number of satellites(), 
Position location(), Horizontal position(), Vertical position(), 
Quaternions 0(), Quaternions 1(), Quaternions 2(), Quaternions 3()
```

---

## 5. 非機能要件・環境要件

1. **実行環境:**
   - OS: Windows 10 / 11
   - 開発言語: Python 3.8 以上
   - 使用標準ライブラリ: `os`, `glob`, `struct`, `csv`, `datetime`（追加の外部パッケージインストール不要で動作可能）
2. **EXE化（配布用スタンドアローン）要件:**
   - ツール: `PyInstaller` を使用（`pyinstaller --onefile`）
   - Pythonが未導入のPCでも、作成された `.exe` ファイルをフォルダ内に配置してダブルクリックするだけで一括変換が完了すること。
3. **処理パフォーマンス:**
   - 1ファイル数万行規模のデータであっても、1ファイルあたり数秒以内で高速デコードできること。

---

## 6. 将来的な拡張・連携要件
- 生成されたCSVを入力とし、角度Z軸の急落（方位360度ループ）をトリガーにした「ショートトラック周回自動セクション分割機能」。
- 各周回における「加速度TOTAL（$\sqrt{X^2+Y^2+Z^2}$）」「角速度」「角度」の3軸連動表示・秒数（ラップタイム）算出機能とのシームレスな連携。