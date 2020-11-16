import '../../dbf/index.dart';

import '../../mymath.dart';
import '../structs.dart';

/// Данные инклинометрии каждой скважины
class InkWellData<T extends InkRowData> {
  /// Номер скважины
  final String well;

  /// Интервал печати начало (м)
  final double strt;

  /// Интервал печати конец (м)
  final double stop;

  /// Данные инклинометрии
  final List<T> data;

  InkWellData(this.well, this.strt, this.stop, this.data);

  /// Пытаемся разобрать базу днных DBF, в случае неудачи возвращаем исключение
  static List<InkWellData> createByDbf(Dbf dbf) {
    final _iNSKV = dbf.fields
        .firstWhere((e) => e.name.toUpperCase() == 'NSKV', orElse: () => null);
    final _iGLUB = dbf.fields
        .firstWhere((e) => e.name.toUpperCase() == 'GLUB', orElse: () => null);
    final _iUGOL = dbf.fields
        .firstWhere((e) => e.name.toUpperCase() == 'UGOL', orElse: () => null);
    final _iUGOL1 = dbf.fields
        .firstWhere((e) => e.name.toUpperCase() == 'UGOL1', orElse: () => null);
    final _iAZIMUT = dbf.fields.firstWhere(
        (e) => e.name.toUpperCase() == 'AZIMUT',
        orElse: () => null);

    if (!(_iNSKV != null &&
        _iGLUB != null &&
        (_iUGOL != null || _iUGOL1 != null) &&
        _iAZIMUT != null)) {
      final str = <String>[];
      if (_iNSKV != null) {
        str.add('NSKV');
      }
      if (_iGLUB != null) {
        str.add('GLUB');
      }
      if (_iUGOL != null) {
        str.add('UGOL');
      }
      if (_iUGOL1 != null) {
        str.add('UGOL1');
      }
      if (_iAZIMUT != null) {
        str.add('AZIMUT');
      }
      throw Exception('!W:Были обнаруженны следующие поля: ${str.join(', ')}');
    }

    final wells = <InkWellData>[];
    final _lRows = dbf.records.length;
    for (var i = 0; i < _lRows; i++) {
      final _row = dbf.records[i];

      /// Если это обычная запись
      if (!_row.deleted) {
        final _well = _row.value(_iNSKV).toString();
        final _iWell = wells.indexWhere((e) => e.well == _well);

        final _parsedRow = InkRowData(
            double.tryParse(_row.value(_iGLUB) is double
                ? _row.value(_iGLUB)
                : (double.tryParse(_row.value(_iGLUB)) ?? double.nan)),
            _iUGOL1 != null
                ? (_row.value(_iUGOL1) is double
                    ? _row.value(_iUGOL1)
                    : double.tryParse(_row.value(_iUGOL1)) ?? double.nan)
                : convertAngleMinuts2Gradus(_row.value(_iUGOL) is double
                    ? _row.value(_iUGOL)
                    : double.tryParse(_row.value(_iUGOL)) ?? double.nan),
            (_row.value(_iAZIMUT) is double
                ? _row.value(_iAZIMUT)
                : double.tryParse(_row.value(_iAZIMUT)) ?? double.nan));
        if (_iWell == -1) {
          wells.add(InkWellData(_well, double.nan, double.nan, [_parsedRow]));
        } else {
          wells[_iWell].data.add(_parsedRow);
        }
      }
    }
    wells.sort((a, b) => a.well.compareTo(b.well));
    final _l = wells.length;
    for (var i = 0; i < _l; i++) {
      final well = wells[i];
      well.data.sort((a, b) => a.depth - b.depth < 0.0
          ? -1
          : a.depth == b.depth
              ? 0
              : 1);
      final strt = well.data.first.depth;
      final stop = well.data.last.depth;
      wells[i] = InkWellData(well.well, strt, stop, well.data);
    }
    return wells;
  }
}
