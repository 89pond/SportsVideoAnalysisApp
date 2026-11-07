import 'package:flutter/material.dart';
import 'sensor_record.dart';

/// グラフ表示可能な波形系列の種類
enum WaveformSeries {
  // 加速度 (g)
  accelX,
  accelY,
  accelZ,
  accelTotal,

  // 角速度 (°/s)
  gyroX,
  gyroY,
  gyroZ,
  gyroTotal,

  // 角度 (°)
  angleX,
  angleY,
  angleZ,
  angleTotal,
}

/// 波形系列のメタ情報・表示プロパティ
extension WaveformSeriesExtension on WaveformSeries {
  String get label {
    switch (this) {
      case WaveformSeries.accelX:
        return 'Acc X';
      case WaveformSeries.accelY:
        return 'Acc Y';
      case WaveformSeries.accelZ:
        return 'Acc Z';
      case WaveformSeries.accelTotal:
        return 'Acc 合成G';

      case WaveformSeries.gyroX:
        return 'Gyro X';
      case WaveformSeries.gyroY:
        return 'Gyro Y';
      case WaveformSeries.gyroZ:
        return 'Gyro Z';
      case WaveformSeries.gyroTotal:
        return 'Gyro 合成';

      case WaveformSeries.angleX:
        return 'Angle X';
      case WaveformSeries.angleY:
        return 'Angle Y';
      case WaveformSeries.angleZ:
        return 'Angle Z';
      case WaveformSeries.angleTotal:
        return 'Angle 合成';
    }
  }

  String get groupName {
    switch (this) {
      case WaveformSeries.accelX:
      case WaveformSeries.accelY:
      case WaveformSeries.accelZ:
      case WaveformSeries.accelTotal:
        return '加速度';
      case WaveformSeries.gyroX:
      case WaveformSeries.gyroY:
      case WaveformSeries.gyroZ:
      case WaveformSeries.gyroTotal:
        return '角速度';
      case WaveformSeries.angleX:
      case WaveformSeries.angleY:
      case WaveformSeries.angleZ:
      case WaveformSeries.angleTotal:
        return '角度';
    }
  }

  String get unit {
    switch (this) {
      case WaveformSeries.accelX:
      case WaveformSeries.accelY:
      case WaveformSeries.accelZ:
      case WaveformSeries.accelTotal:
        return 'g';
      case WaveformSeries.gyroX:
      case WaveformSeries.gyroY:
      case WaveformSeries.gyroZ:
      case WaveformSeries.gyroTotal:
        return '°/s';
      case WaveformSeries.angleX:
      case WaveformSeries.angleY:
      case WaveformSeries.angleZ:
      case WaveformSeries.angleTotal:
        return '°';
    }
  }

  Color get color {
    switch (this) {
      // 加速度
      case WaveformSeries.accelX:
        return const Color(0xFFFF5252);     // 赤
      case WaveformSeries.accelY:
        return const Color(0xFF69F0AE);     // 明るい緑
      case WaveformSeries.accelZ:
        return const Color(0xFF40C4FF);     // 水色
      case WaveformSeries.accelTotal:
        return const Color(0xFFFFD740);     // 黄金色

      // 角速度
      case WaveformSeries.gyroX:
        return const Color(0xFFFF9100);     // オレンジ
      case WaveformSeries.gyroY:
        return const Color(0xFF00E676);     // エメラルドグリーン
      case WaveformSeries.gyroZ:
        return const Color(0xFF448AFF);     // 青
      case WaveformSeries.gyroTotal:
        return const Color(0xFFFF4081);     // ピンク

      // 角度
      case WaveformSeries.angleX:
        return const Color(0xFFE040FB);     // 紫
      case WaveformSeries.angleY:
        return const Color(0xFF18FFFF);     // シアン
      case WaveformSeries.angleZ:
        return const Color(0xFFEEFF41);     // ライムイエロー
      case WaveformSeries.angleTotal:
        return const Color(0xFFFFFFFF);     // 白
    }
  }

  double getValue(SensorRecord record) {
    switch (this) {
      case WaveformSeries.accelX:
        return record.accelX;
      case WaveformSeries.accelY:
        return record.accelY;
      case WaveformSeries.accelZ:
        return record.accelZ;
      case WaveformSeries.accelTotal:
        return record.totalG;

      case WaveformSeries.gyroX:
        return record.gyroX;
      case WaveformSeries.gyroY:
        return record.gyroY;
      case WaveformSeries.gyroZ:
        return record.gyroZ;
      case WaveformSeries.gyroTotal:
        return record.totalGyro;

      case WaveformSeries.angleX:
        return record.angleX;
      case WaveformSeries.angleY:
        return record.angleY;
      case WaveformSeries.angleZ:
        return record.angleZ;
      case WaveformSeries.angleTotal:
        return record.totalAngle;
    }
  }
}
