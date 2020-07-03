import 'dart:convert';
import 'dart:typed_data';

import 'mapping.dart';

class LasDataInfoLine {
  final String mnem;
  final String unit;
  final String data;
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

class LasDataCurve extends LasDataInfoLine {
  String strt;
  String stop;
  double strtN;
  double stopN;

  LasDataCurve(final String mnem, final String unit, final String data,
      final String desc)
      : super(mnem, unit, data, desc);
  LasDataCurve.fromList(final List<String> list) : super.fromList(list);
}

class LasData {
  final info = <String, Map<String, LasDataInfoLine>>{};
  final curves = <LasDataCurve>[];
  final ascii = <List<double>>[];
  final listOfErrors = <String>[];
  Map<String, int> encodesRaiting;
  String encode;
  bool zWrap;

  LasData(final UnmodifiableUint8ListView bytes,
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

    @deprecated
    String vVers;
    @deprecated
    String vWrap;
    @deprecated
    String wNull;
    @deprecated
    double wNullN;
    @deprecated
    String wStrt;
    @deprecated
    double wStrtN;
    @deprecated
    String wStop;
    @deprecated
    double wStopN;
    @deprecated
    String wStep;
    @deprecated
    double wStepN;
    @deprecated
    String wWell;
    @deprecated
    final methods = <String>[];
    @deprecated
    List<String> methodsStrt;
    @deprecated
    List<double> methodsStrtN;
    @deprecated
    List<String> methodsStop;
    @deprecated
    List<double> methodsStopN;

    var iA = 0;
    var section = '';

    bool parseAsciiLine(final String line) {
      for (final e in line.split(' ')) {
        if (e.isNotEmpty) {
          var val = double.tryParse(e);
          if (val == null) {
            logError(r'Ошибка в разборе числа');
            return true;
          }
          if (!zWrap && iA >= curves.length) {
            logError(r'Слишком много чисел в линии');
            return true;
          }
          if (val != wNullN) {
            if (iA == 0) {
              // Depth
              if (curves[iA].strt == null) {
                curves[iA].strt = e;
                curves[iA].strtN = val;
              }
              curves[iA].stop = e;
              curves[iA].stopN = val;
            } else {
              if (curves[iA].strt == null) {
                curves[iA].strt = curves[0].stop;
                curves[iA].strtN = curves[0].stopN;
              }
              curves[iA].stop = curves[0].stop;
              curves[iA].stopN = curves[0].stopN;
            }
          }
          iA += 1;
          if (vWrap == 'YES' && iA >= curves.length) {
            iA = 0;
          }
        }
      }

      if (vWrap == 'NO') {
        if (iA == curves.length) {
          iA = 0;
        } else {
          logError(r'Ошибка в количестве чисел в линии');
          return true;
        }
      }
      return false;
    }

    bool startSection() {
      switch (section) {
        case 'A': // ASCII Log data
          if (listOfErrors.isNotEmpty) {
            logError(r'Невозможно перейти к разбору ASCII данных с ошибками');
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
            logError(r'Не все данные корректны для продолжения парсинга');
            logError('Vers  === $vVers');
            logError('Wrap  === $vWrap');
            logError('Null  === $wNull');
            logError('NullN === $wNullN');
            logError('Strt  === $wStrt');
            logError('StrtN === $wStrtN');
            logError('Stop  === $wStop');
            logError('StopN === $wStopN');
            logError('Step  === $wStep');
            logError('StepN === $wStepN');
            logError('Well  === $wWell');
            return true;
          }
          methodsStrt = List(methods.length);
          methodsStrtN = List(methods.length);
          methodsStop = List(methods.length);
          methodsStopN = List(methods.length);
          return false;
        case 'C': // ~Curve information
        case 'O': // ~Other information
        case 'P': // ~Parameter information
        case 'V': // ~Version information
        case 'W': // ~Well information
          return false;
        default:
          logError(r'Неизвестная секция');
          return true;
      }
      return false;
    }

    bool parseLine(final String line) {
      if (section.isEmpty) {
        logError(r'Отсутсвует секция');
        return true;
      }
      final i0 = line.indexOf('.');
      if (i0 == -1) {
        logError(r'Отсутсвует точка');
        return false;
      }
      // if (line.contains('.', i0 + 1)) {
      //   logError(r'Две точки на линии');
      //   return false;
      // }
      final i1 = line.lastIndexOf(':');
      if (i1 == -1) {
        logError(r'Отсутсвует двоеточие');
        return false;
      }
      // if (line.contains(':', i1 + 1)) {
      //   logError(r'Два двоеточия на линии');
      //   return false;
      // }
      final i2 = line.indexOf(' ', i0);
      final mnem = line.substring(0, i0).trim();
      final unit = line.substring(i0 + 1, i2).trim();
      final data = line.substring(i2 + 1, i1).trim();
      final desc = line.substring(i1 + 1).trim();
      switch (section) {
        case 'V':
          switch (mnem) {
            case 'VERS':
              vVers = data;
              if (unit.isNotEmpty) {
                logError(r'После точки должен быть пробел');
              }
              if (vVers != '1.20' && vVers != '2.0') {
                logError(r'Ошибка в версии файла');
                vVers = null;
              }
              return false;
            case 'WRAP':
              vWrap = data;
              if (unit.isNotEmpty) {
                logError(r'После точки должен быть пробел');
              }
              if (vWrap != 'YES' && vWrap != 'NO') {
                logError(r'Ошибка в значении многострочности');
                vWrap = null;
              }
              return false;
            default:
              logError(r'Неизвестная мнемоника в секции ~V');
              return false;
          }
          break;
        case 'W':
          switch (mnem) {
            case 'NULL':
              wNull = data;
              wNullN = double.tryParse(wNull);
              if (wNullN == null) {
                logError(r'Некорректное число');
              }
              return false;
            case 'STEP':
              wStep = data;
              wStepN = double.tryParse(wStep);
              if (wStepN == null) {
                logError(r'Некорректное число');
              }
              return false;
            case 'STRT':
              wStrt = data;
              wStrtN = double.tryParse(wStrt);
              if (wStrtN == null) {
                logError(r'Некорректное число');
              }
              return false;
            case 'STOP':
              wStop = data;
              wStopN = double.tryParse(wStop);
              if (wStopN == null) {
                logError(r'Некорректное число');
              }
              return false;
            case 'WELL':
              wWell = data;
              if (wWell.isEmpty || wWell == 'WELL') {
                wWell = desc;
              }
              if (wWell.isEmpty ||
                  [
                    'WELL',
                    'WELL NAME',
                    'WELL NUMBER',
                    'Well',
                    'Well name',
                    'Наименование скважины',
                    'Нет поля СКВАЖИН',
                    'Номер скважины',
                    'СКВ№',
                    'Скважина',
                    'скважина'
                  ].contains(wWell)) {
                logError(r'Невозможно получить номер скважины по полю WELL');
                wWell = null;
              }
              return false;
            default:
              return false;
          }
          break;
        case 'C':
          methods.add(mnem);
          break;
      }

      return false;
    }

    lineLoop:
    for (final lineFull in lines) {
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

void getLasData(final UnmodifiableUint8ListView bytes,
    final Map<String, List<String>> charMaps) {
  // Подбираем кодировку
  final cp = getMappingMax(getMappingRaitings(charMaps, bytes));
  final buffer = String.fromCharCodes(
      bytes.map((i) => i >= 0x80 ? charMaps[cp][i - 0x80].codeUnitAt(0) : i));
  // Нарезаем на линии
  final lines = LineSplitter.split(buffer);
  var lineNum = 0;
  final listOfErrors = <String>[];
  final data = <String, dynamic>{};

  const dataInfoExample = {
    '~V': {
      'VERS': ['', '2.0', 'CWLS LAS  -  VERSION 2.0'],
      'WRAP': ['', 'NO', 'One line per depth step'],
    },
    '~W': {
      'STRT': ['M', '1060.0', 'First depth in file'],
      'STOP': ['M', '1363.0', 'Last  depth in file'],
      'STEP': ['M', '0.2', 'Last  depth in file'],
      'NULL': ['M', '-9999.0', 'Null  values'],
      'WELL': ['', '2251_NC', 'WELL'],
    },
    '~C': {
      'DEPTH': ['M', '', 'Depth curve'],
      'ILDskin': ['Ohmm', '', 'Induction log Deep zonde'],
    },
  };

  // final dataLine = {
  //   'mnem': 'STRT',
  //   'unit': 'M',
  //   'data': '1060.0',
  //   'desc': 'First depth in file'
  // };

  String vVers;
  String vWrap;
  String wNull;
  double wNullN;
  String wStrt;
  double wStrtN;
  String wStop;
  double wStopN;
  String wStep;
  double wStepN;
  String wWell;
  final methods = <String>[];
  List<String> methodsStrt;
  List<double> methodsStrtN;
  List<String> methodsStop;
  List<double> methodsStopN;

  void logError(final String txt) {
    // if (iErrors == 0) {
    //   iso.iErrors += 1;
    //   iso.fErrors.writeln(file);
    //   final newPath = iso.pathOut + '/errors/${iso.id}/${iso.iErrors}.las';
    //   iso.fErrors.writeln('\t$newPath');
    //   futureCopyFile = file.copy(newPath);
    // }
    // iErrors += 1;
    // iso.fErrors.writeln('\t[$iErrors]\tСтрока:$lineNum\t$txt');
  }

  var section = '';

  var iA = 0;
  lineLoop:
  for (final lineFull in lines) {
    lineNum += 1;
    final line = lineFull.trim();
    if (line.isEmpty || line.startsWith('#')) {
      // Пустую строку и строк с комментарием пропускаем
      continue lineLoop;
    } else if (section == 'A') {
      // ASCII Log Data Section

      for (final e in line.split(' ')) {
        if (e.isNotEmpty) {
          var val = double.tryParse(e);
          if (val == null) {
            logError(r'Ошибка в разборе числа');
            break lineLoop;
          }
          if (vWrap == 'NO' && iA >= methods.length) {
            logError(r'Слишком много чисел в линии');
            break lineLoop;
          }
          if (val != wNullN) {
            if (iA != 0) {
              if (methodsStrt[iA] == null) {
                methodsStrt[iA] = methodsStop[0];
                methodsStrtN[iA] = methodsStopN[0];
              }
              methodsStop[iA] = methodsStop[0];
              methodsStopN[iA] = methodsStopN[0];
            } else {
              if (methodsStrt[iA] == null) {
                methodsStrt[iA] = e;
                methodsStrtN[iA] = val;
              }
              methodsStop[iA] = e;
              methodsStopN[iA] = val;
            }
          }
          iA += 1;
          if (vWrap == 'YES' && iA >= methods.length) {
            iA = 0;
          }
        }
      }

      if (vWrap == 'NO') {
        if (iA == methods.length) {
          iA = 0;
        } else {
          logError(r'Ошибка в количестве чисел в линии');
          break lineLoop;
        }
      }

      continue lineLoop;
    } else if (line.startsWith('~')) {
      // Заголовок секции
      section = line[1];
      switch (section) {
        case 'A': // ASCII Log data
          if (listOfErrors.isNotEmpty) {
            break lineLoop;
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
            logError(r'Не все данные корректны для продолжения парсинга');
            logError('Vers  === $vVers');
            logError('Wrap  === $vWrap');
            logError('Null  === $wNull');
            logError('NullN === $wNullN');
            logError('Strt  === $wStrt');
            logError('StrtN === $wStrtN');
            logError('Stop  === $wStop');
            logError('StopN === $wStopN');
            logError('Step  === $wStep');
            logError('StepN === $wStepN');
            logError('Well  === $wWell');
            break lineLoop;
          }
          methodsStrt = List(methods.length);
          methodsStrtN = List(methods.length);
          methodsStop = List(methods.length);
          methodsStopN = List(methods.length);
          continue lineLoop;
        case 'C': // ~Curve information
        case 'O': // ~Other information
        case 'P': // ~Parameter information
        case 'V': // ~Version information
        case 'W': // ~Well information
          continue lineLoop;
        default:
          logError(r'Неизвестная секция');
          break lineLoop;
      }
      continue lineLoop;
    } else {
      if (section.isEmpty) {
        logError(r'Отсутсвует секция');
        break lineLoop;
      }
      final i0 = line.indexOf('.');
      if (i0 == -1) {
        logError(r'Отсутсвует точка');
        continue lineLoop;
      }
      // if (line.contains('.', i0 + 1)) {
      //   logError(r'Две точки на линии');
      //   continue lineLoop;
      // }
      final i1 = line.lastIndexOf(':');
      if (i1 == -1) {
        logError(r'Отсутсвует двоеточие');
        continue lineLoop;
      }
      // if (line.contains(':', i1 + 1)) {
      //   logError(r'Два двоеточия на линии');
      //   continue lineLoop;
      // }
      final i2 = line.indexOf(' ', i0);
      final mnem = line.substring(0, i0).trim();
      final unit = line.substring(i0 + 1, i2).trim();
      final data = line.substring(i2 + 1, i1).trim();
      final desc = line.substring(i1 + 1).trim();
      switch (section) {
        case 'V':
          switch (mnem) {
            case 'VERS':
              vVers = data;
              if (unit.isNotEmpty) {
                logError(r'После точки должен быть пробел');
              }
              if (vVers != '1.20' && vVers != '2.0') {
                logError(r'Ошибка в версии файла');
                vVers = null;
              }
              continue lineLoop;
            case 'WRAP':
              vWrap = data;
              if (unit.isNotEmpty) {
                logError(r'После точки должен быть пробел');
              }
              if (vWrap != 'YES' && vWrap != 'NO') {
                logError(r'Ошибка в значении многострочности');
                vWrap = null;
              }
              continue lineLoop;
            default:
              logError(r'Неизвестная мнемоника в секции ~V');
              continue lineLoop;
          }
          break;
        case 'W':
          switch (mnem) {
            case 'NULL':
              wNull = data;
              wNullN = double.tryParse(wNull);
              if (wNullN == null) {
                logError(r'Некорректное число');
              }
              continue lineLoop;
            case 'STEP':
              wStep = data;
              wStepN = double.tryParse(wStep);
              if (wStepN == null) {
                logError(r'Некорректное число');
              }
              continue lineLoop;
            case 'STRT':
              wStrt = data;
              wStrtN = double.tryParse(wStrt);
              if (wStrtN == null) {
                logError(r'Некорректное число');
              }
              continue lineLoop;
            case 'STOP':
              wStop = data;
              wStopN = double.tryParse(wStop);
              if (wStopN == null) {
                logError(r'Некорректное число');
              }
              continue lineLoop;
            case 'WELL':
              wWell = data;
              if (wWell.isEmpty || wWell == 'WELL') {
                wWell = desc;
              }
              if (wWell.isEmpty ||
                  [
                    'WELL',
                    'WELL NAME',
                    'WELL NUMBER',
                    'Well',
                    'Well name',
                    'Наименование скважины',
                    'Нет поля СКВАЖИН',
                    'Номер скважины',
                    'СКВ№',
                    'Скважина',
                    'скважина'
                  ].contains(wWell)) {
                logError(r'Невозможно получить номер скважины по полю WELL');
                wWell = null;
              }
              continue lineLoop;
            default:
              continue lineLoop;
          }
          break;
        case 'C':
          methods.add(mnem);
          break;
      }
    }
  }
}
