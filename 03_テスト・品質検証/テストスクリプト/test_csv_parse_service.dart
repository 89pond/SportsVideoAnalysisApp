// Agent 3: CSVパースサービス (LinkLog 22列 ＆ WITMOTION 31列) 単体テスト
import 'dart:math';

// テスト用モデル簡易定義
class LapRecord {
  final String sessionId;
  final String playerName;
  final String tournamentName;
  final String eventType;
  final int lapNo;
  final double? lapSeconds;
  final String? lapTimeStr;
  final double splitSeconds;
  final String splitTimeStr;
  final double lapDistanceM;
  final double cumulativeDistanceM;
  final double? speedKmh;
  final bool isFastest;
  final bool isMissing;

  LapRecord({
    required this.sessionId,
    required this.playerName,
    required this.tournamentName,
    required this.eventType,
    required this.lapNo,
    this.lapSeconds,
    this.lapTimeStr,
    required this.splitSeconds,
    required this.splitTimeStr,
    required this.lapDistanceM,
    required this.cumulativeDistanceM,
    this.speedKmh,
    this.isFastest = false,
    this.isMissing = false,
  });
}

class SensorRecord {
  final DateTime timestamp;
  final int elapsedMilliseconds;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double totalG;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double totalGyro;

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
  });
}

// テスト対象パーサーロジック
class CsvParseService {
  static List<String> splitToLines(String csvContent) {
    var content = csvContent;
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }
    return content.split(RegExp(r'\r\n|\n|\r'));
  }

  static List<String> parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
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

  static List<LapRecord> parseStopWatchLinkLogCsv(String csvContent) {
    final lines = splitToLines(csvContent);
    final laps = <LapRecord>[];
    if (lines.isEmpty) return laps;

    for (int lineIdx = 1; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx].trim();
      if (line.isEmpty) continue;
      final cols = parseCsvLine(line);
      if (cols.length < 16) continue;

      final sessionId = cols[0].trim();
      final playerName = cols[1].trim();
      final tournamentName = cols.length > 5 ? cols[5].trim() : '';
      final eventType = cols.length > 6 ? cols[6].trim() : '';
      final lapNo = int.tryParse(cols[11].trim()) ?? lineIdx;

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
    }
    return laps;
  }

  static List<SensorRecord> parseWitmotionSensorCsv(String csvContent) {
    final lines = splitToLines(csvContent);
    final records = <SensorRecord>[];
    if (lines.isEmpty) return records;

    DateTime? initialTimestamp;

    for (int lineIdx = 1; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx].trim();
      if (line.isEmpty) continue;
      final cols = parseCsvLine(line);
      if (cols.length < 6) continue;

      var timeStr = cols[0].replaceAll('\t', '').trim();
      if (timeStr.isEmpty && cols.length > 2) {
        timeStr = cols[2].replaceAll('\t', '').trim();
      }

      DateTime timestamp;
      try {
        timestamp = DateTime.parse(timeStr.replaceAll(' ', 'T'));
      } catch (_) {
        timestamp = (initialTimestamp ?? DateTime.now()).add(Duration(milliseconds: (lineIdx - 1) * 10));
      }

      initialTimestamp ??= timestamp;
      final elapsedMs = timestamp.difference(initialTimestamp).inMilliseconds;

      final ax = double.tryParse(cols[3].trim()) ?? 0.0;
      final ay = double.tryParse(cols[4].trim()) ?? 0.0;
      final az = double.tryParse(cols[5].trim()) ?? 0.0;
      final gx = cols.length > 6 ? double.tryParse(cols[6].trim()) ?? 0.0 : 0.0;
      final gy = cols.length > 7 ? double.tryParse(cols[7].trim()) ?? 0.0 : 0.0;
      final gz = cols.length > 8 ? double.tryParse(cols[8].trim()) ?? 0.0 : 0.0;

      final totalG = sqrt(ax * ax + ay * ay + az * az);
      final totalGyr = sqrt(gx * gx + gy * gy + gz * gz);

      records.add(SensorRecord(
        timestamp: timestamp,
        elapsedMilliseconds: elapsedMs >= 0 ? elapsedMs : (lineIdx - 1) * 10,
        accelX: ax,
        accelY: ay,
        accelZ: az,
        totalG: totalG,
        gyroX: gx,
        gyroY: gy,
        gyroZ: gz,
        totalGyro: totalGyr,
      ));
    }
    return records;
  }
}

void main() {
  int passed = 0;
  int failed = 0;

  void assertEqual(String testName, dynamic actual, dynamic expected) {
    if (actual == expected) {
      print(' [PASS] $testName: actual=$actual');
      passed++;
    } else {
      print(' [FAIL] $testName: actual=$actual, expected=$expected');
      failed++;
    }
  }

  print('======================================================');
  print('CSV Parse Service 単体テスト');
  print('======================================================');

  // 1. StopWatch LinkLog CSV テスト
  print('\n-- [1/2] StopWatch LinkLog CSV パーステスト --');
  const sampleLinkLogCsv = '''\uFEFFsession_id,player_name,player_gender,team_name,is_my_team,tournament_name,event_type,race_distance,round,measured_at,total_time_str,lap_no,lap_seconds,lap_time_str,split_seconds,split_time_str,lap_distance_m,cumulative_distance_m,speed_kmh,is_fastest,is_manual_edited,is_missing\r
"20261102_1041_CH5","石井 更紗","女","相模原SSC",0,"秋季記録会","陸上トラック","1200m","決勝","2026-11-02T10:41:00.000","0:02:59.40",1,59.80,"0:00:59.80",59.80,"0:00:59.80",400,400,24.1,"FALSE","FALSE","FALSE"\r
"20261102_1041_CH5","石井 更紗","女","相模原SSC",0,"秋季記録会","陸上トラック","1200m","決勝","2026-11-02T10:41:00.000","0:02:59.40",2,,"",118.20,"0:01:58.20",400,800,,"FALSE","FALSE","TRUE"''';

  final laps = CsvParseService.parseStopWatchLinkLogCsv(sampleLinkLogCsv);
  assertEqual('ラップ件数', laps.length, 2);

  final lap1 = laps[0];
  assertEqual('選手名 (1行目)', lap1.playerName, '石井 更紗');
  assertEqual('大会名 (1行目)', lap1.tournamentName, '秋季記録会');
  assertEqual('ラップタイム秒 (1行目)', lap1.lapSeconds, 59.80);
  assertEqual('スプリット秒 (1行目)', lap1.splitSeconds, 59.80);
  assertEqual('欠損フラグ (1行目)', lap1.isMissing, false);

  final lap2 = laps[1];
  assertEqual('押し忘れ欠損値NULL (2行目)', lap2.lapSeconds, null);
  assertEqual('押し忘れ欠損フラグ (2行目)', lap2.isMissing, true);

  // 2. WITMOTION 31列 センサーCSV テスト
  print('\n-- [2/2] WITMOTION 31列 センサーCSV パーステスト --');
  const sampleWitmotionCsv = '''\uFEFFTime,Device name,Chip Time(),Acceleration X(g),Acceleration Y(g),Acceleration Z(g),Angular velocity X(°/s),Angular velocity Y(°/s),Angular velocity Z(°/s),Angle X(°),Angle Y(°),Angle Z(°),Magnetic field X(μt),Magnetic field Y(μt),Magnetic field Z(μt),Temperature(℃),Pressure(Pa),Height(m),Longitude(),Latitude(),GPS ground speed(km),Angle of course(°),GPS height(m),Number of satellites(),Position location(),Horizontal position(),Vertical position(),Quaternions 0(),Quaternions 1(),Quaternions 2(),Quaternions 3()\r
\t2026-11-07 12:00:00.000,,	2026-11-07 12:00:00.000,0.0000,0.0000,1.0000,0.0000,0.0000,0.0000,0.000,0.000,0.000,150,200,-300,25.00,,,,,,,,,,,,,,,\r
\t2026-11-07 12:00:00.020,,	2026-11-07 12:00:00.020,0.5000,0.0000,1.0000,100.0000,0.0000,0.0000,5.000,0.000,0.000,150,200,-300,25.00,,,,,,,,,,,,,,,''';

  final sensors = CsvParseService.parseWitmotionSensorCsv(sampleWitmotionCsv);
  assertEqual('センサーレコード件数', sensors.length, 2);

  final s1 = sensors[0];
  assertEqual('経過ミリ秒 (1行目: 基準0ms)', s1.elapsedMilliseconds, 0);
  assertEqual('Z軸加速度 (1行目)', s1.accelZ, 1.0);
  assertEqual('合成G (1行目: 1.0G)', double.parse(s1.totalG.toStringAsFixed(1)), 1.0);

  final s2 = sensors[1];
  assertEqual('経過ミリ秒 (2行目: 20ms)', s2.elapsedMilliseconds, 20);
  assertEqual('X軸加速度 (2行目)', s2.accelX, 0.5);
  assertEqual('X軸角速度 (2行目)', s2.gyroX, 100.0);

  print('------------------------------------------------------');
  print('テスト結果: $passed 成功 / $failed 失敗');
  print('======================================================');

  if (failed > 0) {
    throw Exception('テスト失敗');
  }
}
