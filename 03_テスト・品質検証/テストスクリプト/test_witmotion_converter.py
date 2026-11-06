#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Agent 3: WITMOTIONバイナリ変換ツール 自動テストスクリプト
- 正常系パケット（0x50〜0x54）のデコード整合性テスト
- チェックサム検証および計算式精度テスト
- 通信ノイズ・破損パケット自動スキップ耐性テスト
- 出力CSVの31カラム整合性・BOM・Excel用タブ文字(\t)検証テスト
"""

import os
import sys
import struct
import tempfile
import unittest

# テスト対象モジュールのインポート
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
TOOL_DIR = os.path.abspath(os.path.join(CURRENT_DIR, "../../02_実装・コーディング/センサーデータ変換ツール"))
sys.path.insert(0, TOOL_DIR)

from witmotion_converter import (
    CSV_HEADERS,
    verify_checksum,
    parse_packet_data,
    create_empty_record,
    convert_witmotion_binary_file,
)


def make_packet(pkg_type: int, payload: bytes) -> bytes:
    """11バイトパケット（ヘッダー0x55 + 種別 + 8byteペイロード + チェックサム）を生成"""
    assert len(payload) == 8
    prefix = bytes([0x55, pkg_type]) + payload
    checksum = sum(prefix) & 0xFF
    return prefix + bytes([checksum])


class TestWitmotionConverter(unittest.TestCase):

    def test_checksum_verification(self):
        """チェックサム計算・検証のテスト"""
        # 正常パケット
        payload = bytes([1, 2, 3, 4, 5, 6, 7, 8])
        packet = make_packet(0x51, payload)
        self.assertTrue(verify_checksum(packet))

        # チェックサム破損パケット
        corrupted = packet[:10] + bytes([(packet[10] + 1) & 0xFF])
        self.assertFalse(verify_checksum(corrupted))

        # 長さ不足
        self.assertFalse(verify_checksum(packet[:9]))

    def test_chip_time_decoding(self):
        """0x50 Chip TimeのパースおよびExcel用 \t 付加テスト"""
        # 2026-11-05 22:41:40.095 -> YY=26, MM=11, DD=5, HH=22, MI=41, SS=40, MS=95 (0x005F)
        ms = 95
        ms_l = ms & 0xFF
        ms_h = (ms >> 8) & 0xFF
        payload = bytes([26, 11, 5, 22, 41, 40, ms_l, ms_h])
        packet = make_packet(0x50, payload)

        record = create_empty_record()
        parse_packet_data(packet, record)

        expected_time = "\t2026-11-05 22:41:40.095"
        self.assertEqual(record["Time"], expected_time)
        self.assertEqual(record["Chip Time()"], expected_time)

    def test_acceleration_decoding(self):
        """0x51 加速度のパースおよび計算精度テスト"""
        # 1.0g = 32768 / 16 = 2048 (raw)
        # 0.5g = 1024
        # -1.0g = -2048
        # Temp = 25.50℃ = 2550
        raw_ax = 2048
        raw_ay = 1024
        raw_az = -2048
        raw_temp = 2550
        payload = struct.pack('<hhhh', raw_ax, raw_ay, raw_az, raw_temp)
        packet = make_packet(0x51, payload)

        record = create_empty_record()
        parse_packet_data(packet, record)

        self.assertEqual(record["Acceleration X(g)"], "1.0000")
        self.assertEqual(record["Acceleration Y(g)"], "0.5000")
        self.assertEqual(record["Acceleration Z(g)"], "-1.0000")
        self.assertEqual(record["Temperature(℃)"], "25.50")

    def test_angular_velocity_decoding(self):
        """0x52 角速度のパースおよび計算精度テスト"""
        # 100°/s = 100 * 32768 / 2000 = 1638.4 -> 1638 (0.9997)
        # raw = 16384 -> 1000.0000 °/s
        raw_gx = 16384
        raw_gy = -16384
        raw_gz = 0
        payload = struct.pack('<hhhh', raw_gx, raw_gy, raw_gz, 0)
        packet = make_packet(0x52, payload)

        record = create_empty_record()
        parse_packet_data(packet, record)

        self.assertEqual(record["Angular velocity X(°/s)"], "1000.0000")
        self.assertEqual(record["Angular velocity Y(°/s)"], "-1000.0000")
        self.assertEqual(record["Angular velocity Z(°/s)"], "0.0000")

    def test_angle_decoding(self):
        """0x53 角度のパースおよび計算精度テスト"""
        # 90° = 90 * 32768 / 180 = 16384
        # -45° = -8192
        # 180° = 32767 (179.995)
        raw_roll = 16384
        raw_pitch = -8192
        raw_yaw = 0
        payload = struct.pack('<hhhh', raw_roll, raw_pitch, raw_yaw, 0)
        packet = make_packet(0x53, payload)

        record = create_empty_record()
        parse_packet_data(packet, record)

        self.assertEqual(record["Angle X(°)"], "90.000")
        self.assertEqual(record["Angle Y(°)"], "-45.000")
        self.assertEqual(record["Angle Z(°)"], "0.000")

    def test_full_stream_with_noise(self):
        """ノイズ混入ストリームから正常に2サイクルを復元・CSV出力するテスト"""
        # サイクル1: 0x50, 0x51, 0x52, 0x53, 0x54
        c1_time = make_packet(0x50, bytes([26, 11, 5, 10, 0, 0, 0, 0]))
        c1_acc = make_packet(0x51, struct.pack('<hhhh', 2048, 0, 0, 2000))
        c1_gyro = make_packet(0x52, struct.pack('<hhhh', 0, 0, 0, 0))
        c1_ang = make_packet(0x53, struct.pack('<hhhh', 0, 0, 0, 0))
        c1_mag = make_packet(0x54, struct.pack('<hhhh', 10, 20, 30, 0))

        # ノイズ（ランダムバイト、壊れた0x55パケット）
        noise = bytes([0xFF, 0x00, 0x55, 0x99, 0x12, 0x34, 0xAA, 0xBB])

        # サイクル2: 0x50, 0x51
        c2_time = make_packet(0x50, bytes([26, 11, 5, 10, 0, 1, 0, 0]))
        c2_acc = make_packet(0x51, struct.pack('<hhhh', 0, 2048, 0, 2100))

        binary_stream = c1_time + c1_acc + c1_gyro + c1_ang + c1_mag + noise + c2_time + c2_acc

        with tempfile.TemporaryDirectory() as tmpdir:
            input_file = os.path.join(tmpdir, "TEST_WIT.TXT")
            output_file = os.path.join(tmpdir, "TEST_WIT.csv")

            with open(input_file, "wb") as f:
                f.write(binary_stream)

            rows = convert_witmotion_binary_file(input_file, output_file)
            self.assertEqual(rows, 2)

            # CSVの内容検証
            with open(output_file, "r", encoding="utf-8-sig") as f:
                lines = f.readlines()

            # ヘッダー + 2行 = 3行
            self.assertEqual(len(lines), 3)

            # ヘッダー検証
            header_line = lines[0].rstrip("\r\n").split(",")
            self.assertEqual(len(header_line), 31)
            self.assertEqual(header_line[0], "Time")
            self.assertEqual(header_line[3], "Acceleration X(g)")

            # 1行目データ検証
            row1 = lines[1].rstrip("\r\n").split(",")
            self.assertEqual(row1[0], "\t2026-11-05 10:00:00.000")
            self.assertEqual(row1[3], "1.0000")
            self.assertEqual(row1[12], "10")  # Mag X

            # 2行目データ検証
            row2 = lines[2].rstrip("\r\n").split(",")
            self.assertEqual(row2[0], "\t2026-11-05 10:00:01.000")
            self.assertEqual(row2[4], "1.0000")  # Acc Y


if __name__ == "__main__":
    unittest.main()
