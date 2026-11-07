import 'package:flutter/material.dart';
import '../../models/sensor_record.dart';
import '../../models/waveform_series.dart';
import '../theme/app_theme.dart';

/// センサー波形グラフ ＆ 再生ヘッド追従エリア (複数波形選択対応)
class SensorWaveformArea extends StatelessWidget {
  final List<SensorRecord> records;
  final Duration currentPosition;
  final Duration totalDuration;
  final Set<WaveformSeries> selectedSeries;
  final ValueChanged<Set<WaveformSeries>> onSelectedSeriesChanged;
  final ValueChanged<double>? onSeek;

  const SensorWaveformArea({
    super.key,
    required this.records,
    required this.currentPosition,
    required this.totalDuration,
    required this.selectedSeries,
    required this.onSelectedSeriesChanged,
    this.onSeek,
  });

  void _showSeriesSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentSelected = Set<WaveformSeries>.from(selectedSeries);

            void toggleSeries(WaveformSeries s) {
              setModalState(() {
                if (currentSelected.contains(s)) {
                  if (currentSelected.length > 1) {
                    currentSelected.remove(s);
                  }
                } else {
                  currentSelected.add(s);
                }
              });
              onSelectedSeriesChanged(currentSelected);
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '表示する波形を選択 (複数選択可能)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('閉じる', style: TextStyle(color: AppTheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 1. 加速度グループ
                  _buildGroupChips('加速度 (g)', [
                    WaveformSeries.accelX,
                    WaveformSeries.accelY,
                    WaveformSeries.accelZ,
                    WaveformSeries.accelTotal,
                  ], currentSelected, toggleSeries),

                  const SizedBox(height: 12),

                  // 2. 角速度グループ
                  _buildGroupChips('角速度 (°/s)', [
                    WaveformSeries.gyroX,
                    WaveformSeries.gyroY,
                    WaveformSeries.gyroZ,
                    WaveformSeries.gyroTotal,
                  ], currentSelected, toggleSeries),

                  const SizedBox(height: 12),

                  // 3. 角度グループ
                  _buildGroupChips('角度 (°)', [
                    WaveformSeries.angleX,
                    WaveformSeries.angleY,
                    WaveformSeries.angleZ,
                    WaveformSeries.angleTotal,
                  ], currentSelected, toggleSeries),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupChips(
    String groupTitle,
    List<WaveformSeries> seriesList,
    Set<WaveformSeries> currentSelected,
    ValueChanged<WaveformSeries> onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupTitle,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: seriesList.map((s) {
            final isSelected = currentSelected.contains(s);
            return FilterChip(
              selected: isSelected,
              label: Text(s.label),
              avatar: CircleAvatar(
                backgroundColor: s.color,
                radius: 5,
              ),
              selectedColor: s.color.withOpacity(0.25),
              checkmarkColor: s.color,
              labelStyle: TextStyle(
                fontSize: 11,
                color: isSelected ? s.color : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(color: isSelected ? s.color : Colors.white24),
              backgroundColor: AppTheme.cardColor,
              onSelected: (_) => onToggle(s),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      color: AppTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 凡例ヘッダー & 波形選択ボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 波形選択設定ボタン
                InkWell(
                  onTap: () => _showSeriesSelectionDialog(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune, size: 13, color: AppTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          '波形選択',
                          style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // 選択中波形の凡例 (横スクロール可能)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: selectedSeries.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              if (selectedSeries.length > 1) {
                                final updated = Set<WaveformSeries>.from(selectedSeries)..remove(s);
                                onSelectedSeriesChanged(updated);
                              }
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  s.label,
                                  style: TextStyle(fontSize: 10, color: s.color, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
                painter: _MultiSeriesWaveformPainter(
                  records: records,
                  selectedSeries: selectedSeries,
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
}

class _MultiSeriesWaveformPainter extends CustomPainter {
  final List<SensorRecord> records;
  final Set<WaveformSeries> selectedSeries;
  final int currentPositionMs;
  final int totalDurationMs;

  _MultiSeriesWaveformPainter({
    required this.records,
    required this.selectedSeries,
    required this.currentPositionMs,
    required this.totalDurationMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;

    // 0基準センターライン
    final gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);

    if (records.isNotEmpty && selectedSeries.isNotEmpty) {
      for (final series in selectedSeries) {
        final path = Path();
        final paint = Paint()
          ..color = series.color
          ..strokeWidth = series.name.contains('Total') ? 1.8 : 1.2
          ..style = PaintingStyle.stroke;

        // グループに応じた正規化スケール係数
        final double scaleY;
        if (series.groupName == '加速度') {
          scaleY = 16.0; // 1Gあたり 16px
        } else if (series.groupName == '角速度') {
          scaleY = 0.08; // 100°/sあたり 8px
        } else {
          scaleY = 0.25; // 45°あたり 11px
        }

        for (int i = 0; i < records.length; i++) {
          final rec = records[i];
          final x = (rec.elapsedMilliseconds / totalDurationMs) * size.width;
          final val = series.getValue(rec);
          final y = (midY - (val * scaleY)).clamp(2.0, size.height - 2.0);

          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, paint);
      }
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
  bool shouldRepaint(covariant _MultiSeriesWaveformPainter oldDelegate) => true;
}
