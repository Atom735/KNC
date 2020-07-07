import 'dart:convert';
import 'dart:typed_data';

import 'mapping.dart';

class InkDataLine {
  String depth;
  double depthN;
  String angle;
  double angleN;
  String azimuth;
  double azimuthN;
}

class InkData {
  String well;
  String square;
  String diametr;
  String depth;
  String angle;
  double angleN;
  bool angleM;
  String altitude;
  String zaboy;
  final list = <InkDataLine>[];
  final listOfErrors = <String>[];
  Map<String, int> encodesRaiting;
  String encode;

  InkData.txt(final UnmodifiableUint8ListView bytes,
      final Map<String, List<String>> charMaps) {
    // Подбираем кодировку
    encodesRaiting = Map.unmodifiable(getMappingRaitings(charMaps, bytes));
    encode = getMappingMax(encodesRaiting);
    // Преобразуем байты из кодировки в символы
    final buffer = String.fromCharCodes(bytes
        .map((i) => i >= 0x80 ? charMaps[encode][i - 0x80].codeUnitAt(0) : i));
    // Нарезаем на линии
    final lines = LineSplitter.split(buffer);
    var lineNum = 0;

    void logError(final String txt) {
      listOfErrors.add('${listOfErrors.length}\tСтрока:$lineNum\t$txt');
    }

    var iseesoo = 0;
    var tbl1len = 0;
    var tbl2 = <List<String>>[];

    var iDepth = -1;
    var iAngle = -1;
    bool bAngleMinuts;
    var iAzimuth = -1;
    bool bAzimuthMinuts;

    void prepareForTable1() {
      if (well != null && angle != null && altitude != null) {
        iseesoo = 10;
      }
    }

    void parseAngle() {
      // 11.30 град'мин.
      var k = angle.indexOf("'");
      if (k == -1) {
        logError(
            'Ненайден разделитель для значения градусов/минуты (Угол склонения)');
        return;
      }
      switch (angle[k + 1].toLowerCase()) {
        case 'м':
          angleM = true;
          break;
        case 'г':
          angleM = false;
          break;
        default:
          logError(
              'Некорректный тип для значения градусов/минуты (Угол склонения)');
          return;
      }
      angleN = double.tryParse(angle);
      if (angleN == null) {
        logError('Невозможно разобрать значение углас клонения: "$angle"');
        return;
      }
      if (angleM) {
        var v = (angleN % 1.0);
        angleN += (v * 10.0 / 6.0) - v;
      }
    }

    void prepareForStartList() {
      for (var i = 0; i < tbl2[0].length; i++) {
        if (iDepth == -1 && tbl2[0][i].startsWith('Глубина')) {
          iDepth = i;
        } else if (iAngle == -1 && tbl2[0][i].startsWith('Угол')) {
          iAngle = i;
          var k = tbl2[0][i].indexOf("'");
          if (k == -1) {
            logError(
                'Ненайден разделитель для значения градусов/минуты (Угол)');
          } else {
            var m = tbl2[0][i][k + 1].toLowerCase();
            switch (m) {
              case 'м':
                bAngleMinuts = true;
                break;
              case 'г':
                bAngleMinuts = false;
                break;
              default:
                logError(
                    'Некорректный тип для значения градусов/минуты (Угол)');
            }
          }
        } else if (iAzimuth == -1 && tbl2[0][i].startsWith('Азимут')) {
          iAzimuth = i;
          var k = tbl2[0][i].indexOf("'");
          if (k == -1) {
            logError(
                'Ненайден разделитель для значения градусов/минуты (Азимут)');
          } else {
            var m = tbl2[0][i][k + 1].toLowerCase();
            switch (m) {
              case 'м':
                bAzimuthMinuts = true;
                break;
              case 'г':
                bAzimuthMinuts = false;
                break;
              default:
                logError(
                    'Некорректный тип для значения градусов/минуты (Азимут)');
            }
          }
        }
      }
      if (iDepth == -1 ||
          iAngle == -1 ||
          iAzimuth == -1 ||
          bAngleMinuts == null ||
          bAzimuthMinuts == null) {
        logError('Не все данные корректны');
        logError('iDepth         = $iDepth');
        logError('iAngle         = $iAngle');
        logError('iAzimuth       = $iAzimuth');
        logError('bAngleMinuts   = $bAngleMinuts');
        logError('bAzimuthMinuts = $bAzimuthMinuts');
      }
    }

    void parseListLine(final List<String> s) {
      var l = InkDataLine();
      l.depth = s[iDepth];
      l.depthN = double.tryParse(l.depth);
      if (l.depthN == null) {
        logError('Невозможно разобрать значение глубины');
      }
      l.angle = s[iAngle];
      l.angleN = double.tryParse(l.angle);
      if (l.angleN == null) {
        logError('Невозможно разобрать значение угла');
      } else if (bAngleMinuts) {
        var v = (l.angleN % 1.0);
        l.angleN += (v * 10.0 / 6.0) - v;
      }
      l.azimuth = s[iAzimuth];
      l.azimuthN = double.tryParse(
          l.azimuth[0] == '*' ? l.azimuth.substring(1) : l.azimuth);
      if (l.azimuthN == null) {
        logError('Невозможно разобрать значение азимута');
      } else {
        if (bAzimuthMinuts) {
          var v = (l.azimuthN % 1.0);
          l.azimuthN += (v * 10.0 / 6.0) - v;
        }
        l.azimuthN += angleN;
      }
      list.add(l);
    }

    var reL1 = RegExp(r'Скважина\s+N(.+)Площадь:(.+)');
    var reL2 = RegExp(r'Диаметр\s+скважины:(.+)Глубина\s+башмака:(.+)');
    var reL3 = RegExp(r'Угол\s+склонения:(.+)Альтитуда:(.+)Забой:(.+)');

    lineLoop:
    for (final lineFull in lines) {
      lineNum += 1;
      final line = lineFull.trim();
      if (line.isEmpty) {
        // Пустую строку и строк с комментарием пропускаем
        continue lineLoop;
      } else if (line == 'Утверждаю') {
        iseesoo += 1;
        continue lineLoop;
      } else if (line == 'Замер кривизны') {
        iseesoo += 1;
        continue lineLoop;
      } else if (line.startsWith('Заказчик')) {
        iseesoo += 1;
        continue lineLoop;
      } else if (iseesoo >= 2 && iseesoo < 10) {
        if (well == null) {
          final rem = reL1.firstMatch(line);
          if (rem != null) {
            well = rem.group(1).trim();
            square = rem.group(2).trim();
            iseesoo += 1;
            prepareForTable1();
            continue lineLoop;
          }
        }
        if (diametr == null) {
          final rem = reL2.firstMatch(line);
          if (rem != null) {
            diametr = rem.group(1).trim();
            depth = rem.group(2).trim();
            iseesoo += 1;
            prepareForTable1();
            continue lineLoop;
          }
        }
        if (angle == null) {
          final rem = reL3.firstMatch(line);
          if (rem != null) {
            angle = rem.group(1).trim();
            altitude = rem.group(2).trim();
            zaboy = rem.group(3).trim();
            parseAngle();
            iseesoo += 1;
            prepareForTable1();
            continue lineLoop;
          }
        }
      } else if (iseesoo == 10) {
        if (line.startsWith('----')) {
          tbl1len = line.length;
          iseesoo = 11;
          continue lineLoop;
        }
        continue lineLoop;
      } else if (iseesoo >= 11 && iseesoo < 20) {
        if (line.startsWith('----')) {
          if (tbl1len == line.length) {
            iseesoo += 1;
            continue lineLoop;
          } else {
            iseesoo = 20;
            continue lineLoop;
          }
        }
        continue lineLoop;
      } else if (iseesoo >= 20) {
        if (iseesoo == 20) {
          var s = line.split('|');
          for (var i in s) {
            i = i.trim();
          }
          if (s.last.isEmpty) {
            s = s.sublist(0, s.length - 1);
          }
          tbl2.add(s);
          iseesoo += 1;
          continue lineLoop;
        } else if (iseesoo == 21) {
          if (line.startsWith('----')) {
            iseesoo += 1;
            prepareForStartList();
            if (listOfErrors.isNotEmpty) {
              break lineLoop;
            }
            continue lineLoop;
          } else {
            var s = line.split('|');
            for (var i in s) {
              i = i.trim();
            }
            if (s.last.isEmpty) {
              s = s.sublist(0, s.length - 1);
            }
            if (s.length != tbl2[0].length) {
              logError('Несовпадает количество столбцов');
              break lineLoop;
            }
            for (var i = 0; i < s.length; i++) {
              var v = s[i].trim();
              if (v.isNotEmpty) {
                tbl2[0][i] += ' ' + v;
              }
            }
            continue lineLoop;
          }
        } else if (iseesoo == 22) {
          if (line.startsWith('----')) {
            iseesoo = 30;
            break lineLoop;
          } else {
            var s = line.split(' ');
            s.removeWhere((e) => e.isEmpty);
            if (s.length != tbl2[0].length) {
              logError('Несовпадает количество столбцов');
              break lineLoop;
            }
            tbl2.add(s);
            parseListLine(s);
            continue lineLoop;
          }
        }
        continue lineLoop;
      } else {
        continue lineLoop;
      }
    }
  }
}
