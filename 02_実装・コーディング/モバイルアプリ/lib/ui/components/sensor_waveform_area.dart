import 'package:flutter/material.dart';
import '../../models/sensor_record.dart';
import '../theme/app_theme.dart';

/// センサー波形グラフ ＆ 再生ヘッド追従エリア
class SensorWaveformArea extends StatelessWidget {
  final List<SensorRecord> records;
  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<double>? onSeek;

  const SensorWaveformArea({
    super.key,
    required this.records,
    required this.currentPosition,
    required this.totalDuration,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: AppTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 凡例ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '加速度波形 (g)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                Row(
                  children: [
                    _legendItem('Acc X', AppTheme.waveX),
                    const SizedBox(width: 8),
                    _legendItem('Acc Y', AppTheme.waveY),
                    const SizedBox(width: 8),
                    _legendItem('Acc Z', AppTheme.waveZ),
                    const SizedBox(width: 8),
                    _legendItem('合成G', AppTheme.waveTotal),
                  ],
                ),
              ],
            ),
          ),

          // 波形および再生ヘッド描画キャンバス
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                if (onSeek != null && totalDuration.inMilliseconds > 0) {
                  final fraction = (details.localPosition.dx / MediaQuery.of(context).size.width).clamp(0.0, 1.0);
                  onSeek!(fraction * totalDuration.inMilliseconds);
                }
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _WaveformPainter(
                  records: records,
                  currentPositionMs: currentPosition.inMilliseconds,
                  totalDurationMs: totalDuration.inMilliseconds > 0 ? totalDuration.inMilliseconds : 1000,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<SensorRecord> records;
  final int currentPositionMs;
  final int totalDurationMs;

  _WaveformPainter({
    required this.records,
    required this.currentPositionMs,
    required this.totalDurationMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;

    // グリッド基準線 (0Gライン)
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);

    if (records.isNotEmpty) {
      final pathX = Path();
      final pathY = Path();
      final pathZ = Path();
      final pathTotal = Path();

      const scaleY = 15.0; // 1Gあたりのピクセル高さ

      for (int i = 0; i < records.length; i++) {
        final rec = records[i];
        final x = (rec.elapsedMilliseconds / totalDurationMs) * size.width;
        final yX = midY - (rec.accelX * scaleY);
        final yY = midY - (rec.accelY * scaleY);
        final yZ = midY - (rec.accelZ * scaleY);
        final yTotal = midY - (rec.totalG * scaleY);

        if (i == 0) {
          pathX.moveTo(x, yX);
          pathY.moveTo(x, yY);
          pathZ.moveTo(x, yZ);
          pathTotal.moveTo(x, yTotal);
        } else {
          pathX.lineTo(x, yX);
          pathY.lineTo(x, yY);
          pathZ.lineTo(x, yZ);
          pathTotal.lineTo(x, yTotal);
        }
      }

      canvas.drawPath(pathX, Paint()..color = AppTheme.waveX..strokeWidth = 1.2..style = PaintingStyle.stroke);
      canvas.drawPath(pathY, Paint()..color = AppTheme.waveY..strokeWidth = 1.2..style = PaintingStyle.stroke);
      canvas.drawPath(pathZ, Paint()..color = AppTheme.waveZ..strokeWidth = 1.2..style = PaintingStyle.stroke);
      canvas.drawPath(pathTotal, Paint()..color = AppTheme.waveTotal..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }

    // 再生ヘッド (黄色縦ライン)
    final headX = (currentPositionMs / totalDurationMs).clamp(0.0, 1.0) * size.width;
    final headPaint = Paint()
      ..color = AppTheme.accentYellow
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(headX, 0), Offset(headX, size.height), headPaint);

    // 再生ヘッド上部三角マーカー
    final markerPath = Path()
      ..moveTo(headX - 5, 0)
      ..lineTo(headX + 5, 0)
      ..lineTo(headX, 7)
      ..close();
    canvas.drawPath(markerPath, Paint()..color = AppTheme.accentYellow);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}
