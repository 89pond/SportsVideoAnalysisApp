import 'dart:math';
import '../models/lap_record.dart';
import '../models/sensor_record.dart';

/// CSVパースおよびデータ正規化サービス (RFC 4180 / BOM対応)
class CsvParseService {
  /// CSV文字列からBOM (UTF-8 with BOM: \uFEFF) を除去し、安全な行リストに分割
  static List<String> splitToLines(String csvContent) {
    var content = csvContent;
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }
    // CRLF および LF に対応
    return content.split(RegExp(r'\r\n|\n|\r'));
  }

  /// 1行のCSVテキストをRFC 4180準拠（ダブルクォートエスケープ考慮）でカラム分割
  static List<String> parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // 2連ダブルクォート ("") のエスケープ解除
          buffer.write('"');
          i++;
        } else {
          // クォートの開始／終了
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }

  /// StopWatch LinkLog CSV (全22カラム) のパース
  static List<LapRecord> parseStopWatchLinkLogCsv(String csvContent) {
    final lines = splitToLines(csvContent);
    final laps = <LapRecord>[];

    if (lines.isEmpty) return laps;

    // ヘッダー行をスキップ (1行目)
    for (int lineIdx = 1; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx].trim();
      if (line.isEmpty) continue;

      final cols = parseCsvLine(line);
      if (cols.length < 16) continue; // 最低限の必須カラム数

      try {
        final sessionId = cols[0].trim();
        final playerName = cols[1].trim();
        final tournamentName = cols.length > 5 ? cols[5].trim() : '';
        final eventType = cols.length > 6 ? cols[6].trim() : '';
        final lapNo = int.tryParse(cols[11].trim()) ?? lineIdx;

        // 欠損値保護: 押し忘れ時は null
        final lapSecStr = cols[12].trim();
        final lapSeconds = lapSecStr.isNotEmpty ? double.tryParse(lapSecStr) : null;
        final lapTimeStr = cols[13].trim().isNotEmpty ? cols[13].trim() : null;

        final splitSeconds = double.tryParse(cols[14].trim()) ?? 0.0;
        final splitTimeStr = cols[15].trim();

        final lapDistM = cols.length > 16 ? double.tryParse(cols[16].trim()) ?? 0.0 : 0.0;
        final cumDistM = cols.length > 17 ? double.tryParse(cols[17].trim()) ?? 0.0 : 0.0;
        final speedKmh = cols.length > 18 ? double.tryParse(cols[18].trim()) : null;

        final isFastest = cols.length > 19 && cols[19].trim().toUpperCase() == 'TRUE';
        final isMissing = cols.length > 21 && cols[21].trim().toUpperCase() == 'TRUE';

        laps.add(LapRecord(
          sessionId: sessionId,
          playerName: playerName,
          tournamentName: tournamentName,
          eventType: eventType,
          lapNo: lapNo,
          lapSeconds: lapSeconds,
          lapTimeStr: lapTimeStr,
          splitSeconds: splitSeconds,
          splitTimeStr: splitTimeStr,
          lapDistanceM: lapDistM,
          cumulativeDistanceM: cumDistM,
          speedKmh: speedKmh,
          isFastest: isFastest,
          isMissing: isMissing,
        ));
      } catch (e) {
        // パース失敗した行は安全にスキップ
        continue;
      }
    }

    return laps;
  }

  /// WITMOTION 31列 加速度・IMU CSV のパース
  static List<SensorRecord> parseWitmotionSensorCsv(String csvContent) {
    final lines = splitToLines(csvContent);
    final records = <SensorRecord>[];

    if (lines.isEmpty) return records;

    DateTime? initialTimestamp;

    // ヘッダー行をスキップ (1行目)
    for (int lineIdx = 1; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx].trim();
      if (line.isEmpty) continue;

      final cols = parseCsvLine(line);
      if (cols.length < 6) continue; // タイムスタンプと3軸加速度は必須

      try {
        // Time列またはChip Time列から \t（タブ文字）を除去してパース
        var timeStr = cols[0].replaceAll('\t', '').trim();
        if (timeStr.isEmpty && cols.length > 2) {
          timeStr = cols[2].replaceAll('\t', '').trim();
        }

        DateTime timestamp;
        try {
          timestamp = DateTime.parse(timeStr.replaceAll(' ', 'T'));
        } catch (_) {
          // 日時パース失敗時は100Hz相当 (10ms刻み) で補完
          timestamp = (initialTimestamp ?? DateTime.now()).add(Duration(milliseconds: (lineIdx - 1) * 10));
        }

        initialTimestamp ??= timestamp;
        final elapsedMs = timestamp.difference(initialTimestamp).inMilliseconds;

        // 3軸加速度 (g)
        final ax = double.tryParse(cols[3].trim()) ?? 0.0;
        final ay = double.tryParse(cols[4].trim()) ?? 0.0;
        final az = double.tryParse(cols[5].trim()) ?? 0.0;

        // 3軸角速度 (°/s) - 存在する場合
        final gx = cols.length > 6 ? double.tryParse(cols[6].trim()) ?? 0.0 : 0.0;
        final gy = cols.length > 7 ? double.tryParse(cols[7].trim()) ?? 0.0 : 0.0;
        final gz = cols.length > 8 ? double.tryParse(cols[8].trim()) ?? 0.0 : 0.0;

        // 3軸角度 (°) - 存在する場合
        final roll = cols.length > 9 ? double.tryParse(cols[9].trim()) ?? 0.0 : 0.0;
        final pitch = cols.length > 10 ? double.tryParse(cols[10].trim()) ?? 0.0 : 0.0;
        final yaw = cols.length > 11 ? double.tryParse(cols[11].trim()) ?? 0.0 : 0.0;

        // 温度 (℃)
        final temp = cols.length > 15 ? double.tryParse(cols[15].trim()) : null;

        records.add(SensorRecord.fromRaw(
          timestamp: timestamp,
          elapsedMilliseconds: elapsedMs >= 0 ? elapsedMs : (lineIdx - 1) * 10,
          ax: ax,
          ay: ay,
          az: az,
          gx: gx,
          gy: gy,
          gz: gz,
          roll: roll,
          pitch: pitch,
          yaw: yaw,
          temp: temp,
        ));
      } catch (e) {
        continue;
      }
    }

    return records;
  }
}
