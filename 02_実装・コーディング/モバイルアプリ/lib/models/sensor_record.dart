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
  final double totalGyro;         // 角速度合成 sqrt(X^2 + Y^2 + Z^2)

  // 3軸角度 (°)
  final double angleX;
  final double angleY;
  final double angleZ;
  final double totalAngle;        // 角度合成 sqrt(X^2 + Y^2 + Z^2)

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
    required this.totalGyro,
    required this.angleX,
    required this.angleY,
    required this.angleZ,
    required this.totalAngle,
    this.temperature,
  });

  /// 3軸加速度・角速度・角度から合成値を自動計算するファクトリ
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
    final totalGyr = sqrt(gx * gx + gy * gy + gz * gz);
    final totalAng = sqrt(roll * roll + pitch * pitch + yaw * yaw);

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
      totalGyro: totalGyr,
      angleX: roll,
      angleY: pitch,
      angleZ: yaw,
      totalAngle: totalAng,
      temperature: temp,
    );
  }
}
