import 'dbf.g.dart';
import 'ink.g.dart';

extension IOneFileInkDataDbf on OneFileInkDataDbf {
  static OneFileInkDataDbf /*?*/ createByDbf(final OneFileDbf dbf) {
    final _iNSKV = dbf.fields.indexWhere((e) => e.name.toUpperCase() == 'NSKV');
    final _iGLUB = dbf.fields.indexWhere((e) => e.name.toUpperCase() == 'GLUB');
    final _iUGOL = dbf.fields.indexWhere((e) => e.name.toUpperCase() == 'UGOL');
    final _iUGOL1 =
        dbf.fields.indexWhere((e) => e.name.toUpperCase() == 'UGOL1');
    final _iAZIMUT =
        dbf.fields.indexWhere((e) => e.name.toUpperCase() == 'AZIMUT');
    if (_iNSKV != -1 &&
        _iGLUB != -1 &&
        (_iUGOL != -1 || _iUGOL1 != -1) &&
        _iAZIMUT != -1) {
      final _lFields = dbf.fields.length;
      final extInfo = <String>[];
      final fieldsMapping = List<int>.filled(_lFields, -1);
      for (var i = 0; i < _lFields; i++) {
        if (_iNSKV == i ||
            _iGLUB == i ||
            _iUGOL == i ||
            _iUGOL1 == i ||
            _iAZIMUT == i) {
          continue;
        }
        final _field = dbf.fields[i];
        if (_field.type == 'C' || _field.type == 'N') {
          fieldsMapping[i] = extInfo.length;
          extInfo.add(_field.type + _field.name);
        }
      }

      final wells = <OneFileInkDataDbfWell>[];
      final _lRows = dbf.records.length;
      for (var i = 0; i < _lRows; i++) {
        final _row = dbf.records[i];

        /// Если это обычная запись
        if (_row.headByte == 0x20) {
          final _well = _row.values[_iNSKV] as String;
          final _iWell = wells.indexWhere((e) => e.well == _well);
          final _extInfo = List<String>.filled(extInfo.length, '');
          for (var j = 0; j < _lFields; j++) {
            final _j = fieldsMapping[j];
            if (_j != -1) {
              _extInfo[_j] = _row.values[j];
            }
          }
          final _parsedRow = OneFileInkDataRowDbf(
              depth: double.tryParse(_row.values[_iGLUB]),
              angle1:
                  _iUGOL != -1 ? double.tryParse(_row.values[_iUGOL]) : null,
              angle:
                  _iUGOL1 != -1 ? double.tryParse(_row.values[_iUGOL1]) : null,
              azimuth: double.tryParse(_row.values[_iAZIMUT]),
              extInfo: _extInfo);
          if (_iWell == -1) {
            wells.add(OneFileInkDataDbfWell(well: _well, data: [_parsedRow]));
          } else {
            wells[_iWell].data.add(_parsedRow);
          }
        }
      }
      wells.sort((a, b) => a.well.compareTo(b.well));
      for (var well in wells) {
        well.data.sort((a, b) => a.depth - b.depth < 0.0
            ? -1
            : a.depth == b.depth
                ? 0
                : 1);
        well.strt = well.data.first.depth;
        well.stop = well.data.last.depth;
      }
      return OneFileInkDataDbf(wells: wells, extInfo: extInfo);
    } else {
      return null;
    }
  }

  String getDebugString() {
    final str = StringBuffer();
    str.writeln('Данные ИНКЛИНОМЕТРИИ выгруженные из Базы данных');
    str.writeln('СПИСОК СКВАЖИН:');
    for (var well in wells) {
      str.writeln('\t' + well.well);
      str.writeln('\t\t' + well.strt.toString());
      str.writeln('\t\t' + well.stop.toString());
    }
    str.writeln('ДАННЫЕ КАЖДОЙ СКВАЖИНЫ:');
    str.write('СКВАЖИНА'.padRight(16));
    str.write('|' + 'ГЛУБИНА'.padRight(16));
    str.write('|' + 'УГОЛ'.padLeft(16));
    str.write('|' + 'УГОЛ1'.padLeft(16));
    str.write('|' + 'АЗИМУТ'.padLeft(16));
    final _lExt = extInfo.length;
    for (var i = 0; i < _lExt; i++) {
      final _ext = extInfo[i];
      if (_ext.startsWith('N')) {
        str.write('|' + _ext.padLeft(16));
      } else {
        str.write('|' + _ext.padRight(16));
      }
    }
    str.writeln();
    for (var well in wells) {
      for (var row in well.data) {
        str.write(well.well.padRight(16));
        str.write('|' + row.depth.toStringAsFixed(6).padLeft(16));
        str.write('|' + row.angle.toStringAsFixed(2).padLeft(16));
        str.write('|' + row.angle1.toStringAsFixed(2).padLeft(16));
        str.write('|' + row.azimuth.toStringAsFixed(6).padLeft(16));
        for (var i = 0; i < _lExt; i++) {
          final _ext = extInfo[i];
          final _extD = row.extInfo[i];
          if (_ext.startsWith('N')) {
            str.write('|' + _extD.toString().padLeft(16));
          } else {
            str.write('|' + _extD.toString().padRight(16));
          }
        }
      }
    }

    return str.toString();
  }
}
