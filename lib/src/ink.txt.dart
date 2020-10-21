import 'dart:convert';
import 'dart:math';

import 'ink.dart';

import 'ink.g.dart';

final _reDigit = RegExp(r'[\+-]?\d+(?:\.\d+)?');

final reInkTxtDataDepth = RegExp(r'^Гл', caseSensitive: false);
final reInkTxtDataAngle = RegExp(r'^Уг', caseSensitive: false);
final reInkTxtDataAzimuth = RegExp(r'^Аз', caseSensitive: false);
final reInkTxtDataAddLenght = RegExp(r'^Уд', caseSensitive: false);
final reInkTxtDataAbsPoint = RegExp(r'^Аб', caseSensitive: false);
final reInkTxtDataVertDepth = RegExp(r'^Ве', caseSensitive: false);
final reInkTxtDataOffset = RegExp(r'^См', caseSensitive: false);
final reInkTxtDataOffsetAngle = RegExp(r'уго?л\s+см', caseSensitive: false);
final reInkTxtDataNorth =
    RegExp(r'[+-]?(?<![а-яА-Я])[сю]', caseSensitive: false);
final reInkTxtDataWest = RegExp(r'[+-]?[вз]', caseSensitive: false);
final reInkTxtDataIntensity = RegExp(r'^Ин', caseSensitive: false);

/// - 1 - Интервал начало
/// - 2 - Интервал конец
/// - 3 - Количество точек
/// - 4 - ДД
/// - 5 - ММ
/// - 6 - ГГ
final reInkTxtExtPoints = RegExp(
    r'^([\+-]?\d+(?:\.\d+)?)-([\+-]?\d+(?:\.\d+)?)\s+(\d+)[\D]+(\d+)[\D]+(\d+)[\D]+(\d+)$',
    caseSensitive: false);

/// - 1 - Тип прибора
/// - 2 - Номер прибора
/// - 3 - Дата проверки
final reInkTxtExtDev =
    RegExp(r'^(.*?)\s*?N\s*?(\d+)(.+)$', caseSensitive: false);

// ignore: slash_for_doc_comments
/**
```regexp
^\s*Утверждаю\s+([А-Яа-яA-Za-z].+)$\s+_*(.+)
```
- 1 - Звание
- 2 - ФИО
*/
final reInkTxtApprover = RegExp(r'^\s*Утверждаю\s+([А-Яа-яA-Za-z].+)$\s+_*(.+)',
    multiLine: true, unicode: true, caseSensitive: false);

final reInkTxtTitle = RegExp(r'^\s*Замер\s+кривизны\s*$',
    multiLine: true, unicode: true, caseSensitive: false);

/// - 1 - Заказчик
final reInkTxtClient = RegExp(r'^\s*Заказчик.?(.*)$',
    multiLine: true, unicode: true, caseSensitive: false);

// ignore: slash_for_doc_comments
/**
```regexp
^Скважина(?:\s*N)?(.*?)
?(?:\s*Площадь(?:\s*:)?(.*?))?
?(?:\s*Куст(?:\s*:)?(.*?))?$
```
- 1 - Скважина
- 2? - Площадь
- 3? - Куст
*/
final reInkTxtWell = RegExp(
    r'^Скважина(?:\s*N)?(.*?)'
    r'(?:\s*Площадь(?:\s*:)?(.*?))?'
    r'(?:\s*Куст(?:\s*:)?(.*?))?$',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

// ignore: slash_for_doc_comments
/**
```regexp
^Диаметр(?:\s*скважины:)?(?:\s*:)?(.*?)
?(?:\s*Глубина(?:\s*башмака)?(?:\s*:)?(.*?))?$
```
- 1 - Диаметр скважины
- 2? - Глубина башмака
*/
final reInkTxtDiametr = RegExp(
    r'^Диаметр(?:\s*скважины:)?(?:\s*:)?(.*?)'
    r'(?:\s*Глубина(?:\s*башмака)?(?:\s*:)?(.*?))?$',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

// ignore: slash_for_doc_comments
/**
```regexp
^Угол(?:\s*склонения:)?(?:\s*:)?(.*?)
?(?:\s*Альтитуда(?:\s*:)?(.*?))?
?(?:\s*Забой(?:\s*:)?(.*?))?$
```
- 1 - Угол склонения
- 2? - Альтитуда
- 3? - Забой
*/
final reInkTxtAngle = RegExp(
    r'^Угол(?:\s*склонения:)?(?:\s*:)?(.*?)'
    r'(?:\s*Альтитуда(?:\s*:)?(.*?))?'
    r'(?:\s*Забой(?:\s*:)?(.*?))?$',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

/// - 1 - Интервал печати
final reInkTxtPrint = RegExp(r'^В\s+интервале\s+печати\s*:?(.+)$',
    multiLine: true, unicode: true, caseSensitive: false);

/// - 1 - Глубина максимального зенитного угла
/// - 2 - Максимальный зенитный угол
final reInkTxtMaxZenith = RegExp(
    r'^(?:На\s+глубине)?(?:\s*-)?\s*(.+)макс(?:имaльный)?\s+зенит(?:ный\s+угол)?(?:\s*-)?\s*(.+)$',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

/// - 1 - Глубина максимальной интенисивности кривизны
/// - 2 - Максимальная интенсивность кривизны
final reInkTxtMaxIntensity = RegExp(
    r'^(?:На\s+глубине)?(?:\s*-)?\s*(.+)макс(?:имaльная)?\s+инт(?:енсивность\s+кривизны)?(?:\s*-)?(.+)$',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

/// - 1 - Кто обработал
final reInkTxtProcessed = RegExp(r'^\s*Обработал\s*:?\s*(.+)$',
    multiLine: true, unicode: true, caseSensitive: false);

/// - 1 - разделительная строка таблицы
/// - 2 - Заголовок таблицы
/// - 3 - содержание таблицы
final reInkTxtTable =
    RegExp(r'^(-+\r?\n)(.+?)\1(.+?)\1', dotAll: true, multiLine: true);

extension IOneFileInkDataTxt on OneFileInkDataDoc {
  static OneFileInkDataDoc /*?*/ createByString(final String data) {
    if (!reInkTxtTitle.hasMatch(data)) {
      /// Отсутсвует заголовк `Замер кривизны`
      return null;
    }

    String /*?*/ _approver;
    final _matchApprover = reInkTxtApprover.firstMatch(data);
    if (_matchApprover != null) {
      _approver = _matchApprover.group(1).trim();
      if (_matchApprover.group(2) != null) {
        _approver += ' ' + _matchApprover.group(2).trim();
      }
    }

    String /*?*/ _client;
    final _matchClient = reInkTxtClient.firstMatch(data);
    if (_matchClient != null) {
      _client = _matchClient.group(1).trim();
    }

    String /*?*/ _well;
    String /*?*/ _square;
    String /*?*/ _cluster;
    final _matchWell = reInkTxtWell.firstMatch(data);
    if (_matchWell != null) {
      _well = _matchWell.group(1).trim();
      _square = _matchWell.group(2)?.trim();
      _cluster = _matchWell.group(3)?.trim();
    }

    double /*?*/ _diametr;
    double /*?*/ _depth;
    final _matchDiametr = reInkTxtDiametr.firstMatch(data);
    if (_matchWell != null) {
      final _diametr_s = _matchDiametr.group(1).trim();
      final _diametr_d = _reDigit.firstMatch(_diametr_s);
      if (_diametr_d != null) {
        _diametr = double.tryParse(_diametr_d.group(0));
      }
      final _depth_s = _matchDiametr.group(2)?.trim();
      if (_depth_s != null) {
        final _depth_d = _reDigit.firstMatch(_depth_s);
        if (_depth_d != null) {
          _depth = double.tryParse(_depth_d.group(0));
        }
      }
    }

    double /*?*/ _angle;
    var _angleM = false;
    double /*?*/ _altitude;
    double /*?*/ _zaboy;
    final _matchAngle = reInkTxtAngle.firstMatch(data);
    if (_matchWell != null) {
      final _angle_s = _matchAngle.group(1).trim();
      final _angle_d = _reDigit.firstMatch(_angle_s);
      _angleM = _angle_s.toLowerCase().contains('\'м');
      if (_angle_d != null) {
        _angle = double.tryParse(_angle_d.group(0));
      }
      final _altitude_s = _matchAngle.group(2)?.trim();
      if (_altitude_s != null) {
        final _altitude_d = _reDigit.firstMatch(_altitude_s);
        if (_altitude_d != null) {
          _altitude = double.tryParse(_altitude_d.group(0));
        }
      }
      final _zaboy_s = _matchAngle.group(3)?.trim();
      if (_zaboy_s != null) {
        final _zaboy_d = _reDigit.firstMatch(_zaboy_s);
        if (_zaboy_d != null) {
          _zaboy = double.tryParse(_zaboy_d.group(0));
        }
      }
    }

    double /*?*/ _printStrt;
    double /*?*/ _printStop;
    final _matchPrint = reInkTxtPrint.firstMatch(data);
    if (_matchPrint != null) {
      final _print = _matchPrint.group(1).trim();
      final _printStrt_d = _reDigit.firstMatch(_print);
      if (_printStrt_d != null) {
        final _printStop_d =
            _reDigit.firstMatch(_print.substring(_printStrt_d.end));
        if (_printStop_d != null) {
          _printStop = double.tryParse(_printStop_d.group(0));
        }
        _printStrt = double.tryParse(_printStrt_d.group(0));
      }
    }

    double /*?*/ _maxZenithAngleDepth;
    double /*?*/ _maxZenithAngle;
    bool _maxZenithAngleM;
    final _matchMaxZenith = reInkTxtMaxZenith.firstMatch(data);
    if (_matchMaxZenith != null) {
      final _maxZenithAngleDepth_s = _matchMaxZenith.group(1).trim();
      final _maxZenithAngleDepth_d =
          _reDigit.firstMatch(_maxZenithAngleDepth_s);
      if (_maxZenithAngleDepth_d != null) {
        _maxZenithAngleDepth = double.tryParse(_maxZenithAngleDepth_d.group(0));
      }
      final _maxZenithAngle_s = _matchMaxZenith.group(2).trim();
      final _maxZenithAngle_d = _reDigit.firstMatch(_maxZenithAngle_s);
      if (_maxZenithAngle_s.toLowerCase().contains('\'м')) {
        _maxZenithAngleM = true;
      } else if (_maxZenithAngle_s.toLowerCase().contains('\'г')) {
        _maxZenithAngleM = false;
      }
      if (_maxZenithAngle_d != null) {
        _maxZenithAngle = double.tryParse(_maxZenithAngle_d.group(0));
        if (_maxZenithAngle != null &&
            _maxZenithAngleM == null &&
            !maybeAngleInMinuts(_maxZenithAngle)) {
          _maxZenithAngleM = false;
        }
      }
    }

    double /*?*/ _maxIntensityDepth;
    double /*?*/ _maxIntensity;
    bool _maxIntensityM;
    final _matchMaxIntensity = reInkTxtMaxIntensity.firstMatch(data);
    if (_matchMaxIntensity != null) {
      final _maxIntensityDepth_s = _matchMaxIntensity.group(1).trim();
      final _maxIntensityDepth_d = _reDigit.firstMatch(_maxIntensityDepth_s);
      if (_maxIntensityDepth_d != null) {
        _maxIntensityDepth = double.tryParse(_maxIntensityDepth_d.group(0));
      }
      final _maxIntensity_s = _matchMaxIntensity.group(2).trim();
      final _maxIntensity_d = _reDigit.firstMatch(_maxIntensity_s);

      if (_maxIntensity_s.toLowerCase().contains('\'м')) {
        _maxIntensityM = true;
      } else if (_maxIntensity_s.toLowerCase().contains('\'г')) {
        _maxIntensityM = false;
      }
      if (_maxIntensity_d != null) {
        _maxIntensity = double.tryParse(_maxIntensity_d.group(0));
        if (_maxIntensity != null &&
            _maxIntensityM == null &&
            !maybeAngleInMinuts(_maxIntensity)) {
          _maxIntensityM = false;
        }
      }
    }

    String /*?*/ _processed;
    final _matchProcessed = reInkTxtProcessed.firstMatch(data);
    if (_matchProcessed != null) {
      _processed = _matchProcessed.group(1).trim();
    }

    final /*?*/ _extInfo = <OneFileInkDataDocExtInfo>[];
    final /*?*/ _data = <OneFileInkDataRowDoc>[];
    final _matchTbl1 = reInkTxtTable.firstMatch(data);
    if (_matchTbl1 != null) {
      final _tbl1_head = _matchTbl1.group(2);
      final _tbl1_head_lines =
          LineSplitter.split(_tbl1_head).toList(growable: false);
      final _lTbl1_headColumns = _tbl1_head_lines.last.split('|').length;
      final _tbl1_headColumns_t = List<int>.filled(_lTbl1_headColumns - 1, -1);
      final _tbl1_headColumns = List<String>.filled(_lTbl1_headColumns, '');
      for (var i = 0; i < _lTbl1_headColumns - 1; i++) {
        _tbl1_headColumns_t[i] = _tbl1_head_lines.last
            .indexOf('|', i == 0 ? 0 : _tbl1_headColumns_t[i - 1] + 1);
      }
      for (var _line in _tbl1_head_lines) {
        final _cols = _line.split('|');
        if (_cols.length == _lTbl1_headColumns) {
          for (var i = 0; i < _lTbl1_headColumns; i++) {
            _tbl1_headColumns[i] += ' ' + _cols[i].trim();
          }
        } else {
          for (var i = 0; i < _cols.length - 2; i++) {
            _tbl1_headColumns[i] += ' ' + _cols[i].trim();
          }
          _tbl1_headColumns.last += _cols.last;
        }
      }
      for (var i = 0; i < _lTbl1_headColumns; i++) {
        _tbl1_headColumns[i] = _tbl1_headColumns[i].trim();
      }
      final _tbl1_body = _matchTbl1.group(3);
      final _tbl1_body_lines =
          LineSplitter.split(_tbl1_body).toList(growable: false);
      final _lTbl1_body_lines = _tbl1_body_lines.length ~/ 2;
      for (var j = 0; j < _lTbl1_body_lines; j++) {
        final _cols = List<String>.filled(_lTbl1_headColumns - 1, '');

        for (var i = 0; i < _lTbl1_headColumns - 1; i++) {
          final _l1 = _tbl1_body_lines[j * 2 + 0];
          final _l2 = _tbl1_body_lines[j * 2 + 1];
          final _len1 = _l1.length;
          final _len2 = _l2.length;
          final _i1 = i == 0 ? 0 : _tbl1_headColumns_t[i - 1] + 1;
          final _i2 = _tbl1_headColumns_t[i] + 1;
          _cols[i] += (_i1 < _len1 ? _l1.substring(_i1, min(_i2, _len1)) : '') +
              ' ' +
              (_i1 < _len2 ? _l2.substring(_i1, min(_i2, _len2)) : '');
        }
        final _n = int.tryParse(_cols[0]);

        double /*?*/ _strt;
        double /*?*/ _stop;
        int /*?*/ _count;
        int /*?*/ _dd;
        int /*?*/ _mm;
        int /*?*/ _yy;
        final _matchExtPoints = reInkTxtExtPoints.firstMatch(_cols[1].trim());
        if (_matchExtPoints != null) {
          _strt = double.tryParse(_matchExtPoints.group(1));
          _stop = double.tryParse(_matchExtPoints.group(2));
          _count = int.tryParse(_matchExtPoints.group(3));
          _dd = int.tryParse(_matchExtPoints.group(4));
          _mm = int.tryParse(_matchExtPoints.group(5));
          _yy = int.tryParse(_matchExtPoints.group(6));
        }

        String /*?*/ _devType;
        int /*?*/ _devNum;
        String /*?*/ _devDate;
        final _matchExtDev = reInkTxtExtDev.firstMatch(_cols[2].trim());
        if (_matchExtDev != null) {
          _devType = _matchExtDev.group(1);
          _devNum = int.tryParse(_matchExtPoints.group(2));
          _devDate = _matchExtDev.group(3);
        }

        final _shaft = _cols[3].trim();
        final _sLBT = _cols[4].trim();
        final _sTBPV = _cols[5].trim();
        final _sUBT = _cols[6].trim();

        final _supervisor =
            _tbl1_body_lines[j * 2 + 0].substring(_tbl1_headColumns_t.last);
        final _client =
            _tbl1_body_lines[j * 2 + 1].substring(_tbl1_headColumns_t.last);

        _extInfo.add(OneFileInkDataDocExtInfo(
          n: _n,
          strt: _strt,
          stop: _stop,
          count: _count,
          dd: _dd,
          mm: _mm,
          yy: _yy,
          devType: _devType,
          devNum: _devNum,
          devDate: _devDate,
          shaft: _shaft,
          sLBT: _sLBT,
          sTBPV: _sTBPV,
          sUBT: _sUBT,
          supervisor: _supervisor,
          client: _client,
        ));
      }
      final _matchTbl2 =
          reInkTxtTable.firstMatch(data.substring(_matchTbl1.end));
      if (_matchTbl2 != null) {
        final _tbl2_head = _matchTbl2.group(2);
        final _tbl2_head_lines =
            LineSplitter.split(_tbl2_head).toList(growable: false);
        var _lTbl2_headColumns = _tbl2_head_lines.first.split('|').length;
        final _tbl2_headColumns_t = List<int>.filled(_lTbl2_headColumns, -1);
        final _tbl2_headColumns = List<String>.filled(_lTbl2_headColumns, '');
        for (var i = 0; i < _lTbl2_headColumns; i++) {
          _tbl2_headColumns_t[i] = _tbl2_head_lines.last
              .indexOf('|', i == 0 ? 0 : _tbl2_headColumns_t[i - 1] + 1);
        }
        for (var _line in _tbl2_head_lines) {
          final _cols = _line.split('|');
          for (var i = 0; i < _lTbl2_headColumns; i++) {
            _tbl2_headColumns[i] += ' ' + _cols[i].trim();
          }
        }
        var _depth_i = -1;
        var _angle_i = -1;
        bool /*?*/ _angleM;
        var _azimuth_i = -1;
        bool /*?*/ _azimuthM;
        var _addLenght_i = -1;
        var _absPoint_i = -1;
        var _vertDepth_i = -1;
        var _offset_i = -1;
        var _offsetAngle_i = -1;
        bool /*?*/ _offsetAngleM;
        var _north_i = -1;
        bool _northM;
        var _west_i = -1;
        bool _westM;
        var _intensity_i = -1;
        bool /*?*/ _intensityM;

        for (var i = 0; i < _lTbl2_headColumns; i++) {
          final _input = _tbl2_headColumns[i] = _tbl2_headColumns[i].trim();
          if (reInkTxtDataDepth.hasMatch(_input)) {
            _depth_i = i;
          } else if (reInkTxtDataAngle.hasMatch(_input)) {
            _angle_i = i;
            if (_input.toLowerCase().contains('\'м')) {
              _angleM = true;
            } else if (_input.toLowerCase().contains('\'г')) {
              _angleM = false;
            }
          } else if (reInkTxtDataAzimuth.hasMatch(_input)) {
            _azimuth_i = i;
            if (_input.toLowerCase().contains('\'м')) {
              _azimuthM = true;
            } else if (_input.toLowerCase().contains('\'г')) {
              _azimuthM = false;
            }
          } else if (reInkTxtDataAddLenght.hasMatch(_input)) {
            _addLenght_i = i;
          } else if (reInkTxtDataAbsPoint.hasMatch(_input)) {
            _absPoint_i = i;
          } else if (reInkTxtDataVertDepth.hasMatch(_input)) {
            _vertDepth_i = i;
          } else if (reInkTxtDataOffset.hasMatch(_input)) {
            _offset_i = i;
          } else if (reInkTxtDataOffsetAngle.hasMatch(_input)) {
            _offsetAngle_i = i;
            if (_input.toLowerCase().contains('\'м')) {
              _offsetAngleM = true;
            } else if (_input.toLowerCase().contains('\'г')) {
              _offsetAngleM = false;
            }
          } else if (reInkTxtDataNorth.hasMatch(_input)) {
            _north_i = i;
            final _match = reInkTxtDataNorth.firstMatch(_input);
            final _match1 = _match.group(0).toLowerCase();
            if (_match1 == '+с' || _match1 == '-ю') {
              _northM = false;
            } else {
              final _match2 = reInkTxtDataNorth
                  .firstMatch(_input.substring(_match.end))
                  .group(0)
                  ?.toLowerCase();
              if (_match2 != null && (_match1 == '-с' || _match1 == '+ю')) {
                _northM = true;
              } else {
                _northM = false;
              }
            }
          } else if (reInkTxtDataWest.hasMatch(_input)) {
            _west_i = i;
            final _match = reInkTxtDataWest.firstMatch(_input);
            final _match1 = _match.group(0).toLowerCase();
            if (_match1 == '+в' || _match1 == '-з') {
              _westM = false;
            } else {
              final _match2 = reInkTxtDataWest
                  .firstMatch(_input.substring(_match.end))
                  ?.group(0)
                  ?.toLowerCase();
              if (_match2 != null && (_match1 == '-в' || _match1 == '+з')) {
                _westM = true;
              } else {
                _westM = false;
              }
            }
          } else if (reInkTxtDataIntensity.hasMatch(_input)) {
            _intensity_i = i;
            if (_input.toLowerCase().contains('\'м')) {
              _intensityM = true;
            } else if (_input.toLowerCase().contains('\'г')) {
              _intensityM = false;
            }
          }
        }

        /// Текст внтури второй строки второй таблицы
        final _tbl2_body = _matchTbl2.group(3);

        /// Нарезанный на линии текст второй строки второй таблицы
        final _tbl2_body_lines =
            LineSplitter.split(_tbl2_body).toList(growable: false);

        /// Количетво линий второй строки второй таблицы
        final _lLine = _tbl2_body_lines.length;

        /// Количество пробелов на каждой позиции
        final _spaces = <int>[];

        /// Предполагаемые позиции разделителей столбцов
        final _spacesCol = <int>[];

        /// Подсчёт пробелов в каждом столбце
        for (var i = 0; i < _lLine; i++) {
          final _line = _tbl2_body_lines[i].codeUnits;
          final _l = _line.length;
          while (_spaces.length < _l) {
            _spaces.add(i);
          }
          for (var j = 0; j < _l; j++) {
            if (_line[j] == 0x20) {
              _spaces[j]++;
            }
          }
        }
        final _l = _spaces.length;

        /// Подбор длины первого столбца
        var k = _tbl2_body_lines[0].length;
        for (var _line in _tbl2_body_lines) {
          final _match = _reDigit.firstMatch(_line)?.end ?? k;
          if (_match < k) {
            k = _match;
          }
        }

        /// Нарезание на возможные разделители
        var _k = _spaces.first;
        for (var i = 1; i < _l; i++) {
          final _kT = _spaces[i];
          if (_kT <= _k) {
            _k = _kT;
          } else {
            _k = _kT;
            _spacesCol.add(i);
          }
        }

        final _l_spacesCol = _spacesCol.length;
        final _grid = <List<String>>[];
        for (var _line in _tbl2_body_lines) {
          final _cols = List<String>.filled(_l_spacesCol + 1, '');
          final _lLine = _line.length;
          _cols[0] = _line.substring(0, min(_lLine, _spacesCol.first)).trim();
          for (var i = 1; i < _l_spacesCol; i++) {
            _cols[i] = _line
                .substring(
                    min(_lLine, _spacesCol[i - 1]), min(_lLine, _spacesCol[i]))
                .trim();
          }
          _cols.last = _line.substring(min(_lLine, _spacesCol.last)).trim();
          _grid.add(_cols);
        }
        final _l_grid = _grid.length;

        /// Пытаемся определить градусы / минуты по значениям в столбцах
        if (_angle_i != -1 && _angleM == null) {
          _angleM = true;
          for (var i = 0; i < _l_grid; i++) {
            if (!maybeAngleInMinuts(
                double.tryParse(_grid[i][_angle_i]) ?? 0.0)) {
              _angleM = false;
            }
          }
        }
        if (_azimuth_i != -1 && _azimuthM == null) {
          for (var i = 0; i < _l_grid; i++) {
            if (!maybeAngleInMinuts(double.tryParse(
                    _grid[i][_azimuth_i].startsWith('*')
                        ? _grid[i][_azimuth_i].substring(1)
                        : _grid[i][_azimuth_i]) ??
                0.0)) {
              _azimuthM = false;
            }
          }
        }
        if (_offsetAngle_i != -1 && _offsetAngleM == null) {
          for (var i = 0; i < _l_grid; i++) {
            if (!maybeAngleInMinuts(
                double.tryParse(_grid[i][_offsetAngle_i]) ?? 0.0)) {
              _offsetAngleM = false;
            }
          }
        }
        if (_intensity_i != -1 && _intensityM == null) {
          for (var i = 0; i < _l_grid; i++) {
            if (!maybeAngleInMinuts(
                double.tryParse(_grid[i][_intensity_i]) ?? 0.0)) {
              _intensityM = false;
            }
          }
        }

        var _m = 0;
        var _g = 0;
        if (_angleM == true) {
          _m++;
        } else if (_angleM == false) {
          _g++;
        }
        if (_azimuthM == true) {
          _m++;
        } else if (_azimuthM == false) {
          _g++;
        }
        if (_offsetAngleM == true) {
          _m++;
        } else if (_offsetAngleM == false) {
          _g++;
        }
        if (_intensityM == true) {
          _m++;
        } else if (_intensityM == false) {
          _g++;
        }
        if (_maxZenithAngleM == true) {
          _m++;
        } else if (_maxZenithAngleM == false) {
          _g++;
        }
        if (_maxIntensityM == true) {
          _m++;
        } else if (_maxIntensityM == false) {
          _g++;
        }

        /// Если количество точных значений в минутах меньше, то задаём
        /// по умолчанию градусы, иначе минуты
        if (_m < _g) {
          _angleM ??= false;
          _azimuthM ??= false;
          _offsetAngleM ??= false;
          _intensityM ??= false;
          _maxZenithAngleM ??= false;
          _maxIntensityM ??= false;
        } else {
          _angleM ??= true;
          _azimuthM ??= true;
          _offsetAngleM ??= true;
          _intensityM ??= true;
          _maxZenithAngleM ??= true;
          _maxIntensityM ??= true;
        }

        for (var i = 0; i < _l_grid; i++) {
          final _row = _grid[i];
          double /*?*/ _depth;
          if (_depth_i != -1) {
            _depth = double.tryParse(_row[_depth_i]);
          }
          double /*?*/ _angle;
          if (_angle_i != -1) {
            _angle = double.tryParse(_row[_angle_i]);
          }
          double /*?*/ _azimuth;
          var _azimuthStar = false;
          if (_azimuth_i != -1) {
            _azimuthStar = _row[_azimuth_i].startsWith('*');
            _azimuth = double.tryParse(_azimuthStar
                ? _row[_azimuth_i].substring(1)
                : _row[_azimuth_i]);
          }
          double /*?*/ _addLenght;
          if (_addLenght_i != -1) {
            _addLenght = double.tryParse(_row[_addLenght_i]);
          }
          double /*?*/ _absPoint;
          if (_absPoint_i != -1) {
            _absPoint = double.tryParse(_row[_absPoint_i]);
          }
          double /*?*/ _vertDepth;
          if (_vertDepth_i != -1) {
            _vertDepth = double.tryParse(_row[_vertDepth_i]);
          }
          double /*?*/ _offset;
          if (_offset_i != -1) {
            _offset = double.tryParse(_row[_offset_i]);
          }
          double /*?*/ _offsetAngle;
          if (_offsetAngle_i != -1) {
            _offsetAngle = double.tryParse(_row[_offsetAngle_i]);
          }
          double /*?*/ _north;
          if (_north_i != -1) {
            _north = double.tryParse(_row[_north_i]);
          }
          double /*?*/ _west;
          if (_west_i != -1) {
            _west = double.tryParse(_row[_west_i]);
          }
          double /*?*/ _intensity;
          if (_intensity_i != -1) {
            _intensity = double.tryParse(_row[_intensity_i]);
          }

          _data.add(OneFileInkDataRowDoc(
            depth: _depth,
            angle: _angleM ? convertAngleMinuts2Gradus(_angle) : _angle,
            azimuth: _azimuthM ? convertAngleMinuts2Gradus(_azimuth) : _azimuth,
            azimuthStar: _azimuthStar,
            addLenght: _addLenght,
            absPoint: _absPoint,
            vertDepth: _vertDepth,
            offset: _offset,
            offsetAngle: _offsetAngleM
                ? convertAngleMinuts2Gradus(_offsetAngle)
                : _offsetAngle,
            north: _north_i != -1 && _northM ? -_north : _north,
            west: _west_i != -1 && _westM ? -_west : _west,
            intensity: _intensityM
                ? convertAngleMinuts2Gradus(_intensity)
                : _intensity,
          ));
        }
      }
    }

    return OneFileInkDataDoc(
      approver: _approver,
      client: _client,
      well: _well,
      square: _square,
      cluster: _cluster,
      diametr: _diametr,
      depth: _depth,
      angle: _angleM == true ? convertAngleMinuts2Gradus(_angle) : _angle,
      altitude: _altitude,
      zaboy: _zaboy,
      strt: _printStrt ?? (_data.isNotEmpty ? _data.first.depth : 0.0),
      stop: _printStop ?? (_data.isNotEmpty ? _data.last.depth : 0.0),
      maxZenithAngleDepth: _maxZenithAngleDepth,
      maxZenithAngle: _maxZenithAngleM == true
          ? convertAngleMinuts2Gradus(_maxZenithAngle)
          : _maxZenithAngle,
      maxIntensityDepth: _maxIntensityDepth,
      maxIntensity: _maxIntensityM == true
          ? convertAngleMinuts2Gradus(_maxIntensity)
          : _maxIntensity,
      processed: _processed,
      extInfo: _extInfo,
      data: _data,
    );
  }

  String getDebugString() {
    final str = StringBuffer();
    str.writeln('Данные ИНКЛИНОМЕТРИИ разобранные из текстовой строки');
    str.writeln('Номер скважины:'.padRight(48) + (well?.toString() ?? 'null'));
    str.writeln('Угол склонения:'.padRight(48) + (angle?.toString() ?? 'null'));
    str.writeln('Альтитуда:'.padRight(48) + (altitude?.toString() ?? 'null'));
    str.writeln(''.padRight(48, '-'));
    str.writeln(
        'Интервал печати начало:'.padRight(48) + (strt?.toString() ?? 'null'));
    str.writeln(
        'Интервал печати конец:'.padRight(48) + (stop?.toString() ?? 'null'));
    str.writeln('Утвержедно:'.padRight(48) + (approver?.toString() ?? 'null'));
    str.writeln('Заказчик:'.padRight(48) + (client?.toString() ?? 'null'));
    str.writeln('Площадь:'.padRight(48) + (square?.toString() ?? 'null'));
    str.writeln('Куст:'.padRight(48) + (cluster?.toString() ?? 'null'));
    str.writeln(
        'Диаметр скважины:'.padRight(48) + (diametr?.toString() ?? 'null'));
    str.writeln(
        'Глубина башмака:'.padRight(48) + (depth?.toString() ?? 'null'));
    str.writeln('Забой:'.padRight(48) + (zaboy?.toString() ?? 'null'));
    str.writeln('Глубина максимального зенитного угла:'.padRight(48) +
        (maxZenithAngleDepth?.toString() ?? 'null'));
    str.writeln('Максимальный зенитный угол:'.padRight(48) +
        (maxZenithAngle?.toString() ?? 'null'));
    str.writeln('Глубина максимальной интенисивности кривизны:'.padRight(48) +
        (maxIntensityDepth?.toString() ?? 'null'));
    str.writeln('Максимальная интенсивность кривизны:'.padRight(48) +
        (maxIntensity?.toString() ?? 'null'));
    str.writeln(
        'Кто обработал:'.padRight(48) + (processed?.toString() ?? 'null'));

    str.writeln(''.padRight(48, '-'));
    str.writeln('ДОПОЛНИТЕЛЬНЫЕ ДАННЫЕ:'.padRight(48) +
        (extInfo?.length.toString() ?? 'null'));
    if (extInfo != null && extInfo.isNotEmpty) {
      str.writeln('N'.padLeft(4) +
          '|' +
          'Интервал, кол. точек и дата исследования'.padLeft(42) +
          '|' +
          'Тип и номер прибора, дата поверки'.padLeft(42) +
          '|' +
          'Ствол'.padRight(16) +
          '|' +
          'ЛБТ'.padLeft(16) +
          '|' +
          'ТБПВ'.padLeft(16) +
          '|' +
          'УБТ'.padLeft(16) +
          '|' +
          'Фамилия нач. партии'.padRight(32) +
          '|' +
          'Фамилия представителя заказчика');
      for (var ext in extInfo) {
        str.writeln((ext.n?.toString() ?? 'null').padLeft(4) +
            '|' +
            ('[${ext.strt?.toString() ?? 'null'}] -'
                    '[${ext.stop?.toString() ?? 'null'}] '
                    '(${ext.count?.toString() ?? 'null'}) '
                    '${ext.dd?.toString() ?? 'null'}.'
                    '${ext.mm?.toString() ?? 'null'}.'
                    '${ext.yy?.toString() ?? 'null'}')
                .padLeft(42) +
            '|' +
            ('[${ext.devType?.toString() ?? 'null'}] '
                    'N [${ext.devNum?.toString() ?? 'null'}] '
                    '(${ext.devDate?.toString() ?? 'null'})')
                .padLeft(42) +
            '|' +
            '${ext.shaft?.toString() ?? 'null'}'.padRight(16) +
            '|' +
            '${ext.sLBT?.toString() ?? 'null'}'.padLeft(16) +
            '|' +
            '${ext.sTBPV?.toString() ?? 'null'}'.padLeft(16) +
            '|' +
            '${ext.sUBT?.toString() ?? 'null'}'.padLeft(16) +
            '|' +
            '${ext.supervisor?.toString() ?? 'null'}'.padRight(32) +
            '|' +
            '${ext.client?.toString() ?? 'null'}');
      }
    }

    str.writeln(''.padRight(48, '-'));
    str.writeln('ДАННЫЕ ИНКЛИНОМЕТРИИ:'.padRight(48) +
        (data?.length.toString() ?? 'null'));

    if (data != null && data.isNotEmpty) {
      str.writeln('Глубина'.padLeft(16) +
          '|' +
          'Угол'.padLeft(16) +
          '|' +
          'Азимут'.padLeft(16) +
          '|' +
          'Удлинение'.padLeft(16) +
          '|' +
          'Абс. отметка'.padLeft(16) +
          '|' +
          'Верт. глубина'.padLeft(16) +
          '|' +
          'Смещение'.padLeft(16) +
          '|' +
          'Дир. угл смещ.'.padLeft(16) +
          '|' +
          '+север, -юг'.padLeft(16) +
          '|' +
          '+восток, -запад'.padLeft(16) +
          '|' +
          'Интенсивность'.padLeft(16));
      for (var d in data) {
        str.writeln('${d.depth?.toStringAsFixed(6) ?? 'null'}'.padLeft(16) +
            '|' +
            '${d.angle?.toStringAsFixed(6) ?? 'null'}'.padLeft(16) +
            '|' +
            '${d.azimuthStar == true ? '*' : d.azimuthStar == false ? ' ' : '?'}' +
            '${d.azimuth?.toStringAsFixed(6) ?? 'null'}'.padLeft(15) +
            '|' +
            '${d.addLenght?.toStringAsFixed(6) ?? 'null'}'.padLeft(16) +
            '|' +
            '${d.absPoint?.toStringAsFixed(6) ?? 'null'}'.padLeft(16) +
            '|' +
            '${d.vertDepth?.toStringAsFixed(6) ?? 'null'}'.padLeft(16) +
            '|' +
            '${d.offset?.toStringAsFixed(6) ?? 'null'}'.padLeft(16) +
            '|' +
            '${d.offsetAngle?.toStringAsFixed(6) ?? 'null'}'.padLeft(16) +
            '|' +
            '${d.north?.toStringAsFixed(6) ?? 'null'}'.padLeft(16) +
            '|' +
            '${d.west?.toStringAsFixed(6) ?? 'null'}'.padLeft(16) +
            '|' +
            '${d.intensity?.toStringAsFixed(6) ?? 'null'}'.padLeft(16));
      }
    }

    return str.toString();
  }
}
