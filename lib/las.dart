import 'dart:convert';
import 'dart:typed_data';

import 'errors.dart';
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
  final listOfErrors = <ErrorOnLine>[];
  Map<String, int> encodesRaiting;
  String encode;
  bool zWrap;
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

  LasData(final UnmodifiableUint8ListView bytes,
      final Map<String, List<String>> charMaps) {
    // Подбираем кодировку
    encodesRaiting = getMappingRaitings(charMaps, bytes);
    encode = getMappingMax(encodesRaiting);
    // Преобразуем байты из кодировки в символы
    final buffer = String.fromCharCodes(bytes
        .map((i) => i >= 0x80 ? charMaps[encode][i - 0x80].codeUnitAt(0) : i));

    // Нарезаем на линии
    final lines = LineSplitter.split(buffer);
    var lineNum = 0;

    void logError(KncError err) => listOfErrors.add(ErrorOnLine(err, lineNum));

    var iA = 0;
    var section = '';

    bool startSection() {
      switch (section) {
        case 'A': // ASCII Log data
          if (listOfErrors.isNotEmpty) {
            logError(KncError.lasErrorsNotEmpty);
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
            logError(KncError.lasAllDataNotCorrect);
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
          logError(KncError.lasUnknownSection);
          return true;
      }
    }

    bool parseAsciiLine(final String line) {
      for (final e in line.split(' ')) {
        if (e.isNotEmpty) {
          var val = double.tryParse(e);
          if (val == null) {
            logError(KncError.lasNumberParseError);
            return true;
          }
          if (zWrap == false && iA >= curves.length) {
            logError(KncError.lasTooManyNumbers);
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
          if (zWrap == true && iA >= curves.length) {
            iA = 0;
          }
        }
      }

      if (zWrap == false) {
        if (iA == curves.length) {
          iA = 0;
        } else {
          logError(KncError.lasTooManyNumbers);
          return true;
        }
      }
      return false;
    }

    bool parseLine(final String line) {
      if (section.isEmpty) {
        logError(KncError.lasSectionIsNull);
        return true;
      }
      final i0 = line.indexOf('.');
      if (i0 == -1) {
        logError(KncError.lasHaventDot);
        return false;
      }
      final i1 = line.lastIndexOf(':');
      if (i1 == -1) {
        logError(KncError.lasHaventDoubleDot);
        return false;
      }
      final i2 = line.indexOf(' ', i0);
      final mnem = line.substring(0, i0).trim();
      final unit = line.substring(i0 + 1, i2).trim();
      final data = line.substring(i2 + 1, i1).trim();
      final desc = line.substring(i1 + 1).trim();
      if (section != 'C') {
        info[section][mnem] = LasDataInfoLine(mnem, unit, data, desc);
      }
      switch (section) {
        case 'V':
          switch (mnem) {
            case 'VERS':
              vVers = data;
              if (unit.isNotEmpty) {
                logError(KncError.lasHaventSpaceAfterDot);
              }
              if (vVers != '1.20' && vVers != '2.0') {
                logError(KncError.lasVersionError);
                vVers = null;
              }
              return false;
            case 'WRAP':
              vWrap = data;
              if (unit.isNotEmpty) {
                logError(KncError.lasHaventSpaceAfterDot);
              }
              if (vWrap != 'YES' && vWrap != 'NO') {
                logError(KncError.lasLineWarpError);
                vWrap = null;
              }
              zWrap = vWrap == 'YES';
              return false;
            default:
              logError(KncError.lasUncknownMnemInVSection);
              return false;
          }
          break;
        case 'W':
          switch (mnem) {
            case 'NULL':
              wNull = data;
              wNullN = double.tryParse(wNull);
              if (wNullN == null) {
                logError(KncError.lasUncorrectNumber);
              }
              return false;
            case 'STEP':
              wStep = data;
              wStepN = double.tryParse(wStep);
              if (wStepN == null) {
                logError(KncError.lasUncorrectNumber);
              }
              return false;
            case 'STRT':
              wStrt = data;
              wStrtN = double.tryParse(wStrt);
              if (wStrtN == null) {
                logError(KncError.lasUncorrectNumber);
              }
              return false;
            case 'STOP':
              wStop = data;
              wStopN = double.tryParse(wStop);
              if (wStopN == null) {
                logError(KncError.lasUncorrectNumber);
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
                logError(KncError.lasCantGetWell);
                wWell = null;
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
