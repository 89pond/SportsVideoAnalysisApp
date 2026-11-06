#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
WITMOTION加速度センサーバイナリデータ（TXT）一括CSV変換プログラム
(WITMOTION Binary TXT to WinMotion-compatible CSV Batch Converter)

要件定義書・設計書に準拠:
- 11バイト固定長パケット (0x55 ヘッダー, 0x50〜0x54 パケット種別, チェックサム)
- WinMotion互換31列CSV (UTF-8 with BOM / CRLF)
- Excel時刻書式誤認防止のための \t（タブ文字）プレフィックス付加
- ダブルクリック実行（カレントディレクトリ内TXT一括自動変換）対応
"""

import os
import sys
import glob
import struct
import csv
from datetime import datetime

# WinMotion互換の31列ヘッダー定義
CSV_HEADERS = [
    "Time", "Device name", "Chip Time()",
    "Acceleration X(g)", "Acceleration Y(g)", "Acceleration Z(g)",
    "Angular velocity X(°/s)", "Angular velocity Y(°/s)", "Angular velocity Z(°/s)",
    "Angle X(°)", "Angle Y(°)", "Angle Z(°)",
    "Magnetic field X(μt)", "Magnetic field Y(μt)", "Magnetic field Z(μt)",
    "Temperature(℃)", "Pressure(Pa)", "Height(m)", "Longitude()", "Latitude()",
    "GPS ground speed(km)", "Angle of course(°)", "GPS height(m)", "Number of satellites()",
    "Position location()", "Horizontal position()", "Vertical position()",
    "Quaternions 0()", "Quaternions 1()", "Quaternions 2()", "Quaternions 3()"
]


def create_empty_record():
    """初期化された1行分のレコード辞書を作成"""
    return {header: "" for header in CSV_HEADERS}


def format_record(record):
    """レコード辞書をCSV出力用のリスト形式に変換"""
    return [record.get(h, "") for h in CSV_HEADERS]


def verify_checksum(packet: bytes) -> bool:
    """チェックサム検証: 先頭10バイトの合計の下位1バイトが11バイト目と一致するか"""
    if len(packet) != 11:
        return False
    return (sum(packet[:10]) & 0xFF) == packet[10]


def parse_packet_data(packet: bytes, record: dict):
    """
    11バイトパケットの種別を判定し、レコード辞書に物理値を設定する
    packet: 11バイトのbytesオブジェクト
    """
    pkg_type = packet[1]
    payload = packet[2:10]

    if pkg_type == 0x50:
        # 0x50: チップ時刻 (Chip Time)
        # YY MM DD HH MM SS MS_L MS_H
        yy, mm, dd, hh, mi, ss = payload[:6]
        ms = payload[6] | (payload[7] << 8)
        year = 2000 + yy
        # 安全性のため範囲チェック
        if 1 <= mm <= 12 and 1 <= dd <= 31 and 0 <= hh <= 23 and 0 <= mi <= 59 and 0 <= ss <= 60:
            time_str = f"{year:04d}-{mm:02d}-{dd:02d} {hh:02d}:{mi:02d}:{ss:02d}.{ms:03d}"
            # Excel誤認防止のため \t を先頭に付与
            record["Time"] = f"\t{time_str}"
            record["Chip Time()"] = f"\t{time_str}"

    elif pkg_type == 0x51:
        # 0x51: 加速度 (Acceleration)
        # ax, ay, az, temp (符号付き16bit int, リトルエンディアン)
        ax_raw, ay_raw, az_raw, t_raw = struct.unpack('<hhhh', payload)
        record["Acceleration X(g)"] = f"{ax_raw / 32768.0 * 16.0:.4f}"
        record["Acceleration Y(g)"] = f"{ay_raw / 32768.0 * 16.0:.4f}"
        record["Acceleration Z(g)"] = f"{az_raw / 32768.0 * 16.0:.4f}"
        record["Temperature(℃)"] = f"{t_raw / 100.0:.2f}"

    elif pkg_type == 0x52:
        # 0x52: 角速度 (Angular Velocity)
        # gx, gy, gz, t (符号付き16bit int, リトルエンディアン)
        gx_raw, gy_raw, gz_raw, _ = struct.unpack('<hhhh', payload)
        record["Angular velocity X(°/s)"] = f"{gx_raw / 32768.0 * 2000.0:.4f}"
        record["Angular velocity Y(°/s)"] = f"{gy_raw / 32768.0 * 2000.0:.4f}"
        record["Angular velocity Z(°/s)"] = f"{gz_raw / 32768.0 * 2000.0:.4f}"

    elif pkg_type == 0x53:
        # 0x53: 角度 (Angle)
        # roll, pitch, yaw, version (符号付き16bit int, リトルエンディアン)
        roll_raw, pitch_raw, yaw_raw, _ = struct.unpack('<hhhh', payload)
        record["Angle X(°)"] = f"{roll_raw / 32768.0 * 180.0:.3f}"
        record["Angle Y(°)"] = f"{pitch_raw / 32768.0 * 180.0:.3f}"
        record["Angle Z(°)"] = f"{yaw_raw / 32768.0 * 180.0:.3f}"

    elif pkg_type == 0x54:
        # 0x54: 地磁気 (Magnetic Field)
        # hx, hy, hz, t (符号付き16bit int, リトルエンディアン)
        hx_raw, hy_raw, hz_raw, _ = struct.unpack('<hhhh', payload)
        record["Magnetic field X(μt)"] = f"{hx_raw}"
        record["Magnetic field Y(μt)"] = f"{hy_raw}"
        record["Magnetic field Z(μt)"] = f"{hz_raw}"

    elif pkg_type == 0x59:
        # 0x59: クォータニオン (Quaternions - 存在する場合の拡張対応)
        q0_raw, q1_raw, q2_raw, q3_raw = struct.unpack('<hhhh', payload)
        record["Quaternions 0()"] = f"{q0_raw / 32768.0:.4f}"
        record["Quaternions 1()"] = f"{q1_raw / 32768.0:.4f}"
        record["Quaternions 2()"] = f"{q2_raw / 32768.0:.4f}"
        record["Quaternions 3()"] = f"{q3_raw / 32768.0:.4f}"


def convert_witmotion_binary_file(input_filepath: str, output_filepath: str = None) -> int:
    """
    1つのWITMOTIONバイナリTXTファイルをCSVへ変換する
    戻り値: 出力したレコード行数
    """
    if output_filepath is None:
        base, _ = os.path.splitext(input_filepath)
        output_filepath = base + ".csv"

    # バイナリデータ全読み込み
    with open(input_filepath, "rb") as f:
        data = f.read()

    data_len = len(data)
    if data_len < 11:
        print(f"  [警告] ファイルサイズが小さすぎます: {data_len} bytes")
        return 0

    idx = 0
    current_record = create_empty_record()
    has_pending_data = False
    row_count = 0

    # UTF-8 with BOM, CRLFで書き込み (csv.writer利用時は newline="" を指定し lineterminator で改行制御)
    with open(output_filepath, "w", encoding="utf-8-sig", newline="") as out_f:
        writer = csv.writer(out_f, lineterminator="\r\n")
        writer.writerow(CSV_HEADERS)

        while idx <= data_len - 11:
            # ヘッダー 0x55 の探索
            if data[idx] == 0x55:
                packet = data[idx:idx + 11]
                if verify_checksum(packet):
                    pkg_type = packet[1]

                    # 新しいサイクルの開始検知:
                    # 0x50 (Chip Time) が来た場合、またはすでに同種パケット値が保持されている場合は前行を出力
                    is_cycle_start = (pkg_type == 0x50) or (
                        pkg_type == 0x51 and current_record["Acceleration X(g)"] != ""
                    )

                    if is_cycle_start and has_pending_data:
                        writer.writerow(format_record(current_record))
                        row_count += 1
                        current_record = create_empty_record()
                        has_pending_data = False

                    # パケット解析
                    parse_packet_data(packet, current_record)
                    has_pending_data = True
                    idx += 11
                    continue

            # 0x55でない、またはチェックサム不一致の場合は1バイト進めてリスキャン
            idx += 1

        # 最終レコードの書き出し
        if has_pending_data:
            writer.writerow(format_record(current_record))
            row_count += 1

    return row_count


def process_directory(target_dir: str):
    """対象ディレクトリ内のすべての .TXT / .txt ファイルを一括変換"""
    patterns = [
        os.path.join(target_dir, "*.TXT"),
        os.path.join(target_dir, "*.txt")
    ]
    files = []
    for p in patterns:
        files.extend(glob.glob(p))
    files = sorted(list(set(files)))

    if not files:
        print(f"指定されたフォルダに対象ファイル (.TXT / .txt) が見つかりませんでした: {target_dir}")
        return

    print("=" * 60)
    print("WITMOTIONバイナリデータ一括CSV変換プログラム")
    print(f"処理対象フォルダ: {os.path.abspath(target_dir)}")
    print(f"検出ファイル数  : {len(files)} 件")
    print("=" * 60)

    success_count = 0
    total_rows = 0

    for idx, filepath in enumerate(files, start=1):
        filename = os.path.basename(filepath)
        print(f"[{idx}/{len(files)}] 変換中: {filename} ... ", end="", flush=True)
        try:
            rows = convert_witmotion_binary_file(filepath)
            csv_name = os.path.splitext(filename)[0] + ".csv"
            print(f"完了 (出力: {csv_name}, {rows:,} 行)")
            success_count += 1
            total_rows += rows
        except Exception as e:
            print(f"エラー発生: {e}")

    print("-" * 60)
    print(f"一括変換完了: {success_count}/{len(files)} 成功, 総出力レコード数: {total_rows:,} 行")
    print("=" * 60)


def main():
    """エントリーポイント"""
    # 引数があればそのパス、なければカレントディレクトリ
    if len(sys.argv) > 1:
        target_path = sys.argv[1]
        if os.path.isfile(target_path):
            print(f"単一ファイル変換: {target_path}")
            rows = convert_witmotion_binary_file(target_path)
            print(f"完了: {rows:,} 行出力")
        else:
            process_directory(target_path)
    else:
        # 引数なし（ダブルクリック起動時等）
        current_dir = os.path.dirname(os.path.abspath(__file__))
        process_directory(current_dir)

    # Windowsダブルクリック実行時の自動終了防止
    if sys.stdin and sys.stdin.isatty():
        input("\n[Enter]キーを押して終了してください...")


if __name__ == "__main__":
    main()
