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
  String altitude;
  String zaboy;
  List<InkDataLine> list;
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

    var reL1 = RegExp(r'Скважина\s+N(.+)Площадь:(.+)');
    var reL2 = RegExp(r'Диаметр\s+скважины:(.+)Глубина\s+башмака:(.+)');
    var reL3 = RegExp(r"Угол\s+склонения:(.+)Альтитуда:(.+)Забой:(.+)");

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
      } else if (line.startsWith('Заказчик.')) {
        iseesoo += 1;
        continue lineLoop;
      } else if (iseesoo >= 2) {
      } else {
        if (well == null) {
          final rem = reL1.firstMatch(line);
          if (rem != null) {
            well = rem.group(1);
            square = rem.group(2);
            continue lineLoop;
          }
        }
        if (diametr == null) {
          final rem = reL2.firstMatch(line);
          if (rem != null) {
            diametr = rem.group(1);
            depth = rem.group(2);
            continue lineLoop;
          }
        }
        if (angle == null) {
          final rem = reL3.firstMatch(line);
          if (rem != null) {
            angle = rem.group(1);
            altitude = rem.group(2);
            zaboy = rem.group(3);
            continue lineLoop;
          }
        }
        continue lineLoop;
      }
    }
  }
}
