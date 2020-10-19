import 'dart:convert';

import 'ink.dart';

import 'ink.g.dart';

final reDigit = RegExp(r'[\+-]?\d+(?:\.\d+)?');

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
^\s*утверждаю\s+
?(?:[\s\S]*?([\w :]+)[\s\S]*?
?(?:_+)([\w \.\s]+?$))?
```
- 1 - Звание
- 2 - ФИО
*/
final reInkTxtApprover = RegExp(
    r'^\s*Утверждаю\s+'
    r'(?:[\s\S]*?([\w :]+)[\s\S]*?'
    r'(?:_+)([\w \.\s]+?$))?',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

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
final reInkTxtTable = RegExp(r'^(-+)(.+?)\1(.+?)\1');

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
      _client = _matchApprover.group(1).trim();
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
      final _diametr_d = reDigit.firstMatch(_diametr_s);
      if (_diametr_d != null) {
        _diametr = double.tryParse(_diametr_d.group(0));
      }
      final _depth_s = _matchDiametr.group(2)?.trim();
      if (_depth_s != null) {
        final _depth_d = reDigit.firstMatch(_depth_s);
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
      final _angle_d = reDigit.firstMatch(_angle_s);
      _angleM = _angle_s.toLowerCase().contains('м');
      if (_angle_d != null) {
        _angle = double.tryParse(_angle_d.group(0));
      }
      final _altitude_s = _matchAngle.group(2)?.trim();
      if (_altitude_s != null) {
        final _altitude_d = reDigit.firstMatch(_altitude_s);
        if (_altitude_d != null) {
          _altitude = double.tryParse(_altitude_d.group(0));
        }
      }
      final _zaboy_s = _matchAngle.group(3)?.trim();
      if (_zaboy_s != null) {
        final _zaboy_d = reDigit.firstMatch(_zaboy_s);
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
      final _printStrt_d = reDigit.firstMatch(_print);
      if (_printStrt_d != null) {
        final _printStop_d = reDigit.matchAsPrefix(_print, _printStrt_d.end);
        if (_printStop_d != null) {
          _printStop = double.tryParse(_printStop_d.group(0));
        }
        _printStrt = double.tryParse(_printStrt_d.group(0));
      }
    }

    double /*?*/ _maxZenithAngleDepth;
    double /*?*/ _maxZenithAngle;
    var _maxZenithAngleM = false;
    final _matchMaxZenith = reInkTxtMaxZenith.firstMatch(data);
    if (_matchMaxZenith != null) {
      final _maxZenithAngleDepth_s = _matchMaxZenith.group(1).trim();
      final _maxZenithAngleDepth_d = reDigit.firstMatch(_maxZenithAngleDepth_s);
      if (_maxZenithAngleDepth_d != null) {
        _maxZenithAngleDepth = double.tryParse(_maxZenithAngleDepth_d.group(0));
      }
      final _maxZenithAngle_s = _matchMaxZenith.group(2).trim();
      final _maxZenithAngle_d = reDigit.firstMatch(_maxZenithAngle_s);
      _maxZenithAngleM = _maxZenithAngle_s.toLowerCase().contains('м');
      if (_maxZenithAngle_d != null) {
        _maxZenithAngle = double.tryParse(_maxZenithAngle_d.group(0));
      }
    }

    double /*?*/ _maxIntensityDepth;
    double /*?*/ _maxIntensity;
    var _maxIntensityM = false;
    final _matchMaxIntensity = reInkTxtMaxIntensity.firstMatch(data);
    if (_matchMaxIntensity != null) {
      final _maxIntensityDepth_s = _matchMaxIntensity.group(1).trim();
      final _maxIntensityDepth_d = reDigit.firstMatch(_maxIntensityDepth_s);
      if (_maxIntensityDepth_d != null) {
        _maxIntensityDepth = double.tryParse(_maxIntensityDepth_d.group(0));
      }
      final _maxIntensity_s = _matchMaxIntensity.group(2).trim();
      final _maxIntensity_d = reDigit.firstMatch(_maxIntensity_s);
      _maxIntensityM = _maxIntensity_s.toLowerCase().contains('м');
      if (_maxIntensity_d != null) {
        _maxIntensity = double.tryParse(_maxIntensity_d.group(0));
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
      final _tbl1_headColumns_t = List<int>.filled(_lTbl1_headColumns, -1);
      final _tbl1_headColumns = List<String>.filled(_lTbl1_headColumns, '');
      for (var i = 0; i < _lTbl1_headColumns; i++) {
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
          _cols[i] += _tbl1_body_lines[j * 2 + 0].substring(
                  i == 0 ? 0 : _tbl1_headColumns_t[i - 1] + 1,
                  _tbl1_headColumns_t[i] + 1) +
              ' ' +
              _tbl1_body_lines[j * 2 + 1].substring(
                  i == 0 ? 0 : _tbl1_headColumns_t[i - 1] + 1,
                  _tbl1_headColumns_t[i] + 1);
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
      final _matchTbl2 = reInkTxtTable.matchAsPrefix(data, _matchTbl1.end);
      if (_matchTbl2 != null) {}
    }

    return OneFileInkDataDoc(
      approver: _approver,
      client: _client,
      well: _well,
      square: _square,
      cluster: _cluster,
      diametr: _diametr,
      depth: _depth,
      angle: _angleM ? convertAngleMinuts2Gradus(_angle) : _angle,
      altitude: _altitude,
      zaboy: _zaboy,
      strt: _printStrt ?? _data.isNotEmpty ? _data.first.depth : 0.0,
      stop: _printStop ?? _data.isNotEmpty ? _data.last.depth : 0.0,
      maxZenithAngleDepth: _maxZenithAngleDepth,
      maxZenithAngle: _maxZenithAngleM
          ? convertAngleMinuts2Gradus(_maxZenithAngle)
          : _maxZenithAngle,
      maxIntensityDepth: _maxIntensityDepth,
      maxIntensity: _maxIntensityM
          ? convertAngleMinuts2Gradus(_maxIntensity)
          : _maxIntensity,
      processed: _processed,
      extInfo: _extInfo.isNotEmpty ? _extInfo : null,
      data: _data,
    );
  }
}
