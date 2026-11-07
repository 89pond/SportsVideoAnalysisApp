import 'package:flutter/material.dart';
import '../../models/lap_record.dart';
import '../../models/sensor_record.dart';
import '../theme/app_theme.dart';

/// HUD (ヘッドアップディスプレイ) 風 計測・加速度表示バー
class HudOverlayBar extends StatelessWidget {
  final LapRecord? currentLap;
  final SensorRecord? currentSensor;
  final double diffSeconds; // 比較対象とのタイム差 (+/-)

  const HudOverlayBar({
    super.key,
    this.currentLap,
    this.currentSensor,
    this.diffSeconds = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final lapText = currentLap != null
        ? 'LAP ${currentLap!.lapNo}: ${currentLap!.lapTimeStr ?? '--'}'
        : 'LAP: 計測待機';

    final totalG = currentSensor != null ? currentSensor!.totalG : 1.0;
    final diffColor = diffSeconds <= 0 ? AppTheme.accentGreen : AppTheme.secondary;
    final diffSign = diffSeconds > 0 ? '+' : '';
    final diffText = currentLap != null ? '$diffSign${diffSeconds.toStringAsFixed(2)}s' : '--';

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左側: ラップタイム情報
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primary, width: 1),
                ),
                child: Text(
                  lapText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 比較差分 (Diff)
              Text(
                'Diff: $diffText',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: diffColor,
                ),
              ),
            ],
          ),

          // 右側: リアルタイム合成G値ゲージ
          Row(
            children: [
              const Text('合成G: ', style: TextStyle(fontSize: 12, color: Colors.white70)),
              Text(
                '${totalG.toStringAsFixed(2)} G',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentYellow,
                ),
              ),
              const SizedBox(width: 8),
              // G値ビジュアルインジケーター (最大3.0G目安)
              SizedBox(
                width: 60,
                height: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (totalG / 3.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      totalG > 2.0 ? AppTheme.secondary : AppTheme.accentYellow,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
