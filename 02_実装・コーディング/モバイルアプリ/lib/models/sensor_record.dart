import 'dart:math';

/// 1レコード分のセンサーデータモデル (WITMOTION 31列CSV互換)
class SensorRecord {
  final DateTime timestamp;        // 計測日時 (ミリ秒精度)
  final int elapsedMilliseconds;   // セッション開始からの経過ミリ秒 (二分探索用キー)
  
  // 3軸加速度 (g)
  final double accelX;
  final double accelY;
  final double accelZ;
  final double totalG;            // 合成加速度 sqrt(X^2 + Y^2 + Z^2)

  // 3軸角速度 (°/s)
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  // 3軸角度 (°)
  final double angleX;
  final double angleY;
  final double angleZ;

  // 温度 (℃)
  final double? temperature;

  SensorRecord({
    required this.timestamp,
    required this.elapsedMilliseconds,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.totalG,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.angleX,
    required this.angleY,
    required this.angleZ,
    this.temperature,
  });

  /// 3軸加速度から合成Gを自動計算するファクトリ
  factory SensorRecord.fromRaw({
    required DateTime timestamp,
    required int elapsedMilliseconds,
    required double ax,
    required double ay,
    required double az,
    double gx = 0.0,
    double gy = 0.0,
    double gz = 0.0,
    double roll = 0.0,
    double pitch = 0.0,
    double yaw = 0.0,
    double? temp,
  }) {
    final g = sqrt(ax * ax + ay * ay + az * az);
    return SensorRecord(
      timestamp: timestamp,
      elapsedMilliseconds: elapsedMilliseconds,
      accelX: ax,
      accelY: ay,
      accelZ: az,
      totalG: g,
      gyroX: gx,
      gyroY: gy,
      gyroZ: gz,
      angleX: roll,
      angleY: pitch,
      angleZ: yaw,
      temperature: temp,
    );
  }
}
