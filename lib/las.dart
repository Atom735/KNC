import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'errors.dart';
import 'mapping.dart';

/// Конечные данные одной кривой (хранятся в базе данных LAS)
class SingleCurveLasData {
  /// Путь к оригиналу файла
  final String origin;

  /// Наименование скважины
  final String well;

  /// Наименование иследования
  final String name;

  /// Начальная глубина
  final double strt;

  /// Конечная глубина
  final double stop;

  /// Данные иследования
  final List<double> data;

  /// Шаг квантования глубины
  double get step => data.length >= 2 ? (stop - strt) / (data.length - 1) : 0;

  SingleCurveLasData(
      this.origin, this.well, this.name, this.strt, this.stop, this.data);

  /// Получить данные с помощью разобранных LAS данных файла
  static List<SingleCurveLasData> getByLasData(final LasData las) {
    final cs = las.curves;
    final cc = cs.length - 1;
    final out = List<SingleCurveLasData>(cc);
    for (var i = 0; i < cc; i++) {
      final ci = cs[i + 1];
      final data = List<double>(ci.stopI - ci.strtI + 1);
      for (var j = 0; j < data.length; j++) {
        data[j] = las.ascii[j + ci.strtI][i + 1];
      }
      out[i] = SingleCurveLasData(
          las.origin, las.wWell, ci.mnem, ci.strtN, ci.stopN, data);
    }
    return out;
  }

  /// Оператор сравнения на совпадение
  @override
  bool operator ==(dynamic other) {
    if (other is SingleCurveLasData) {
      return well == other.well &&
          name == other.name &&
          strt == other.strt &&
          stop == other.stop &&
          data.length == other.data.length;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    var str = '';
    if (origin != null) {
      str += 'origin: "$origin";';
    }
    if (well != null) {
      str += 'well: "$well";';
    }
    if (name != null) {
      str += 'name: "$name";';
    }
    return '[$str]';
  }

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
    if (name != null) {
      io.add(utf8.encoder.convert(name));
    }
    io.add([0]);
    final bb = ByteData(20);
    bb.setFloat64(0, strt);
    bb.setFloat64(8, stop);
    bb.setUint32(16, data.length);
    io.add(bb.buffer.asUint8List());
    final bl = ByteData(8 * data.length);
    for (var i = 0; i < data.length; i++) {
      bl.setFloat64(8 * i, data[i]);
    }
    io.add(bl.buffer.asUint8List());
  }
}

/// Класс хранящий базу данных LAS
class LasDataBase {
  /// База данных, где ключём является Имя скважины
  var db = <String, List<SingleCurveLasData>>{};

  /// `+{key}{0}{listLen}LIST{SingleCurveLasData}`
  /// ...
  /// Сохранение данных в бинарном виде в файл
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
      db[key] = <SingleCurveLasData>[];
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
        iNull = 0;
        while (buf[offset + iNull] != 0) {
          iNull += 1;
        }
        final name = utf8.decoder.convert(buf.sublist(offset, offset + iNull));
        offset += iNull + 1;
        final bb = ByteData.view(buf.buffer, offset, 20);
        offset += 20;
        final strt = bb.getFloat64(0);
        final stop = bb.getFloat64(8);
        final data = List<double>(bb.getUint32(16));
        final bl = ByteData.view(buf.buffer, offset, 8 * data.length);
        offset += 8 * data.length;
        for (var i = 0; i < data.length; i++) {
          data[i] = bl.getFloat64(8 * i);
        }
        db[key][i] = SingleCurveLasData(origin, well, name, strt, stop, data);
      }
    }
  }

  /// Добавляет данные LAS файла в базу,
  /// если такие данные уже имеются
  /// то функция вернёт количество совпадений
  ///
  /// Кол-во совпадений можно сравнить с `LasData.curves.length - 1`
  /// Если их меньше, то выборочные данные были добавлены
  int addLasData(final LasData las) {
    final list = SingleCurveLasData.getByLasData(las);
    if (db[las.wWell] == null) {
      db[las.wWell] = [];
      db[las.wWell].addAll(list);
      return 0;
    } else {
      /// Флаг уникальности данных
      var b = 0;
      for (var scld in list) {
        var bk = true;
        for (var scdb in db[las.wWell]) {
          if (scdb == scld) {
            // Если совпадают
            b += 1;
            bk = false;
          }
        }
        if (bk) {
          db[las.wWell].add(scld);
        }
      }
      return b;
    }
  }
}

/// Данные строки LAS файла
class LasDataInfoLine {
  /// Мнемоника
  final String mnem;

  /// Размерность данных
  final String unit;

  /// Данные
  final String data;

  /// Описание данных
  final String desc;

  LasDataInfoLine(this.mnem, this.unit, this.data, this.desc);
  LasDataInfoLine.fromList(final List<String> list)
      : mnem = list[0],
        unit = list[1],
        data = list[2],
        desc = list[3];
  String operator [](final int i) => i == 0
      ? mnem
      : i == 1
          ? unit
          : i == 2
              ? data
              : i == 3
                  ? desc
                  : throw RangeError.index(i, this, 'index', null, 4);
}

/// Данные о кривой LAS файла
///
/// Наименование кривой хранится в переменной `mnem`
class LasDataCurve extends LasDataInfoLine {
  /// Начальная глубина (оригинальная запись)
  String strt;

  /// Начальная глубина (числовое значение)
  double strtN;

  /// Конечная глубина (оригинальная запись)
  String stop;

  /// Конечная глубина (числовое значение)
  double stopN;

  /// Индекс начальной глубины в таблице значений `curves` из `LasData`
  int strtI;

  /// Индекс конечной глубины в таблице значений `curves` из `LasData`
  int stopI;

  LasDataCurve(final String mnem, final String unit, final String data,
      final String desc)
      : super(mnem, unit, data, desc);
  LasDataCurve.fromList(final List<String> list) : super.fromList(list);
}

class LasData {
  /// Путь к оригиналу файла
  String origin;

  /// Данные секций
  ///
  /// `info['W']['WELL']` - значение поля WELL в секции ~W
  final info = <String, Map<String, LasDataInfoLine>>{};

  /// Данные о кривых LAS файла, ну или секции ~C
  final curves = <LasDataCurve>[];

  /// Числовые данные самих кривых
  ///
  /// `ascii[0]` - данные глубины (Обычно)
  final ascii = <List<double>>[];

  /// Значение рейтинга кодировок
  Map<String, int> encodesRaiting;

  /// Конечная подобранная кодировка
  String encode;

  /// Флаг переноса строки для ascii данных
  bool zWrap;

  /// Версия LAS файла
  String vVers;

  /// Флаг переноса строки для ascii данных (Оригинальная запись)
  String vWrap;

  /// Значение отсуствующих данных (Оригинальная запись)
  String wNull;

  /// Значение отсуствующих данных (Числовое значение)
  double wNullN;

  /// Значение начальной глубины (Оригинальная запись)
  String wStrt;

  /// Значение начальной глубины (Числовое значение)
  double wStrtN;

  /// Значение конечной глубины (Оригинальная запись)
  String wStop;

  /// Значение конечной глубины (Числовое значение)
  double wStopN;

  /// Шаг квантования глубины (Оригинальная запись)
  String wStep;

  /// Шаг квантования глубины (Числовое значение)
  double wStepN;

  /// Наименование скважины
  String wWell;

  /// Номер обрабатываемой строки
  ///
  /// После обработки, хранит количество строк в файле
  var lineNum = 0;

  /// Список ошибок (Если он пуст после разбора, то данные корректны)
  final listOfErrors = <ErrorOnLine>[];

  /// Функция записи ошибки (сохраняет внутри класса)
  void _logError(KncError err, [String txt]) =>
      listOfErrors.add(ErrorOnLine(err, lineNum, txt));

  /// Разбор LAS файла и преобразование к внутреннему преставлению
  /// * [bytes] - данные файла в байтовом представлении
  /// * [charMaps] - доступные кодировки
  /// * [mapIgnore] (opt) - Таблица шаблонных значений
  LasData(final UnmodifiableUint8ListView bytes,
      final Map<String, List<String>> charMaps,
      [dynamic mapIgnore]) {
    // Подбираем кодировку
    encodesRaiting = getMappingRaitings(charMaps, bytes);
    encode = getMappingMax(encodesRaiting);
    // Преобразуем байты из кодировки в символы
    final buffer = String.fromCharCodes(bytes
        .map((i) => i >= 0x80 ? charMaps[encode][i - 0x80].codeUnitAt(0) : i));

    // Нарезаем на линии
    final lines = LineSplitter.split(buffer);

    var lastLine;

    var iA = 0;
    var section = '';

    /// Обработка начала секции
    bool startSection() {
      switch (section) {
        case 'A': // ASCII Log data
          if (listOfErrors.isNotEmpty) {
            _logError(KncError.lasErrorsNotEmpty);
            return true;
          } else if (vVers == null ||
              vWrap == null ||
              wNull == null ||
              wNullN == null ||
              wStrt == null ||
              wStrtN == null ||
              wStop == null ||
              wStopN == null ||
              wStep == null ||
              wStepN == null ||
              wWell == null) {
            _logError(KncError.lasAllDataNotCorrect);
            if (wWell == null) {
              _logError(KncError.lasCantGetWell);
            }
            return true;
          }
          return false;
        case 'C': // ~Curve information
        case 'O': // ~Other information
        case 'P': // ~Parameter information
        case 'V': // ~Version information
        case 'W': // ~Well information
          info[section] = {};
          return false;
        default:
          _logError(KncError.lasUnknownSection, lastLine);
          return true;
      }
    }

    /// Обработка линии с данными
    bool parseAsciiLine(final String line) {
      // Нарезаем строку с помощью пробелов
      for (final e in line.split(' ')) {
        if (e.isNotEmpty) {
          // Непустую строку пытаемся разобрать на число
          var val = double.tryParse(e);
          if (val == null) {
            _logError(KncError.lasNumberParseError, e);
            return true;
          }
          if (zWrap == false && iA >= curves.length) {
            _logError(KncError.lasTooManyNumbers);
            return true;
          }
          if (iA == 0) {
            ascii.add(List<double>(curves.length));
          }
          ascii.last[iA] = val;
          if (val != wNullN) {
            if (iA == 0) {
              // Depth
              if (curves[iA].strt == null) {
                curves[iA].strtI = ascii.length - 1;
                curves[iA].strt = e;
                curves[iA].strtN = val;
              }
              curves[iA].stopI = ascii.length - 1;
              curves[iA].stop = e;
              curves[iA].stopN = val;
            } else {
              // Not Depth
              if (curves[iA].strt == null) {
                curves[iA].strtI = ascii.length - 1;
                curves[iA].strt = curves[0].stop;
                curves[iA].strtN = curves[0].stopN;
              }
              curves[iA].stopI = ascii.length - 1;
              curves[iA].stop = curves[0].stop;
              curves[iA].stopN = curves[0].stopN;
            }
          }
          iA += 1;
          if (zWrap == true && iA >= curves.length) {
            iA = 0;
          }
        }
      }

      if (zWrap == false) {
        if (iA == curves.length) {
          iA = 0;
        } else {
          _logError(KncError.lasTooManyNumbers);
          return true;
        }
      }
      return false;
    }

    /// Разбор строки секции с информации
    bool parseLine(final String line) {
      if (section.isEmpty) {
        _logError(KncError.lasSectionIsNull, lastLine);
        return true;
      }
      final i0 = line.indexOf('.');
      if (i0 == -1) {
        _logError(KncError.lasHaventDot, lastLine);
        return false;
      }
      final i1 = line.lastIndexOf(':');
      if (i1 == -1) {
        _logError(KncError.lasHaventDoubleDot, lastLine);
        return false;
      }
      final i2 = line.indexOf(' ', i0);
      if (i2 == -1) {
        _logError(KncError.lasHaventSpaceAfterDot, lastLine);
        return false;
      }
      if (i1 < i2) {
        _logError(KncError.lasDotAfterDoubleDot, lastLine);
        return false;
      }
      final mnem = line.substring(0, i0).trim();
      final unit = line.substring(i0 + 1, i2).trim();
      var data = line.substring(i2 + 1, i1).trim();
      var desc = line.substring(i1 + 1).trim();
      if (section != 'C') {
        info[section][mnem] = LasDataInfoLine(mnem, unit, data, desc);
        if (mapIgnore != null && mapIgnore['$section~$mnem'] != null) {
          if (mapIgnore['$section~$mnem'].contains(data)) {
            data = desc;
            desc = null;
          }
          if (mapIgnore['$section~$mnem'].contains(data)) {
            data = null;
          }
        }
      }
      switch (section) {
        case 'V':
          switch (mnem) {
            case 'VERS':
              vVers = data;
              if (unit.isNotEmpty) {
                _logError(KncError.lasHaventSpaceAfterDot, lastLine);
              }
              if (vVers != '1.20' && vVers != '2.0') {
                _logError(KncError.lasVersionError, lastLine);
                vVers = null;
              }
              return false;
            case 'WRAP':
              vWrap = data;
              if (unit.isNotEmpty) {
                _logError(KncError.lasHaventSpaceAfterDot, lastLine);
              }
              if (vWrap != 'YES' && vWrap != 'NO') {
                _logError(KncError.lasLineWarpError, lastLine);
                vWrap = null;
              }
              zWrap = vWrap == 'YES';
              return false;
            default:
              _logError(KncError.lasUncknownMnemInVSection, lastLine);
              return false;
          }
          break;
        case 'W':
          switch (mnem) {
            case 'NULL':
              wNull = data;
              if (wNull == null) {
                _logError(KncError.lasEmptyData, lastLine);
                return false;
              }
              wNullN = double.tryParse(wNull);
              if (wNullN == null) {
                _logError(KncError.lasUncorrectNumber, wNull);
                return false;
              }
              return false;
            case 'STEP':
              wStep = data;
              if (wStep == null) {
                _logError(KncError.lasEmptyData, lastLine);
                return false;
              }
              wStepN = double.tryParse(wStep);
              if (wStepN == null) {
                _logError(KncError.lasUncorrectNumber, wStep);
                return false;
              }
              return false;
            case 'STRT':
              wStrt = data;
              if (wStrt == null) {
                _logError(KncError.lasEmptyData, lastLine);
                return false;
              }
              wStrtN = double.tryParse(wStrt);
              if (wStrtN == null) {
                _logError(KncError.lasUncorrectNumber, wStrt);
                return false;
              }
              return false;
            case 'STOP':
              wStop = data;
              if (wStop == null) {
                _logError(KncError.lasEmptyData, lastLine);
                return false;
              }
              wStopN = double.tryParse(wStop);
              if (wStopN == null) {
                _logError(KncError.lasUncorrectNumber, wStop);
                return false;
              }
              return false;
            case 'WELL':
              wWell = data;
              if (wWell == null) {
                _logError(KncError.lasCantGetWell, lastLine);
                return false;
              }
              return false;
            default:
              return false;
          }
          break;
        case 'C':
          curves.add(LasDataCurve(mnem, unit, data, desc));
          break;
      }

      return false;
    }

    /// цикл разбора строк
    lineLoop:
    for (final lineFull in lines) {
      lastLine = lineFull;
      lineNum += 1;
      final line = lineFull.trim();
      if (line.isEmpty || line.startsWith('#')) {
        // Пустую строку и строк с комментарием пропускаем
        continue lineLoop;
      } else if (section == 'A') {
        // ASCII Log Data Section
        if (parseAsciiLine(line)) {
          break lineLoop;
        } else {
          continue lineLoop;
        }
      } else if (line.startsWith('~')) {
        // Заголовок секции
        section = line[1];
        if (startSection()) {
          break lineLoop;
        } else {
          continue lineLoop;
        }
      } else {
        if (parseLine(line)) {
          break lineLoop;
        } else {
          continue lineLoop;
        }
      }
    }
  }
}
