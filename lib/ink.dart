import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:xml/xml_events.dart';

import 'errors.dart';
import 'mapping.dart';

/// Конечные данные инклинометрии (одна линия)
class InkDataOneLineFinal {
  double depth;
  double angle;
  double azimuth;

  static const length = 3;

  void operator []=(final int i, final double val) {
    switch (i) {
      case 0:
        depth = val;
        break;
      case 1:
        angle = val;
        break;
      case 2:
        azimuth = val;
        break;
      default:
        throw RangeError.index(i, this, 'index', null, length);
    }
  }

  double operator [](final int i) {
    switch (i) {
      case 0:
        return depth;
      case 1:
        return angle;
      case 2:
        return azimuth;
      default:
        throw RangeError.index(i, this, 'index', null, length);
    }
  }

  /// Сохранение данных в бинарном виде
  void save(final IOSink io) {
    final bl = ByteData(8 * length);
    for (var i = 0; i < length; i++) {
      bl.setFloat64(8 * i, this[i]);
    }
    io.add(bl.buffer.asUint8List());
  }
}

/// Конечные данные инклинометрии
class SingleInkData {
  /// Путь к оригиналу файла
  final String origin;

  /// Наименование скважины
  final String well;

  /// Начальная глубина
  final double strt;

  /// Конечная глубина
  final double stop;

  /// Данные инклинометрии
  final List<InkDataOneLineFinal> data;

  SingleInkData(this.origin, this.well, this.strt, this.stop, this.data);

  /// Оператор сравнения на совпадение
  @override
  bool operator ==(dynamic other) {
    if (other is SingleInkData) {
      return well == other.well &&
          strt == other.strt &&
          stop == other.stop &&
          data.length == other.data.length;
    } else {
      return false;
    }
  }

  @override
  String toString() =>
      '[Origin: "$origin", Well: "$well", Strt: $strt, Stop: $stop, Points: ${data.length}]';

  /// Сохранение данных в бинарном виде
  void save(final IOSink io) {
    if (origin != null) {
      io.add(utf8.encoder.convert(origin));
    }
    io.add([0]);
    if (well != null) {
      io.add(utf8.encoder.convert(well));
    }
    io.add([0]);
    final bb = ByteData(20);
    bb.setFloat64(0, strt);
    bb.setFloat64(8, stop);
    bb.setUint32(16, data.length);
    io.add(bb.buffer.asUint8List());
    for (var i = 0; i < data.length; i++) {
      data[i].save(io);
    }
  }
}

/// Класс хранящий базу данных с инклинометрией
class InkDataBase {
  /// База данных, где ключём является Имя скважины
  var db = <String, List<SingleInkData>>{};

  /// Сохранение данных в бинарном виде в файл
  /// - `+{key1}{0}{listLen1}LIST{SingleInkData1}`
  /// - `+{key2}{0}{listLen2}LIST{SingleInkData2}`
  /// - `...`
  /// - `{0}`
  Future save(final String path) async {
    final io = File(path).openWrite(encoding: null, mode: FileMode.writeOnly);
    db.forEach((key, value) {
      io.add(['+'.codeUnits[0]]);
      io.add(utf8.encoder.convert(key));
      io.add([0]);
      final bb = ByteData(4);
      bb.setUint32(0, value.length);
      io.add(bb.buffer.asUint8List());
      for (final item in value) {
        item.save(io);
      }
    });
    io.add([0]);
    await io.flush();
    await io.close();
  }

  /// Загрузка бинарных данных
  Future load(final String path) async {
    final buf = await File(path).readAsBytes();
    var offset = 0;
    db.clear();
    while (buf[offset] == '+'.codeUnits[0]) {
      offset += 1;
      var iNull = 0;
      while (buf[offset + iNull] != 0) {
        iNull += 1;
      }
      final key = utf8.decoder.convert(buf.sublist(offset, offset + iNull));
      offset += iNull + 1;
      db[key] = <SingleInkData>[];
      db[key].length = ByteData.view(buf.buffer, offset, 4).getUint32(0);
      offset += 4;
      for (var i = 0; i < db[key].length; i++) {
        iNull = 0;
        while (buf[offset + iNull] != 0) {
          iNull += 1;
        }
        final origin =
            utf8.decoder.convert(buf.sublist(offset, offset + iNull));
        offset += iNull + 1;
        iNull = 0;
        while (buf[offset + iNull] != 0) {
          iNull += 1;
        }
        final well = utf8.decoder.convert(buf.sublist(offset, offset + iNull));
        offset += iNull + 1;
        final bb = ByteData.view(buf.buffer, offset, 20);
        offset += 20;
        final strt = bb.getFloat64(0);
        final stop = bb.getFloat64(8);
        final data = List<InkDataOneLineFinal>(bb.getUint32(16));
        final bl = ByteData.view(
            buf.buffer, offset, 8 * data.length * InkDataOneLineFinal.length);
        offset += 8 * data.length * InkDataOneLineFinal.length;
        for (var i = 0; i < data.length; i++) {
          for (var j = 0; j < InkDataOneLineFinal.length; j++) {
            data[i][j] =
                bl.getFloat64(8 * (i * InkDataOneLineFinal.length + j));
          }
        }
        db[key][i] = SingleInkData(origin, well, strt, stop, data);
      }
    }
  }
}

class InkData {
  /// Путь к оригиналу файла
  String origin;

  /// Название скважины
  String well;

  /// Название площади
  String square;

  /// Диаметр скважины
  String diametr;

  /// Глубина башмака
  String depth;

  /// Угол склонения (оригинальная запись)
  String angle;

  /// Флаг оригинальной записи в град'мин
  bool angleM;

  /// Угол склонения, числовое значение (в градусах и долях градуса)
  double angleN;

  /// Альтитуда
  String altitude;

  /// Глубина забоя
  String zaboy;

  final list = <InkDataLine>[];

  bool bInkFile;

  var iDepth = -1;
  var iAngle = -1;
  bool bAngleMinuts;
  var iAzimuth = -1;
  bool bAzimuthMinuts;
  var iseesoo = 0;

  /// Номер обрабатываемой строки
  ///
  /// После обработки, хранит количество строк в файле
  var lineNum = 0;

  /// Список ошибок (Если он пуст после разбора, то данные корректны)
  final listOfErrors = <ErrorOnLine>[];

  /// Функция записи ошибки (сохраняет внутри класса)
  void logError(KncError err, [String txt]) =>
      listOfErrors.add(ErrorOnLine(err, lineNum, txt));
}

class InkDataLine {
  String depth;
  double depthN;
  String angle;
  double angleN;
  String azimuth;
  double azimuthN;
}

@deprecated
class InkDataOLD {
  /// Путь к оригиналу файла
  String origin;

  /// Название скважины
  String well;

  /// Название площади
  String square;

  /// Диаметр скважины
  String diametr;

  /// Глубина башмака
  String depth;

  /// Угол склонения (оригинальная запись)
  String angle;

  /// Флаг оригинальной записи в град'мин
  bool angleM;

  /// Угол склонения, числовое значение (в градусах и долях градуса)
  double angleN;

  /// Альтитуда
  String altitude;

  /// Глубина забоя
  String zaboy;

  final list = <InkDataLine>[];

  bool bInkFile;

  var iDepth = -1;
  var iAngle = -1;
  bool bAngleMinuts;
  var iAzimuth = -1;
  bool bAzimuthMinuts;
  var iseesoo = 0;

  /// Номер обрабатываемой строки
  ///
  /// После обработки, хранит количество строк в файле
  var lineNum = 0;

  final listOfErrors = <String>[];

  /// Значение рейтинга кодировок (действительно только для текстовых файлов)
  Map<String, int> encodesRaiting;

  /// Конечная подобранная кодировка (действительно только для текстовых файлов)
  String encode;

  Future future;

  void _logErrorOLD(final String txt) {
    listOfErrors.add('Строка:$lineNum\t$txt');
  }

  void _prepareForTable1() {
    if (well != null && angle != null && altitude != null) {
      iseesoo = 10;
    }
  }

  void _prepareForStartList(final dynamic rowIn) {
    if (rowIn is List<String>) {
      final tt = rowIn;
      for (var i = 0; i < tt.length; i++) {
        if (iDepth == -1 && tt[i].startsWith('Глубина')) {
          iDepth = i;
        } else if (iAngle == -1 && tt[i].startsWith('Угол')) {
          iAngle = i;
          var k = tt[i].indexOf("'");
          if (k == -1) {
            _logErrorOLD(
                'Ненайден разделитель для значения градусов/минуты (Угол)');
          } else {
            var m = tt[i][k + 1].toLowerCase();
            switch (m) {
              case 'м':
                bAngleMinuts = true;
                break;
              case 'г':
                bAngleMinuts = false;
                break;
              default:
                _logErrorOLD(
                    'Некорректный тип для значения градусов/минуты (Угол)');
            }
          }
        } else if (iAzimuth == -1 && tt[i].startsWith('Азимут')) {
          iAzimuth = i;
          var k = tt[i].indexOf("'");
          if (k == -1) {
            _logErrorOLD(
                'Ненайден разделитель для значения градусов/минуты (Азимут)');
          } else {
            var m = tt[i][k + 1].toLowerCase();
            switch (m) {
              case 'м':
                bAzimuthMinuts = true;
                break;
              case 'г':
                bAzimuthMinuts = false;
                break;
              default:
                _logErrorOLD(
                    'Некорректный тип для значения градусов/минуты (Азимут)');
            }
          }
        }
      }
    } else if (rowIn is List<List<String>>) {
      final tt = rowIn;
      for (var i = 0; i < tt.length; i++) {
        if (iDepth == -1 && tt[i][0].startsWith('Глубина')) {
          iDepth = i;
        } else if (iAngle == -1 && tt[i][0].startsWith('Угол')) {
          iAngle = i;
          var k = tt[i][0].indexOf("'");
          if (k == -1) {
            _logErrorOLD(
                'Ненайден разделитель для значения градусов/минуты (Угол)');
          } else {
            var m = tt[i][0][k + 1].toLowerCase();
            switch (m) {
              case 'м':
                bAngleMinuts = true;
                break;
              case 'г':
                bAngleMinuts = false;
                break;
              default:
                _logErrorOLD(
                    'Некорректный тип для значения градусов/минуты (Угол)');
            }
          }
        } else if (iAzimuth == -1 && tt[i][0].startsWith('Азимут')) {
          iAzimuth = i;
          var k = tt[i][0].indexOf("'");
          if (k == -1) {
            _logErrorOLD(
                'Ненайден разделитель для значения градусов/минуты (Азимут)');
          } else {
            var m = tt[i][0][k + 1].toLowerCase();
            switch (m) {
              case 'м':
                bAzimuthMinuts = true;
                break;
              case 'г':
                bAzimuthMinuts = false;
                break;
              default:
                _logErrorOLD(
                    'Некорректный тип для значения градусов/минуты (Азимут)');
            }
          }
        }
      }
    } else {
      _logErrorOLD('Неправильный тип аргумента для функции');
    }
    if (iDepth == -1 ||
        iAngle == -1 ||
        iAzimuth == -1 ||
        bAngleMinuts == null ||
        bAzimuthMinuts == null) {
      _logErrorOLD('Не все данные корректны');
      _logErrorOLD('iDepth         = $iDepth');
      _logErrorOLD('iAngle         = $iAngle');
      _logErrorOLD('iAzimuth       = $iAzimuth');
      _logErrorOLD('bAngleMinuts   = $bAngleMinuts');
      _logErrorOLD('bAzimuthMinuts = $bAzimuthMinuts');
    }
  }

  void _parseAngle() {
    // 11.30 град'мин.
    var k = angle.indexOf("'");
    if (k == -1) {
      _logErrorOLD(
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
        _logErrorOLD(
            'Некорректный тип для значения градусов/минуты (Угол склонения)');
        return;
    }
    angleN = double.tryParse(angle.substring(0, angle.indexOf(' ')));
    if (angleN == null) {
      _logErrorOLD('Невозможно разобрать значение углас клонения: "$angle"');
      return;
    }
    if (angleM) {
      var v = (angleN % 1.0);
      angleN += (v * 10.0 / 6.0) - v;
    }
  }

  /// bytes <- Stream by File.openRead, await future for complete
  InkDataOLD.docx(final Stream<List<int>> bytes) {
    final data = [];
    String paragraph;
    List<List<List<String>>> data_tbl;

    // Скважина N 1240 Площадь Сотниковская Куст - 0
    var reL1 = RegExp(r'Скважина\s+N(.+)Площадь:?(.+)');
    //Диаметр скважины: 0.216 м. Глубина башмака кондуктора: 380.4 м.
    var reL2 = RegExp(
        r'Диаметр\s+скважины:(.+)Глубина\s+башмака(?:\s+кондуктора):?(.+)');
    // Угол склонения: 11.30 град'мин. Альтитуда: 181.96 м. Забой: 1840.0 м.
    var reL3 = RegExp(r'Угол\s+склонения:?(.+)Альтитуда:?(.+)Забой:?(.+)');

    void _parseSecondTblData(final List<List<String>> row) {
      if (listOfErrors.isNotEmpty) {
        return;
      }
      final iLengthDepth =
          row[iDepth].length - (row[iDepth].last.isEmpty ? 1 : 0);
      final iLengthAngle =
          row[iAngle].length - (row[iAngle].last.isEmpty ? 1 : 0);
      final iLengthAzimuth =
          row[iAzimuth].length - (row[iAzimuth].last.isEmpty ? 1 : 0);
      if (iLengthDepth != iLengthAngle || iLengthDepth != iLengthAzimuth) {
        _logErrorOLD('количество строк в колонках таблицы несовпадает');
        return;
      }
      for (var i = 0; i < iLengthDepth; i++) {
        lineNum = i + 1;
        var l = InkDataLine();
        l.depth = row[iDepth][i];
        l.depthN = double.tryParse(l.depth);
        if (l.depthN == null) {
          _logErrorOLD('Невозможно разобрать значение глубины');
        }
        l.angle = row[iAngle][i];
        l.angleN = double.tryParse(l.angle);
        if (l.angleN == null) {
          _logErrorOLD('Невозможно разобрать значение угла');
        } else if (bAngleMinuts) {
          var v = (l.angleN % 1.0);
          l.angleN += (v * 10.0 / 6.0) - v;
        }
        l.azimuth = row[iAzimuth][i];
        l.azimuthN = double.tryParse(
            l.azimuth[0] == '*' ? l.azimuth.substring(1) : l.azimuth);
        if (l.azimuthN == null) {
          _logErrorOLD('Невозможно разобрать значение азимута');
        } else {
          if (bAzimuthMinuts) {
            var v = (l.azimuthN % 1.0);
            l.azimuthN += (v * 10.0 / 6.0) - v;
          }
          l.azimuthN += angleN;
        }
        list.add(l);
      }
    }

    future = bytes
        .transform(Utf8Decoder(allowMalformed: true))
        .transform(XmlEventDecoder())
        .listen((events) {
      for (var event in events) {
        if (event is XmlStartElementEvent) {
          if (event.name == 'w:tbl') {
            data_tbl = <List<List<String>>>[];
            data.add(data_tbl);
            // data_tbl = data.last;

            if (iseesoo == 10) {
              iseesoo = 11;
            }
            if (iseesoo == 12) {
              iseesoo = 20;
            }
          }
          if (data_tbl == null) {
            if (event.name == 'w:p') {
              paragraph = '';
              // paragraph = '^';
              if (event.isSelfClosing) {
                // paragraph += r'$';
                data.add(paragraph);
                paragraph = null;
              }
            }
          } else {
            if (event.name == 'w:tr') {
              data_tbl.add([]);
              if (iseesoo >= 20 && iseesoo < 30) {
                iseesoo += 1;
              }
            }
            if (event.name == 'w:tc') {
              data_tbl.last.add([]);
            }
            if (event.name == 'w:p') {
              paragraph = '';
              // paragraph = '^';
              if (event.isSelfClosing) {
                // paragraph += r'$';
                data_tbl.last.last.add(paragraph);
                paragraph = null;
              }
            }
          }
        } else if (event is XmlEndElementEvent) {
          if (event.name == 'w:tbl') {
            final tblRowHeight = List.filled(data_tbl.length, 0);
            var cells_max = 0;
            for (var r in data_tbl) {
              if (cells_max < r.length) cells_max = r.length;
            }
            final tblCellWidth = List.filled(cells_max, 0);

            for (var ir = 0; ir < data_tbl.length; ir++) {
              final row = data_tbl[ir];
              for (var ic = 0; ic < row.length; ic++) {
                final cell = row[ic];
                if (tblRowHeight[ir] < cell.length) {
                  tblRowHeight[ir] = cell.length;
                }
                for (final p in cell) {
                  if (tblCellWidth[ic] < p.length) {
                    tblCellWidth[ic] = p.length;
                  }
                }
              }
            }
            data_tbl = null;
            if (iseesoo == 11) {
              iseesoo = 12;
            }
            if (iseesoo >= 20 && iseesoo < 30) {
              iseesoo = 30;
            }
          } else if (event.name == 'w:tr') {
            if (iseesoo == 21) {
              // Закончили строку заголовка второй таблицы
              _prepareForStartList(data_tbl.last);
            }
            if (iseesoo == 22) {
              // Закончили строку значений второй таблицы
              _parseSecondTblData(data_tbl.last);
            }
          }
          if (data_tbl == null) {
            if (event.name == 'w:p') {
              // paragraph += r'$';
              data.add(paragraph);
              final line = paragraph.trim();
              if (line == 'Утверждаю' ||
                  line == 'Замер кривизны' ||
                  line.startsWith('Заказчик')) {
                iseesoo += 1;
                bInkFile = iseesoo >= 2;
              } else if (iseesoo >= 2 && iseesoo < 10) {
                if (well == null) {
                  final rem = reL1.firstMatch(line);
                  if (rem != null) {
                    well = rem.group(1).trim();
                    square = rem.group(2).trim();
                    iseesoo += 1;
                    _prepareForTable1();
                  }
                }
                if (diametr == null) {
                  final rem = reL2.firstMatch(line);
                  if (rem != null) {
                    diametr = rem.group(1).trim();
                    depth = rem.group(2).trim();
                    iseesoo += 1;
                    _prepareForTable1();
                  }
                }
                if (angle == null) {
                  final rem = reL3.firstMatch(line);
                  if (rem != null) {
                    angle = rem.group(1).trim();
                    altitude = rem.group(2).trim();
                    zaboy = rem.group(3).trim();
                    _parseAngle();
                    iseesoo += 1;
                    _prepareForTable1();
                  }
                }
              }
              paragraph = null;
            }
          } else {
            if (event.name == 'w:p') {
              // paragraph += r'$';
              data_tbl.last.last.add(paragraph);
              paragraph = null;
            }
          }
        } else if (event is XmlTextEvent) {
          if (paragraph == null) {
            data.add(event.text);
          } else {
            paragraph += event.text;
          }
        }
      }
    }).asFuture(this);
  }

  InkDataOLD.txt(final UnmodifiableUint8ListView bytes,
      final Map<String, List<String>> charMaps) {
    bInkFile = false;
    // Подбираем кодировку
    encodesRaiting = Map.unmodifiable(getMappingRaitings(charMaps, bytes));
    encode = getMappingMax(encodesRaiting);
    // Преобразуем байты из кодировки в символы
    final buffer = String.fromCharCodes(bytes
        .map((i) => i >= 0x80 ? charMaps[encode][i - 0x80].codeUnitAt(0) : i));
    // Нарезаем на линии
    final lines = LineSplitter.split(buffer);

    var tbl1len = 0;
    var tbl2 = <List<String>>[];

    void parseListLine(final List<String> s) {
      var l = InkDataLine();
      l.depth = s[iDepth];
      l.depthN = double.tryParse(l.depth);
      if (l.depthN == null) {
        _logErrorOLD('Невозможно разобрать значение глубины');
      }
      l.angle = s[iAngle];
      l.angleN = double.tryParse(l.angle);
      if (l.angleN == null) {
        _logErrorOLD('Невозможно разобрать значение угла');
      } else if (bAngleMinuts) {
        var v = (l.angleN % 1.0);
        l.angleN += (v * 10.0 / 6.0) - v;
      }
      l.azimuth = s[iAzimuth];
      l.azimuthN = double.tryParse(
          l.azimuth[0] == '*' ? l.azimuth.substring(1) : l.azimuth);
      if (l.azimuthN == null) {
        _logErrorOLD('Невозможно разобрать значение азимута');
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
      } else if (line == 'Утверждаю' ||
          line == 'Замер кривизны' ||
          line.startsWith('Заказчик')) {
        iseesoo += 1;
        bInkFile = iseesoo >= 2;
        continue lineLoop;
      } else if (iseesoo >= 2 && iseesoo < 10) {
        if (well == null) {
          final rem = reL1.firstMatch(line);
          if (rem != null) {
            well = rem.group(1).trim();
            square = rem.group(2).trim();
            iseesoo += 1;
            _prepareForTable1();
            continue lineLoop;
          }
        }
        if (diametr == null) {
          final rem = reL2.firstMatch(line);
          if (rem != null) {
            diametr = rem.group(1).trim();
            depth = rem.group(2).trim();
            iseesoo += 1;
            _prepareForTable1();
            continue lineLoop;
          }
        }
        if (angle == null) {
          final rem = reL3.firstMatch(line);
          if (rem != null) {
            angle = rem.group(1).trim();
            altitude = rem.group(2).trim();
            zaboy = rem.group(3).trim();
            _parseAngle();
            iseesoo += 1;
            _prepareForTable1();
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
          for (var i = 0; i < s.length; i++) {
            s[i] = s[i].trim();
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
            _prepareForStartList(tbl2[0]);
            if (listOfErrors.isNotEmpty) {
              break lineLoop;
            }
            continue lineLoop;
          } else {
            var s = line.split('|');
            for (var i = 0; i < s.length; i++) {
              s[i] = s[i].trim();
            }
            if (s.last.isEmpty) {
              s = s.sublist(0, s.length - 1);
            }
            if (s.length != tbl2[0].length) {
              _logErrorOLD('Несовпадает количество столбцов');
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
              _logErrorOLD('Несовпадает количество столбцов');
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
